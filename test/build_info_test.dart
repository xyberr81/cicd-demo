import 'package:cicd_demo/build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows the environment and the short commit SHA', () {
    expect(
      buildLabel(env: 'production', sha: '1a2b3c4d5e6f7890'),
      'production · 1a2b3c4',
    );
  });

  test('a patched build shows the patch number', () {
    expect(
      buildLabel(env: 'production', sha: '1a2b3c4d5e', patch: 2),
      'production · 1a2b3c4 · patch 2',
    );
  });

  test('a build with no commit shows only the environment', () {
    expect(buildLabel(env: 'local', sha: ''), 'local');
  });
}
