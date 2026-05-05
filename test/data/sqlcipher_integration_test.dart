@TestOn('mac-os || linux || windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/data/db/database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// 验证 SQLite3MultipleCiphers 构建钩子已生效，`PRAGMA key` 能真正加密
/// 落盘文件。用例为真实文件 I/O（非内存 DB），覆盖：
///
///  1. 写入带 key 的库 → 文件前 16 字节 **不等于** 明文 SQLite 头
///     （`SQLite format 3\x00`）。
///  2. 重新以相同 key 打开，能读出数据。
///  3. 以错误 key 打开会失败（sqlite3mc 返回错误）。
void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('gwp_cipher_test_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('明文 SQLite 文件头可被识别，即使文件大小 >= 4096', () async {
    final dbPath = p.join(tmpDir.path, 'plain.db');
    {
      final db = sqlite3.open(dbPath);
      db.execute('CREATE TABLE t (v TEXT NOT NULL)');
      db.execute("INSERT INTO t (v) VALUES ('plain')");
      db.close();
    }

    expect(await File(dbPath).length(), greaterThanOrEqualTo(4096));
    expect(await isPlaintextSqliteDatabase(File(dbPath)), isTrue);
  });

  test('加密 SQLite 文件不会被误判为明文库', () async {
    final dbPath = p.join(tmpDir.path, 'encrypted.db');
    const hexKey =
        '00112233445566778899aabbccddeeff'
        '00112233445566778899aabbccddeeff';
    {
      final db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = \"x'$hexKey'\";");
      db.execute('CREATE TABLE t (v TEXT NOT NULL)');
      db.close();
    }

    expect(await isPlaintextSqliteDatabase(File(dbPath)), isFalse);
  });

  test('PRAGMA key 生效：数据库落盘为密文（非 "SQLite format 3" 头）', () {
    final dbPath = p.join(tmpDir.path, 'cipher.db');
    const hexKey =
        '00112233445566778899aabbccddeeff'
        '00112233445566778899aabbccddeeff';

    // 写入阶段
    {
      final db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = \"x'$hexKey'\";");
      db.execute('CREATE TABLE t (v TEXT NOT NULL)');
      db.execute("INSERT INTO t (v) VALUES ('hello-encrypted')");
      db.close();
    }

    // 断言 1：落盘文件头不是明文 SQLite header
    final header = Uint8List.fromList(
      File(dbPath).readAsBytesSync().take(16).toList(),
    );
    final asText = String.fromCharCodes(header);
    expect(
      asText.startsWith('SQLite format 3'),
      isFalse,
      reason: '落盘文件前 16 字节仍为明文 SQLite header，加密未生效',
    );

    // 断言 2：相同 key 能读
    {
      final db = sqlite3.open(dbPath);
      db.execute("PRAGMA key = \"x'$hexKey'\";");
      final rows = db.select('SELECT v FROM t');
      expect(rows.length, 1);
      expect(rows.first['v'], 'hello-encrypted');
      db.close();
    }

    // 断言 3：错误 key 会失败
    {
      final db = sqlite3.open(dbPath);
      db.execute(
        'PRAGMA key = "x\'ffffffffffffffffffffffffffffffff'
        'ffffffffffffffffffffffffffffffff\'";',
      );
      expect(
        () => db.select('SELECT v FROM t'),
        throwsA(isA<SqliteException>()),
      );
      db.close();
    }
  });
}
