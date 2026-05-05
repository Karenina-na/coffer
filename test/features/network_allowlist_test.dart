import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'release-reachable settings dictionary page does not call Nominatim',
    () {
      final source = File(
        'lib/features/settings/presentation/dict_manage_page.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('nominatim.openstreetmap.org')));
      expect(source, isNot(contains('package:http/http.dart')));
    },
  );
}
