import 'package:flutter/material.dart' hide Notification;
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/avatar_provider.dart';
import 'package:intl/intl.dart';
import '../services/bluesky_service.dart';
import '../themes/line_theme.dart';
import 'profile_screen.dart';
import 'thread_screen.dart';

class NotificationGroup {
  final String reason;
  final String? subjectUri;
  final List<dynamic> items;
  final DateTime latestIndexedAt;
  final dynamic reasonSubject;

  NotificationGroup({
    required this.reason,
    this.subjectUri,
    required this.items,
    required this.latestIndexedAt,
    this.reasonSubject,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = BlueskyService();
  List<NotificationGroup> _groupedNotifications = [];
  final Map<String, dynamic> _subjectPosts = {};
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
        // Collect all reasonSubject URIs to fetch them in batch
        final Set<String> subjectUris = {};
        for (final n in notifications) {
          if (n.reasonSubject != null) {
            subjectUris.add(n.reasonSubject.toString());
          }
        }

        _groupNotifications(notifications);

        if (subjectUris.isNotEmpty) {
          try {
            final posts = await _service.getPosts(subjectUris.toList());
            if (mounted) {
              setState(() {
                for (final p in posts) {
                  try {
                    // Use the URI string as key
                    final pUri = p.uri.toString();
                    _subjectPosts[pUri] = p;
                  } catch (e) {
                    debugPrint('Error processing post in notifications: $e');
                  }
                }
              });
            }
          } catch (e) {
            debugPrint('Error fetching subject posts: $e');
          }
        }

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

  void _groupNotifications(List<dynamic> notifications) {
    final List<NotificationGroup> result = [];
    final Map<String, NotificationGroup> groups = {};

    for (final n in notifications) {
      final reason = n.reason.toString();
      String key;
      bool shouldGroup = false;

      if (reason.contains('like') || reason.contains('repost')) {
        final subject = n.reasonSubject?.toString() ?? 'unknown';
        key = '$reason:$subject';
        shouldGroup = true;
      } else if (reason.contains('follow')) {
        key = 'follow';
        shouldGroup = true;
      } else {
        // reply, mention, quote
        key = 'individual:${n.uri}';
        shouldGroup = false;
      }

      if (shouldGroup && groups.containsKey(key)) {
        groups[key]!.items.add(n);
      } else {
        final group = NotificationGroup(
          reason: reason,
          subjectUri: n.reasonSubject?.toString(),
          items: [n],
          latestIndexedAt: n.indexedAt,
          reasonSubject: n.reasonSubject,
        );
        if (shouldGroup) {
          groups[key] = group;
        }
        result.add(group);
      }
    }

    setState(() {
      _groupedNotifications = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: LineColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: LineColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.notifications_title,
          style: LineTextStyles.appBarTitle,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: LineColors.borderLight, height: 1),
        ),
      ),
      body: RefreshIndicator(
        color: LineColors.lineGreen,
        onRefresh: _fetchNotifications,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: LineColors.lineGreen),
              )
            : _groupedNotifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: LineColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.notifications_empty,
                      style: const TextStyle(color: LineColors.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _groupedNotifications.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 72),
                  child: Container(color: LineColors.borderLight, height: 1),
                ),
                itemBuilder: (context, index) {
                  final group = _groupedNotifications[index];
                  return _buildGroupedNotificationItem(group);
                },
              ),
      ),
    );
  }

  Widget _buildGroupedNotificationItem(NotificationGroup group) {
    final l10n = AppLocalizations.of(context);
    final isMultiple = group.items.length > 1;
    final firstItem = group.items.first;
    final reason = group.reason;
    // Precompute subject text so we don't use declarations inside widget children
    final subjectText = _getReasonSubjectText(group.reasonSubject);

    IconData icon;
    Color color;
    String text;

    if (reason.contains('like')) {
      icon = Icons.favorite;
      color = Colors.pink;
      text = l10n.notifications_liked;
    } else if (reason.contains('repost')) {
      icon = Icons.repeat;
      color = Colors.green;
      text = l10n.notifications_reposted;
    } else if (reason.contains('follow')) {
      icon = Icons.person_add;
      color = Colors.blue;
      text = l10n.notifications_followed;
    } else if (reason.contains('mention')) {
      icon = Icons.alternate_email;
      color = Colors.orange;
      text = l10n.notifications_mentioned;
    } else if (reason.contains('reply')) {
      icon = Icons.reply;
      color = Colors.blue;
      text = l10n.notifications_replied;
    } else if (reason.contains('quote')) {
      icon = Icons.format_quote;
      color = Colors.blue;
      text = l10n.notifications_quoted;
    } else {
      icon = Icons.notifications;
      color = Colors.grey;
      text = '${l10n.notifications_title} ($reason)';
    }

    return InkWell(
      onTap: () {
        if (group.subjectUri != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThreadScreen(postUri: group.subjectUri!),
            ),
          );
        } else if (firstItem.uri != null &&
            (reason.contains('reply') ||
                reason.contains('mention') ||
                reason.contains('quote'))) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ThreadScreen(postUri: firstItem.uri.toString()),
            ),
          );
        } else if (reason.contains('follow')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(actor: firstItem.author.did),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingAvatars(group, icon, color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildNotificationTitle(group, text)),
                      Text(
                        _formatDate(group.latestIndexedAt),
                        style: LineTextStyles.bodyText2,
                      ),
                    ],
                  ),
                  if (!isMultiple &&
                      (reason.contains('reply') ||
                          reason.contains('mention') ||
                          reason.contains('quote')))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getRecordText(firstItem),
                        style: LineTextStyles.bodyText2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Subject post preview (e.g. for likes/reposts)
                  if (group.reasonSubject != null && subjectText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: LineColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subjectText,
                          style: LineTextStyles.bodyText2.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingAvatars(
    NotificationGroup group,
    IconData icon,
    Color color,
  ) {
    final items = group.items;
    if (items.length == 1) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(actor: items.first.author.did),
                ),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundImage: avatarImageProvider(items.first.author.avatar),
              child: items.first.author.avatar == null
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
                border: Border.all(color: LineColors.borderLight, width: 1),
              ),
              child: Icon(icon, size: 12, color: color),
            ),
          ),
        ],
      );
    }

    // Multiple avatars
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          for (int i = 0; i < (items.length > 4 ? 4 : items.length); i++)
            Positioned(
              left: i * 8.0,
              top: i * 4.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: avatarImageProvider(items[i].author.avatar),
                  child: items[i].author.avatar == null
                      ? const Icon(Icons.person, size: 14)
                      : null,
                ),
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
                border: Border.all(color: LineColors.borderLight, width: 1),
              ),
              child: Icon(icon, size: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTitle(NotificationGroup group, String actionText) {
    final items = group.items;
    final firstAuthor =
        items.first.author.displayName ?? items.first.author.handle;

    if (items.length == 1) {
      return RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: LineTextStyles.bodyText1,
          children: [
            TextSpan(
              text: firstAuthor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' $actionText'),
          ],
        ),
      );
    }

    final count = items.length;
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: LineTextStyles.bodyText1,
        children: [
          TextSpan(
            text: firstAuthor,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' さん'),
          if (count > 1)
            TextSpan(
              text: '、他${count - 1}人',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          TextSpan(text: ' $actionText'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分';
    if (diff.inHours < 24) return '${diff.inHours}時間';
    if (diff.inDays < 7) return '${diff.inDays}日';

    return DateFormat('MM/dd').format(date);
  }

  String _getRecordText(dynamic notification) {
    try {
      if (notification.record != null && notification.record['text'] != null) {
        return notification.record['text'] as String;
      }
    } catch (_) {}
    return '';
  }

  String _getReasonSubjectText(dynamic reasonSubject) {
    if (reasonSubject == null) return '';
    final String uri = reasonSubject.toString();

    // 1. Try direct lookup
    dynamic post = _subjectPosts[uri];

    // 2. Try normalization lookup
    if (post == null) {
      final normalizedUri = uri.replaceFirst('at://', '');
      for (final entry in _subjectPosts.entries) {
        final entryUri = entry.key.replaceFirst('at://', '');
        if (entryUri == normalizedUri) {
          post = entry.value;
          break;
        }
      }
    }

    if (post == null) return '';

    // 3. Extract text
    try {
      // Try to get record
      dynamic record;
      if (post is Map) {
        record = post['record'] ?? post['value'];
      } else {
        try {
          record = (post as dynamic).record;
        } catch (_) {
          try {
            record = (post as dynamic).value;
          } catch (_) {}
        }
      }

      if (record != null) {
        if (record is Map) {
          if (record['text'] != null) return record['text'].toString();
        } else {
          try {
            return (record as dynamic).text.toString();
          } catch (_) {}
        }
      }

      // Try top-level text
      if (post is Map) {
        if (post['text'] != null) return post['text'].toString();
      } else {
        try {
          return (post as dynamic).text.toString();
        } catch (_) {}
      }

      // Try toJson fallback
      try {
        final dynamic json = (post as dynamic).toJson();
        final dynamic r = json['record'] ?? json['value'];
        if (r != null && r['text'] != null) return r['text'].toString();
      } catch (_) {}
    } catch (e) {
      debugPrint('Error in _getReasonSubjectText: $e');
    }

    return '';
  }
}
