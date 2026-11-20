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
  late final AppLifecycleListener _lifecycle;
  String _version = '';
  String _status = 'Checking for updates…';
  bool _busy = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    // Reopening the app from recents doesn't rerun initState, so check on resume too.
    _lifecycle = AppLifecycleListener(onResume: _checkForUpdate);
    _checkForUpdate();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Checking for updates…';
    });

    final info = await PackageInfo.fromPlatform();
    final result = await checkForUpdate(info.version);
    if (!mounted) return;

    setState(() {
      _busy = false;
      _version = '${info.version} (build ${info.buildNumber})';
      _status = switch (result) {
        UpdatesDisabled() => 'Update check off in local builds',
        UpToDate() => 'Up to date',
        UpdateAvailable(:final release) => '${release.version} available',
        CheckFailed(:final reason) => reason,
      };
    });

    if (result case UpdateAvailable(:final release)) {
      await _offerUpdate(release);
    }
  }

  Future<void> _offerUpdate(Release release) async {
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

    setState(() {
      _busy = true;
      _progress = 0;
    });
    try {
      await AppInstallerPlus().downloadAndInstallApk(
        downloadFileUrl: release.apkUrl,
        deleteOnError: true,
        onProgress: (p) => setState(() => _progress = p),
      );
    } catch (e) {
      if (mounted) setState(() => _status = 'Download failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
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
              const SizedBox(height: 32),
              Text(_status, textAlign: TextAlign.center),
              if (_progress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
                Text('Downloading ${(_progress! * 100).round()}%'),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _busy ? null : _checkForUpdate,
                child: const Text('Check for updates'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
