import 'dart:convert';

import 'package:http/http.dart' as http;

/// Set at build time by CI: `--dart-define=GITHUB_REPO=owner/name`.
/// Empty in local builds, which turns the update check off.
const githubRepo = String.fromEnvironment('GITHUB_REPO');

class Release {
  const Release({
    required this.version,
    required this.apkUrl,
    required this.notes,
  });

  final String version;
  final String apkUrl;
  final String notes;
}

/// Parses `v1.2.3` or `1.2.3` into `[1, 2, 3]`. Returns null for anything else.
List<int>? parseVersion(String raw) {
  final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(raw.trim());
  if (match == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
}

bool isNewer(String candidate, String current) {
  final a = parseVersion(candidate);
  final b = parseVersion(current);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// Reads the GitHub `releases/latest` response. Returns null when the
/// release has no APK attached.
Release? releaseFromJson(Map<String, dynamic> json) {
  final assets = (json['assets'] as List).cast<Map<String, dynamic>>();
  final apk = assets
      .where((a) => (a['name'] as String).endsWith('.apk'))
      .firstOrNull;
  if (apk == null) return null;
  return Release(
    version: json['tag_name'] as String,
    apkUrl: apk['browser_download_url'] as String,
    notes: (json['body'] as String?) ?? '',
  );
}

sealed class UpdateCheck {
  const UpdateCheck();
}

/// Local build without `GITHUB_REPO`: there is nothing to check against.
class UpdatesDisabled extends UpdateCheck {
  const UpdatesDisabled();
}

class UpToDate extends UpdateCheck {
  const UpToDate();
}

class UpdateAvailable extends UpdateCheck {
  const UpdateAvailable(this.release);
  final Release release;
}

class CheckFailed extends UpdateCheck {
  const CheckFailed(this.reason);
  final String reason;
}

/// Asks GitHub for the latest release and compares it with [currentVersion].
/// Never throws: every failure comes back as [CheckFailed] so the UI can show it.
Future<UpdateCheck> checkForUpdate(
  String currentVersion, {
  String repo = githubRepo,
  http.Client? client,
}) async {
  if (repo.isEmpty) return const UpdatesDisabled();
  try {
    final res = await (client ?? http.Client())
        .get(
          Uri.https('api.github.com', '/repos/$repo/releases/latest'),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 403 || res.statusCode == 429) {
      return const CheckFailed('GitHub rate limit hit. Try mobile data.');
    }
    if (res.statusCode != 200) {
      return CheckFailed('GitHub returned HTTP ${res.statusCode}.');
    }
    final release = releaseFromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
    if (release == null) {
      return const CheckFailed('Latest release has no APK attached.');
    }
    if (!isNewer(release.version, currentVersion)) return const UpToDate();
    return UpdateAvailable(release);
  } catch (e) {
    return CheckFailed('Could not reach GitHub: $e');
  }
}
