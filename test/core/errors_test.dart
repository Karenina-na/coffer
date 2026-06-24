import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';

void main() {
  group('NetworkError.isTransient', () {
    test('timeout is transient', () {
      const e = NetworkError('timed out', kind: NetworkErrorKind.timeout);
      expect(e.isTransient, isTrue);
    });

    test('connectivity is transient', () {
      const e = NetworkError('no net', kind: NetworkErrorKind.connectivity);
      expect(e.isTransient, isTrue);
    });

    test('serverError is transient', () {
      const e = NetworkError('500', kind: NetworkErrorKind.serverError);
      expect(e.isTransient, isTrue);
    });

    test('rateLimited is transient', () {
      const e = NetworkError('429', kind: NetworkErrorKind.rateLimited);
      expect(e.isTransient, isTrue);
    });

    test('clientError is NOT transient', () {
      const e = NetworkError('400', kind: NetworkErrorKind.clientError);
      expect(e.isTransient, isFalse);
    });

    test('malformedResponse is NOT transient', () {
      const e = NetworkError(
        'bad json',
        kind: NetworkErrorKind.malformedResponse,
      );
      expect(e.isTransient, isFalse);
    });

    test('unknown is NOT transient', () {
      const e = NetworkError('oops', kind: NetworkErrorKind.unknown);
      expect(e.isTransient, isFalse);
    });
  });

  group('NetworkError.statusCode', () {
    test('statusCode is preserved', () {
      const e = NetworkError(
        'forbidden',
        kind: NetworkErrorKind.clientError,
        statusCode: 403,
      );
      expect(e.statusCode, 403);
    });

    test('statusCode defaults to null', () {
      const e = NetworkError('no code', kind: NetworkErrorKind.unknown);
      expect(e.statusCode, isNull);
    });
  });

  group('AppError.toString', () {
    test('NotFoundError toString', () {
      const e = NotFoundError('record 42');
      expect(e.toString(), 'NotFoundError(record 42)');
    });

    test('ValidationError toString', () {
      const e = ValidationError('bad input');
      expect(e.toString(), 'ValidationError(bad input)');
    });

    test('StorageError toString', () {
      const e = StorageError('db fail');
      expect(e.toString(), 'StorageError(db fail)');
    });

    test('CryptoError toString', () {
      const e = CryptoError('mac fail');
      expect(e.toString(), 'CryptoError(mac fail)');
    });

    test('UnknownError toString', () {
      const e = UnknownError('mystery');
      expect(e.toString(), 'UnknownError(mystery)');
    });
  });
}
