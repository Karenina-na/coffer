import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/core/result.dart';

void main() {
  group('Result', () {
    group('Ok', () {
      test('isOk is true', () {
        const r = Ok<int, AppError>(42);
        expect(r.isOk, isTrue);
      });

      test('isErr is false', () {
        const r = Ok<int, AppError>(42);
        expect(r.isErr, isFalse);
      });

      test('valueOrNull returns value', () {
        const r = Ok<int, AppError>(42);
        expect(r.valueOrNull, 42);
      });

      test('errorOrNull returns null', () {
        const r = Ok<int, AppError>(42);
        expect(r.errorOrNull, isNull);
      });

      test('when calls ok branch', () {
        const r = Ok<int, AppError>(42);
        final result = r.when(ok: (v) => 'ok:$v', err: (_) => 'err');
        expect(result, 'ok:42');
      });

      test('Ok<void> is valid', () {
        const r = Ok<void, AppError>(null);
        expect(r.isOk, isTrue);
        // valueOrNull for void is void (null), but we cannot call expect on void
        expect(r.isErr, isFalse);
      });
    });

    group('Err', () {
      test('isErr is true', () {
        const r = Err<int, AppError>(NotFoundError('missing'));
        expect(r.isErr, isTrue);
      });

      test('isOk is false', () {
        const r = Err<int, AppError>(NotFoundError('missing'));
        expect(r.isOk, isFalse);
      });

      test('errorOrNull returns error', () {
        const e = NotFoundError('missing');
        const r = Err<int, AppError>(e);
        expect(r.errorOrNull, e);
      });

      test('valueOrNull returns null', () {
        const r = Err<int, AppError>(StorageError('fail'));
        expect(r.valueOrNull, isNull);
      });

      test('when calls err branch', () {
        const r = Err<int, AppError>(ValidationError('bad'));
        final result = r.when(ok: (_) => 'ok', err: (e) => 'err:${e.message}');
        expect(result, 'err:bad');
      });
    });

    group('when return type', () {
      test('when can return different types', () {
        final Result<int, AppError> r = const Ok(10);
        final len = r.when(ok: (v) => v * 2, err: (_) => -1);
        expect(len, 20);
      });

      test('Err when can return different types', () {
        final Result<int, AppError> r = const Err(StorageError('db down'));
        final len = r.when(ok: (v) => v * 2, err: (_) => -1);
        expect(len, -1);
      });
    });
  });
}
