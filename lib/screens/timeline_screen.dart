import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _service = BlueskyService();
  List<PostItem> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    try {
      final posts = await _service.getTimeline();
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('タイムライン', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTimeline,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: _posts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: post.avatar != null
                              ? CachedNetworkImageProvider(post.avatar!)
                              : null,
                          child: post.avatar == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: post.author,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: ' @${post.handle}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    post.createdAt.toLocal().toString().substring(11, 16),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(post.text),
                              if (post.media.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: post.media.first.url,
                                    placeholder: (context, url) => Container(
                                      height: 200,
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildActionIcon(Icons.chat_bubble_outline, post.replyCount.toString()),
                                  _buildActionIcon(Icons.repeat, post.repostCount.toString()),
                                  _buildActionIcon(Icons.favorite_border, post.likeCount.toString()),
                                  const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF00C300),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
