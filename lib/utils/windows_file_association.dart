import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class WindowsFileAssociation {
  static const _prefsKey = 'windows_file_association_registered_v1';

  static Future<void> registerIfNeeded() async {
    if (!Platform.isWindows) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) == true) return;

    try {
      final exePath = Platform.resolvedExecutable;
      final exeName = p.basename(exePath);
      final openCommand = '"$exePath" "%1"';

      await _runReg(['add', 'HKCU\\Software\\Classes\\Applications\\$exeName\\shell\\open\\command', '/ve', '/d', openCommand, '/f']);
      await _runReg(['add', 'HKCU\\Software\\Classes\\Applications\\$exeName\\SupportedTypes', '/v', '.json', '/d', '', '/f']);
      await _runReg(['add', 'HKCU\\Software\\Classes\\.json\\OpenWithList\\$exeName', '/ve', '/d', '', '/f']);

      await prefs.setBool(_prefsKey, true);
    } catch (_) {
      // Non-fatal; flag stays unset so it retries next launch.
    }
  }

  static Future<void> _runReg(List<String> args) async {
    final result = await Process.run('reg', args, runInShell: false);
    if (result.exitCode != 0) {
      throw ProcessException('reg', args, result.stderr.toString(), result.exitCode);
    }
  }
}
