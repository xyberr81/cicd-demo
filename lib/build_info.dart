// Set by CI with --dart-define. Local builds keep the defaults.
const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'local');
const commitSha = String.fromEnvironment('COMMIT_SHA');

/// What was built and from which commit, for example "production · 1a2b3c4".
String buildLabel({String env = appEnv, String sha = commitSha}) {
  if (sha.isEmpty) return env;
  return '$env · ${sha.length > 7 ? sha.substring(0, 7) : sha}';
}
