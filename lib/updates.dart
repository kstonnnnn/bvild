import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'settings.dart';

const String _releasesApi = 'https://api.github.com/repos/kstonnnnn/bvild/releases/latest';

class UpdateInfo {
  final int build;
  final String name;
  final String url;
  UpdateInfo(this.build, this.name, this.url);
  bool get isNewer => appBuild > 0 && build > appBuild;
}

/// Update checks only make sense for the sideloaded Android build.
bool get updatesSupported => !kIsWeb && appBuild > 0;

Future<UpdateInfo> fetchLatest() async {
  final r = await http
      .get(Uri.parse(_releasesApi), headers: {'Accept': 'application/vnd.github+json'})
      .timeout(const Duration(seconds: 10));
  if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  final j = jsonDecode(r.body) as Map<String, dynamic>;
  final tag = (j['tag_name'] ?? '').toString();
  final m = RegExp(r'(\d+)$').firstMatch(tag);
  final build = m == null ? 0 : int.parse(m.group(1)!);
  var url = (j['html_url'] ?? '').toString();
  final assets = (j['assets'] as List?) ?? const [];
  for (final a in assets) {
    if (a is Map && (a['name'] ?? '').toString().endsWith('.apk')) {
      url = (a['browser_download_url'] ?? url).toString();
    }
  }
  return UpdateInfo(build, (j['name'] ?? tag).toString(), url);
}

Future<void> openLink(String url) async {
  if (url.isEmpty) return;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Manual check with a result dialog.
Future<void> checkForUpdates(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Checking for updates…'), duration: Duration(seconds: 2)));
  try {
    final info = await fetchLatest();
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(info.isNewer ? 'Update available' : 'You are up to date'),
        content: Text(info.isNewer
            ? '${info.name} is out. You have version $appVersion (build $appBuild). '
                'Download the new APK and install it over the current one. Your progress stays.'
            : 'You have the latest version: $appVersion (build $appBuild).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (info.isNewer)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                openLink(info.url);
              },
              child: const Text('Download'),
            ),
        ],
      ),
    );
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Could not check for updates. Are you online?')));
  }
}

/// Quiet check at startup: shows a snackbar only if there is something new.
Future<void> silentUpdateCheck(BuildContext context) async {
  if (!updatesSupported) return;
  try {
    final info = await fetchLatest();
    if (!info.isNewer || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${info.name} is available'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(label: 'Download', onPressed: () => openLink(info.url)),
      ),
    );
  } catch (_) {}
}
