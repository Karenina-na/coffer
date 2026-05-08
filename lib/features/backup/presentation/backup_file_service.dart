import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors.dart';
import '../../../core/result.dart';

class PickedBackupPackage {
  const PickedBackupPackage({
    required this.contents,
    required this.displayName,
    required this.sizeBytes,
  });

  final String contents;
  final String displayName;
  final int sizeBytes;
}

class BackupFileService {
  Future<Result<File, AppError>> createBackupFile(String package) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, _fileName(DateTime.now().toUtc())));
      await file.writeAsString(package, flush: true);
      return Ok(file);
    } catch (e) {
      return Err(StorageError('create backup file failed: $e'));
    }
  }

  Future<Result<void, AppError>> shareBackupFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Coffer 加密备份',
        text: '这是 Coffer 导出的加密备份文件，恢复时仍需输入备份口令。',
      );
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('share backup file failed: $e'));
    }
  }

  Future<Result<PickedBackupPackage?, AppError>> pickBackupPackage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (picked == null || picked.files.isEmpty) {
        return const Ok(null);
      }
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes != null) {
        return Ok(
          PickedBackupPackage(
            contents: utf8.decode(bytes),
            displayName: file.name,
            sizeBytes: bytes.length,
          ),
        );
      }
      final path = file.path;
      if (path == null) {
        return const Err(StorageError('picked backup file has no readable path'));
      }
      final contents = await File(path).readAsString();
      final stat = await File(path).stat();
      return Ok(
        PickedBackupPackage(
          contents: contents,
          displayName: p.basename(path),
          sizeBytes: stat.size,
        ),
      );
    } catch (e) {
      return Err(StorageError('pick backup file failed: $e'));
    }
  }

  String _fileName(DateTime nowUtc) {
    final y = nowUtc.year.toString().padLeft(4, '0');
    final m = nowUtc.month.toString().padLeft(2, '0');
    final d = nowUtc.day.toString().padLeft(2, '0');
    final hh = nowUtc.hour.toString().padLeft(2, '0');
    final mm = nowUtc.minute.toString().padLeft(2, '0');
    final ss = nowUtc.second.toString().padLeft(2, '0');
    return 'coffer-backup-$y$m$d-$hh$mm$ss.enc.json';
  }
}
