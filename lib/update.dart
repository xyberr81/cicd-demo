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

/// Returns the latest release if it is newer than [currentVersion].
Future<Release?> checkForUpdate(
  String currentVersion, {
  http.Client? client,
}) async {
  if (githubRepo.isEmpty) return null;
  final res = await (client ?? http.Client()).get(
    Uri.https('api.github.com', '/repos/$githubRepo/releases/latest'),
    headers: {'Accept': 'application/vnd.github+json'},
  );
  if (res.statusCode != 200) return null;
  final release = releaseFromJson(jsonDecode(res.body) as Map<String, dynamic>);
  if (release == null || !isNewer(release.version, currentVersion)) return null;
  return release;
}
