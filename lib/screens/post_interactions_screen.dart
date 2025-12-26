import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../models/actor_item.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../utils/avatar_provider.dart';
import '../widgets/post_widget.dart';
import 'profile_screen.dart';

class PostInteractionsScreen extends StatefulWidget {
  final String postUri;
  final int initialTabIndex;

  const PostInteractionsScreen({
    super.key,
    required this.postUri,
    this.initialTabIndex = 0,
  });

  @override
  State<PostInteractionsScreen> createState() => _PostInteractionsScreenState();
}

class _PostInteractionsScreenState extends State<PostInteractionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = BlueskyService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.post_interactions_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.post_interactions_reposts),
            Tab(text: l10n.post_interactions_quotes),
            Tab(text: l10n.post_interactions_likes),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActorList(
            future: _service.getRepostedBy(widget.postUri),
            emptyText: l10n.post_interactions_no_reposts,
          ),
          _QuoteList(
            future: _service.getQuotes(widget.postUri),
            emptyText: l10n.post_interactions_no_quotes,
          ),
          _ActorList(
            future: _service.getLikes(widget.postUri),
            emptyText: l10n.post_interactions_no_likes,
          ),
        ],
      ),
    );
  }
}

class _ActorList extends StatelessWidget {
  final Future<List<ActorItem>> future;
  final String emptyText;

  const _ActorList({required this.future, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActorItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final actors = snapshot.data ?? [];
        if (actors.isEmpty) {
          return Center(child: Text(emptyText));
        }
        return ListView.separated(
          itemCount: actors.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final actor = actors[index];
            return ListTile(
              leading: kIsWeb
                  ? ClipOval(
                      child: actor.avatar != null && actor.avatar!.isNotEmpty
                          ? Image.network(
                              actor.avatar!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person),
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                              child: const Icon(Icons.person),
                            ),
                    )
                  : CircleAvatar(
                      backgroundImage: avatarImageProvider(actor.avatar),
                      child: actor.avatar == null ? const Icon(Icons.person) : null,
                    ),
              title: Text(actor.displayName ?? actor.handle, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('@${actor.handle}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(actor: actor.did)),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _QuoteList extends StatelessWidget {
  final Future<List<PostItem>> future;
  final String emptyText;

  const _QuoteList({required this.future, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PostItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(child: Text(emptyText));
        }
        return ListView.separated(
          itemCount: posts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return PostWidget(post: posts[index]);
          },
        );
      },
    );
  }
}
