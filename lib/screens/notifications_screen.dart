import 'package:flutter/material.dart' hide Notification;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/bluesky_service.dart';
import 'profile_screen.dart';
import 'thread_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = BlueskyService();
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _loading = false;
        });
        // Mark as seen
        _service.updateNotificationsSeen();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('通知はありません', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationItem(notification);
                },
              ),
      ),
    );
  }

  Widget _buildNotificationItem(dynamic notification) {
    IconData icon;
    Color color;
    String text;

    final reason = notification.reason.toString();

    if (reason.contains('like')) {
      icon = Icons.favorite;
      color = Colors.pink;
      text = 'があなたの投稿を「いいね」しました';
    } else if (reason.contains('repost')) {
      icon = Icons.repeat;
      color = Colors.green;
      text = 'があなたの投稿をリポストしました';
    } else if (reason.contains('follow')) {
      icon = Icons.person_add;
      color = Colors.blue;
      text = 'があなたをフォローしました';
    } else if (reason.contains('mention')) {
      icon = Icons.alternate_email;
      color = Colors.orange;
      text = 'があなたをメンションしました';
    } else if (reason.contains('reply')) {
      icon = Icons.reply;
      color = Colors.blue;
      text = 'があなたに返信しました';
    } else if (reason.contains('quote')) {
      icon = Icons.format_quote;
      color = Colors.blue;
      text = 'があなたの投稿を引用しました';
    } else {
      icon = Icons.notifications;
      color = Colors.grey;
      text = '通知がありました ($reason)';
    }

    return ListTile(
      leading: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(actor: notification.author.did),
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: notification.author.avatar != null
                  ? CachedNetworkImageProvider(notification.author.avatar!)
                  : null,
              child: notification.author.avatar == null
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Icon(icon, size: 12, color: color),
            ),
          ),
        ],
      ),
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text:
                  notification.author.displayName ?? notification.author.handle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' $text'),
          ],
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              DateFormat('yyyy/MM/dd HH:mm').format(notification.indexedAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
      onTap: () {
        if (notification.reasonSubject != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ThreadScreen(postUri: notification.reasonSubject!.toString()),
            ),
          );
        } else if (notification.uri != null &&
            (reason.contains('reply') ||
                reason.contains('mention') ||
                reason.contains('quote'))) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ThreadScreen(postUri: notification.uri.toString()),
            ),
          );
        }
      },
    );
  }
}
