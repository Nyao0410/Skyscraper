import 'package:workmanager/workmanager.dart';
import 'package:atproto_core/atproto_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'bluesky_service.dart';
import 'database_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

const taskCheckScheduledPosts = "checkScheduledPosts";
const taskRetryPendingDMs = "retryPendingDMs";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Ensure Flutter is initialized for background tasks
    WidgetsFlutterBinding.ensureInitialized();

    Future<void> appendDebugLog(String msg) async {
      try {
        final now = DateTime.now().toIso8601String();
        final line = "$now - $task - $msg\n";
        // Try external storage first (adb friendly)
        try {
          final f = File('/sdcard/bsky_background.log');
          await f.writeAsString(line, mode: FileMode.append);
          return;
        } catch (_) {}
        // Fallback to app documents directory
        try {
          final dir = await getApplicationDocumentsDirectory();
          final f = File('${dir.path}/bsky_background.log');
          await f.writeAsString(line, mode: FileMode.append);
        } catch (_) {}
      } catch (_) {}
    }
    debugPrint("Background task started: $task");
    appendDebugLog('started');
    switch (task) {
      case taskCheckScheduledPosts:
        try {
          final db = DatabaseService();
          final service = BlueskyService();
          
          final accounts = await service.getAccounts();
          final now = DateTime.now();
          debugPrint("Checking scheduled posts for ${accounts.length} accounts at $now");
          appendDebugLog('accounts_count=${accounts.length}, now=$now');

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
                appendDebugLog('processed_account=${account['did']}');
              } catch (e) {
                debugPrint("Error processing account ${account['handle']}: $e");
                appendDebugLog('error_processing_account=${account['did']}, error=$e');
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
            appendDebugLog('re-registered_ios_task');
          }
          } catch (e) {
          debugPrint("Background task critical error: $e");
          appendDebugLog('critical_error=$e');
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
  final nowUtc = now.toUtc();
  const int maxAttempts = 3;
  for (final post in scheduledPosts) {
    final scheduledAtStr = post['scheduled_at'] as String;
    DateTime scheduledAt = DateTime.parse(scheduledAtStr);
    // Ensure we are comparing UTC times
    if (!scheduledAt.isUtc) {
      scheduledAt = scheduledAt.toUtc();
    }
    
    debugPrint("Checking post ${post['id']}: scheduledAt=$scheduledAt, nowUtc=$nowUtc");
    if (scheduledAt.isBefore(nowUtc)) {
      try {
        await service.post(post['text']);
        await db.markAsSent(post['id']);
        debugPrint("Successfully posted scheduled post ${post['id']} for $handle");
      } catch (e) {
        debugPrint("Failed to post for $handle, attempting refresh: $e");
        // Increase attempt count and decide whether to retry later
        final id = post['id'] as int;
        final attempts = await db.incrementDraftAttempts(id);
        // Try refreshing session once immediately if attempts == 1
        if (attempts == 1) {
          final refreshed = await service.refreshSession();
          if (refreshed) {
            try {
              await service.post(post['text']);
              await db.markAsSent(id);
              debugPrint("Successfully posted for $handle after refresh");
              continue;
            } catch (e2) {
              debugPrint("Failed to post for $handle even after refresh: $e2");
            }
          }
        }
        // If we've reached max attempts, mark as sent to stop further retries
        if (attempts >= maxAttempts) {
          debugPrint('Max attempts reached for post ${post['id']} (attempts=$attempts). Marking as sent.');
          await db.markAsSent(id);
        }
      }
    } else {
      debugPrint("Post ${post['id']} is scheduled for the future: $scheduledAt");
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
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      // Register periodic DM retry task as well
      await Workmanager().registerPeriodicTask(
        "2",
        taskRetryPendingDMs,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
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
