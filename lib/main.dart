import 'package:app_installer_plus/app_installer_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update.dart';

// Change this between releases to show the update arrived.
const headline = 'Hello, seminar!';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CI/CD Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _version = '';
  double? _progress;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = '${info.version} (build ${info.buildNumber})');

    final release = await checkForUpdate(info.version);
    if (release == null || !mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${release.version} available'),
        content: Text(
          release.notes.isEmpty ? 'A new version is ready.' : release.notes,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    setState(() => _progress = 0);
    try {
      await AppInstallerPlus().downloadAndInstallApk(
        downloadFileUrl: release.apkUrl,
        deleteOnError: true,
        onProgress: (p) => setState(() => _progress = p),
      );
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headline,
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('v$_version', style: theme.textTheme.titleMedium),
              if (_progress != null) ...[
                const SizedBox(height: 24),
                LinearProgressIndicator(value: _progress),
                Text('Downloading ${(_progress! * 100).round()}%'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
