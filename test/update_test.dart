import 'package:cicd_demo/update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewer', () {
    test('compares each part numerically', () {
      expect(isNewer('v1.10.0', '1.9.0'), isTrue);
      expect(isNewer('v2.0.0', '1.99.99'), isTrue);
      expect(isNewer('v1.0.1', '1.0.0'), isTrue);
    });

    test('same or older version is not an update', () {
      expect(isNewer('v1.0.0', '1.0.0'), isFalse);
      expect(isNewer('v0.9.0', '1.0.0'), isFalse);
    });

    test('ignores tags that are not plain versions', () {
      expect(isNewer('nightly', '1.0.0'), isFalse);
      expect(isNewer('v2.0.0-beta', '1.0.0'), isFalse);
    });
  });

  group('releaseFromJson', () {
    test('picks the APK asset', () {
      final release = releaseFromJson({
        'tag_name': 'v1.1.0',
        'body': 'Bug fixes',
        'assets': [
          {
            'name': 'checksums.txt',
            'browser_download_url': 'https://x/checksums.txt',
          },
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://x/app-release.apk',
          },
        ],
      });
      expect(release?.version, 'v1.1.0');
      expect(release?.apkUrl, 'https://x/app-release.apk');
      expect(release?.notes, 'Bug fixes');
    });

    test('returns null without an APK', () {
      expect(releaseFromJson({'tag_name': 'v1.1.0', 'assets': []}), isNull);
    });
  });
}
