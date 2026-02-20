import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/subscriptions/data/subscription_model.dart';
import '../../features/settings/data/subscription_list_model.dart';
import '../../features/settings/data/category_model.dart';
import '../../features/settings/data/payment_method_model.dart';
import '../database/hive_service.dart';

/// The iCloud container registered in the Apple Developer Portal and Xcode.
const _containerId =
    'iCloud.com.mb.pm.subscriptiontracker';

/// The filename stored in the iCloud Documents container.
const _backupFileName = 'subscriptions_backup.json';

class ICloudBackupService {
  static final ICloudBackupService _instance = ICloudBackupService._internal();
  factory ICloudBackupService() => _instance;
  ICloudBackupService._internal();

  // ─── Backup ─────────────────────────────────────────────────────────────────

  /// Serialises all Hive data to JSON and uploads it to iCloud.
  /// Returns the [DateTime] of the backup on success.
  Future<DateTime> backup({
    void Function(double progress)? onProgress,
  }) async {
    final subs = HiveService.subscriptionBox.values.toList();
    final lists = HiveService.listsBox.values.toList();
    final categories = HiveService.categoriesBox.values.toList();
    final paymentMethods = HiveService.paymentMethodsBox.values.toList();

    final payload = jsonEncode({
      'version': 3,
      'backedUpAt': DateTime.now().toIso8601String(),
      'subscriptions': subs.map((s) => s.toJson()).toList(),
      'lists': lists.map((l) => l.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'paymentMethods': paymentMethods.map((p) => p.toJson()).toList(),
    });

    // Write to temp file
    final dir = await getTemporaryDirectory();
    final tmpFile = File('${dir.path}/$_backupFileName');
    await tmpFile.writeAsString(payload, flush: true);

    // Upload to iCloud
    await ICloudStorage.upload(
      containerId: _containerId,
      filePath: tmpFile.path,
      destinationRelativePath: _backupFileName,
      onProgress: onProgress != null
          ? (stream) => stream.listen((progress) => onProgress(progress))
          : null,
    );

    await tmpFile.delete();
    return DateTime.now();
  }

  // ─── Restore ────────────────────────────────────────────────────────────────

  /// Downloads the backup from iCloud and re-imports all data into Hive.
  Future<void> restore({
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final localPath = '${dir.path}/$_backupFileName';

    await ICloudStorage.download(
      containerId: _containerId,
      relativePath: _backupFileName,
      destinationFilePath: localPath,
      onProgress: onProgress != null
          ? (stream) => stream.listen((progress) => onProgress(progress))
          : null,
    );

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Restore failed: no backup found in iCloud.');
    }

    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    // Clear existing data
    await HiveService.subscriptionBox.clear();
    await HiveService.listsBox.clear();
    await HiveService.categoriesBox.clear();
    await HiveService.paymentMethodsBox.clear();

    // Re-import subscriptions
    final rawSubs = raw['subscriptions'] as List<dynamic>? ?? [];
    for (final s in rawSubs) {
      final sub = Subscription.fromJson(s as Map<String, dynamic>);
      await HiveService.subscriptionBox.put(sub.id, sub);
    }

    // Re-import lists
    final rawLists = raw['lists'] as List<dynamic>? ?? [];
    for (final l in rawLists) {
      final list = SubscriptionList.fromJson(l as Map<String, dynamic>);
      await HiveService.listsBox.put(list.id, list);
    }

    // Re-import categories
    final rawCats = raw['categories'] as List<dynamic>? ?? [];
    for (final c in rawCats) {
      final category = CategoryModel.fromJson(c as Map<String, dynamic>);
      await HiveService.categoriesBox.put(category.id, category);
    }

    // Re-import payment methods
    final rawPMs = raw['paymentMethods'] as List<dynamic>? ?? [];
    for (final p in rawPMs) {
      final pm = PaymentMethod.fromJson(p as Map<String, dynamic>);
      await HiveService.paymentMethodsBox.put(pm.id, pm);
    }

    await file.delete();
  }

  // ─── Metadata ───────────────────────────────────────────────────────────────

  /// Returns the date of the last backup, or null if none exists.
  Future<DateTime?> lastBackupDate() async {
    try {
      final files = await ICloudStorage.gather(
        containerId: _containerId,
        onUpdate: null,
      );
      final match = files.where((f) => f.relativePath == _backupFileName);
      if (match.isEmpty) return null;
      return match.first.contentChangeDate;
    } catch (_) {
      return null;
    }
  }

  /// Whether iCloud is available on this device (signed in, Drive enabled).
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    try {
      await ICloudStorage.gather(containerId: _containerId, onUpdate: null);
      return true;
    } catch (_) {
      return false;
    }
  }
}
