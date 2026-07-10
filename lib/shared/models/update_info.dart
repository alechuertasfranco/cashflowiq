// lib/shared/models/update_info.dart

class UpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String apkUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.apkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json, {required int currentBuildNumber}) {
    final minBuildNumber = json['min_build_number'] as int? ?? 0;
    return UpdateInfo(
      latestVersion: json['latest_version'] as String,
      latestBuildNumber: json['latest_build_number'] as int,
      apkUrl: json['apk_url'] as String,
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: (json['force_update'] as bool? ?? false) || currentBuildNumber < minBuildNumber,
    );
  }
}
