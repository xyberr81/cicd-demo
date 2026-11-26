import 'package:cicd_demo/patch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class FakeUpdater implements ShorebirdUpdater {
  FakeUpdater({
    this.isAvailable = true,
    this.status = UpdateStatus.upToDate,
    this.current,
    this.server,
  });

  @override
  final bool isAvailable;
  final UpdateStatus status;
  int? current;
  int? next;
  final int? server;
  bool fail = false;

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async {
    if (fail) throw Exception('offline');
    return status;
  }

  @override
  Future<void> update({UpdateTrack? track}) async => next = server;

  @override
  Future<Patch?> readCurrentPatch() async =>
      current == null ? null : Patch(number: current!);

  @override
  Future<Patch?> readNextPatch() async {
    final n = next ?? current;
    return n == null ? null : Patch(number: n);
  }
}

void main() {
  test('a build without Shorebird has no patches', () async {
    expect(
      await checkForPatch(FakeUpdater(isAvailable: false)),
      isA<PatchesUnavailable>(),
    );
  });

  test('a new patch is downloaded and waits for a restart', () async {
    final result = await checkForPatch(
      FakeUpdater(status: UpdateStatus.outdated, server: 1),
    );
    expect(
      result,
      isA<PatchReady>()
          .having((r) => r.running, 'running', null)
          .having((r) => r.next, 'next', 1),
    );
  });

  test('after the restart the patch is current', () async {
    final result = await checkForPatch(FakeUpdater(current: 1));
    expect(result, isA<PatchCurrent>().having((r) => r.patch, 'patch', 1));
  });

  test('the release with no patch yet is current', () async {
    final result = await checkForPatch(FakeUpdater());
    expect(result, isA<PatchCurrent>().having((r) => r.patch, 'patch', null));
  });

  test('errors are reported, not thrown', () async {
    final result = await checkForPatch(FakeUpdater()..fail = true);
    expect(result, isA<PatchFailed>());
  });
}
