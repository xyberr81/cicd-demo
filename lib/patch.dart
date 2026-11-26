import 'package:shorebird_code_push/shorebird_code_push.dart';

sealed class PatchCheck {
  const PatchCheck();
}

/// Not built with `shorebird release` (local and main-branch builds).
class PatchesUnavailable extends PatchCheck {
  const PatchesUnavailable();
}

/// Running the newest patch, or the release itself when [patch] is null.
class PatchCurrent extends PatchCheck {
  const PatchCurrent(this.patch);
  final int? patch;
}

/// Patch [next] is downloaded and replaces [running] the next time the app starts.
class PatchReady extends PatchCheck {
  const PatchReady({required this.running, required this.next});
  final int? running;
  final int next;
}

class PatchFailed extends PatchCheck {
  const PatchFailed(this.reason);
  final String reason;
}

/// Downloads a new Shorebird patch if there is one. Never throws.
Future<PatchCheck> checkForPatch(ShorebirdUpdater updater) async {
  if (!updater.isAvailable) return const PatchesUnavailable();
  try {
    if (await updater.checkForUpdate() == UpdateStatus.outdated) {
      await updater.update();
    }
    final current = (await updater.readCurrentPatch())?.number;
    final next = (await updater.readNextPatch())?.number;
    if (next != null && next != current) {
      return PatchReady(running: current, next: next);
    }
    return PatchCurrent(current);
  } catch (e) {
    return PatchFailed('Patch check failed: $e');
  }
}
