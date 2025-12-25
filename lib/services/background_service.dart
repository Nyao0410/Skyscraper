import 'package:workmanager/workmanager.dart';
import 'package:atproto_core/atproto_core.dart';
import 'package:flutter/foundation.dart';
import 'bluesky_service.dart';
import 'database_service.dart';
import 'dart:io';

const taskCheckScheduledPosts = "checkScheduledPosts";
const taskRetryPendingDMs = "retryPendingDMs";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Background task started: $task");
    switch (task) {
      case taskCheckScheduledPosts:
        try {
          final db = DatabaseService();
          final service = BlueskyService();
          
          final accounts = await service.getAccounts();
          final now = DateTime.now();
          debugPrint("Checking scheduled posts for ${accounts.length} accounts at $now");

          if (accounts.isEmpty) {
            debugPrint("No accounts found, attempting session restore");
            final success = await service.restoreSession();
            if (success) {
              await _processScheduledPosts(db, service, service.did!, service.handle ?? "unknown", now);
            }
          } else {
            for (final account in accounts) {
              try {
                debugPrint("Processing account: ${account['handle']}");
                final session = Session.fromJson(account['session']);
                await service.activateSession(session);
                await _processScheduledPosts(db, service, account['did'], account['handle'], now);
              } catch (e) {
                debugPrint("Error processing account ${account['handle']}: $e");
              }
            }
          }
          
          // For iOS, we need to schedule the next task manually
          if (Platform.isIOS) {
            await Workmanager().registerOneOffTask(
              "1",
              taskCheckScheduledPosts,
              initialDelay: const Duration(minutes: 15),
              constraints: Constraints(
                networkType: NetworkType.connected,
              ),
            );
          }
        } catch (e) {
          debugPrint("Background task critical error: $e");
          return false;
        }
        break;
      case taskRetryPendingDMs:
        try {
          final service = BlueskyService();
          final accounts = await service.getAccounts();

          if (accounts.isEmpty) {
            final success = await service.restoreSession();
            if (success) {
              await service.retryPendingDMs();
            }
          } else {
            for (final account in accounts) {
              try {
                final session = Session.fromJson(account['session']);
                await service.activateSession(session);
                await service.retryPendingDMs();
              } catch (e) {
                debugPrint('Error retrying DMs for ${account['handle']}: $e');
              }
            }
          }

          // For iOS re-register
          if (Platform.isIOS) {
            await Workmanager().registerOneOffTask(
              "2",
              taskRetryPendingDMs,
              initialDelay: const Duration(minutes: 15),
              constraints: Constraints(
                networkType: NetworkType.connected,
              ),
            );
          }
        } catch (e) {
          debugPrint('Background task retryPendingDMs error: $e');
          return false;
        }
        break;
    }
    return true;
  });
}

Future<void> _processScheduledPosts(DatabaseService db, BlueskyService service, String did, String handle, DateTime now) async {
  final scheduledPosts = await db.getScheduledPosts(did);
  debugPrint("Found ${scheduledPosts.length} scheduled posts for $handle");
  for (final post in scheduledPosts) {
    final scheduledAt = DateTime.parse(post['scheduled_at']).toUtc();
    if (scheduledAt.isBefore(now.toUtc())) {
      try {
        await service.post(post['text']);
        await db.markAsSent(post['id']);
        debugPrint("Successfully posted scheduled post ${post['id']} for $handle");
      } catch (e) {
        debugPrint("Failed to post for $handle, attempting refresh: $e");
        final refreshed = await service.refreshSession();
        if (refreshed) {
          try {
            await service.post(post['text']);
            await db.markAsSent(post['id']);
            debugPrint("Successfully posted for $handle after refresh");
          } catch (e2) {
            debugPrint("Failed to post for $handle even after refresh: $e2");
          }
        }
      }
    }
  }
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> init() async {
    // Do not initialize background work on web builds — Workmanager
    // and related platform APIs are not supported in browsers.
    if (kIsWeb) {
      debugPrint('BackgroundService: running on web, skipping background init');
      return;
    }

    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Register periodic task
    if (!kIsWeb && Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        "1",
        taskCheckScheduledPosts,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      // Register periodic DM retry task as well
      await Workmanager().registerPeriodicTask(
        "2",
        taskRetryPendingDMs,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } else if (Platform.isIOS) {
      // For iOS, we register a one-off task that we'll re-register
      await Workmanager().registerOneOffTask(
        "1",
        taskCheckScheduledPosts,
        initialDelay: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      // Also register DM retry one-off task
      await Workmanager().registerOneOffTask(
        "2",
        taskRetryPendingDMs,
        initialDelay: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }
  }
}
