import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/api.dart' as api;

void main() {
  test('Authentication', () async {
    await api.authenticate();
  });
}
