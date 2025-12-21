import 'package:workmanager/workmanager.dart';
import 'package:atproto_core/atproto_core.dart';
import 'bluesky_service.dart';
import 'database_service.dart';
import 'dart:io';

const taskCheckScheduledPosts = "checkScheduledPosts";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case taskCheckScheduledPosts:
        try {
          final db = DatabaseService();
          final service = BlueskyService();
          
          final accounts = await service.getAccounts();
          final now = DateTime.now();

          if (accounts.isEmpty) {
            // Fallback to single account restore if no accounts list
            final success = await service.restoreSession();
            if (!success) return true;
            
            final scheduledPosts = await db.getScheduledPosts(service.did!);
            for (final post in scheduledPosts) {
              final scheduledAt = DateTime.parse(post['scheduled_at']);
              if (scheduledAt.isBefore(now)) {
                await service.post(post['text']);
                await db.markAsSent(post['id']);
              }
            }
          } else {
            for (final account in accounts) {
              try {
                final session = Session.fromJson(account['session']);
                await service.activateSession(session);
                
                final scheduledPosts = await db.getScheduledPosts(account['did']);
                for (final post in scheduledPosts) {
                  final scheduledAt = DateTime.parse(post['scheduled_at']);
                  if (scheduledAt.isBefore(now)) {
                    await service.post(post['text']);
                    await db.markAsSent(post['id']);
                  }
                }
              } catch (e) {
                print("Error processing account ${account['handle']}: $e");
              }
            }
          }
        } catch (e) {
          print("Background task error: $e");
          return false;
        }
        break;
    }
    return true;
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    
    // Register periodic task
    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        "1",
        taskCheckScheduledPosts,
        frequency: const Duration(minutes: 15), // Minimum for Android
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    } else if (Platform.isIOS) {
      // iOS has stricter limitations, usually handled via background fetch
      // Workmanager on iOS is limited
    }
  }
}
