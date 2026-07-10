// lib/core/services/update_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cashflowiq/shared/models/update_info.dart';

/// Checks the self-hosted `/app/version` endpoint for a newer APK, downloads
/// it, and hands it to the Android package installer. No Firebase auth is
/// required for this endpoint, so it bypasses [ApiClient] and calls the API
/// directly.
class UpdateService {
  UpdateService._();

  static String get _baseUrl => dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8000";

  /// Returns null if the installed build is already current (or the check fails).
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/app/version"))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(json, currentBuildNumber: currentBuildNumber);

      if (info.latestBuildNumber <= currentBuildNumber) return null;
      return info;
    } catch (_) {
      // Update checks are best-effort - never block app startup on network errors.
      return null;
    }
  }

  /// Downloads the APK to a private app directory, reporting progress in [0, 1].
  static Future<String> downloadApk(String apkUrl, {void Function(double progress)? onProgress}) async {
    final request = http.Request('GET', Uri.parse(apkUrl));
    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw Exception("No se pudo descargar la actualización (HTTP ${response.statusCode})");
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cashflowiq_update.apk');
    final sink = file.openWrite();

    final total = response.contentLength ?? 0;
    var received = 0;

    await response.stream.forEach((chunk) {
      received += chunk.length;
      sink.add(chunk);
      if (total > 0) onProgress?.call(received / total);
    });

    await sink.close();
    return file.path;
  }

  static Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath);
  }
}
