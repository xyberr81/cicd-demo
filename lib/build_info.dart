// Set by CI with --dart-define. Local builds keep the defaults.
const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'local');
const commitSha = String.fromEnvironment('COMMIT_SHA');

/// What was built, from which commit, and which Shorebird patch is running,
/// for example "production · 1a2b3c4 · patch 1".
String buildLabel({String env = appEnv, String sha = commitSha, int? patch}) {
  return [
    env,
    if (sha.isNotEmpty) sha.length > 7 ? sha.substring(0, 7) : sha,
    if (patch != null) 'patch $patch',
  ].join(' · ');
}
