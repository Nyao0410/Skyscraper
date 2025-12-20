import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/post_item.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'services/bluesky_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ja_JP';
  await initializeDateFormatting('ja_JP', null);
  runApp(const BskyApp());
}

class BskyApp extends StatelessWidget {
  const BskyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluesky LINE Client',
      theme: ThemeData(
        primaryColor: const Color(0xFF00C300),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C300)),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = BlueskyService();

  bool _isLoggedIn = false;
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  List<PostItem> _feed = [];

  Future<void> _handleLogin(String handle, String password) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.login(handle, password);
      setState(() => _isLoggedIn = true);
      await _fetchTimeline();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchTimeline() async {
    if (!_isLoggedIn) return;

    setState(() => _refreshing = true);

    try {
      final list = await _service.getTimeline(limit: 40);
      // debugPrint('Main: Fetched ${list.length} posts');
      setState(() => _feed = list);
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タイムラインの取得に失敗しました: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.isEmpty) return;

    if (!mounted) return;

    // Show sending indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('投稿中...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await _service.post(text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('投稿しました!'),
            ],
          ),
          backgroundColor: Color(0xFF00C300),
          duration: Duration(seconds: 1),
        ),
      );

      await _fetchTimeline();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      final errorMessage = e.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('投稿エラー: $errorMessage')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() => _error = errorMessage);
    }
  }

  Future<void> _handleLike(PostItem item) async {
    try {
      debugPrint('Attempting to like post: CID=${item.id}, URI=${item.uri}');
      await _service.like(item.id, item.uri);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('いいねしました')),
      );
    } catch (e) {
      debugPrint('Like failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('いいね失敗: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleRepost(PostItem item) async {
    try {
      debugPrint('Attempting to repost post: CID=${item.id}, URI=${item.uri}');
      await _service.repost(item.id, item.uri);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RPしました')),
      );
    } catch (e) {
      debugPrint('Repost failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RP失敗: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleDelete(PostItem item) async {
    try {
      debugPrint('Attempting to delete post: URI=${item.uri}');
      await _service.delete(item.uri);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除しました')),
      );
      _fetchTimeline(); // Refresh timeline
    } catch (e) {
      debugPrint('Delete failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除失敗: ${e.toString()}')),
      );
    }
  }

  void _handleReply(PostItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('返信機能は未実装です')),
    );
  }

  void _handleQuote(PostItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('引用機能は未実装です')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLogin: _handleLogin,
        isLoading: _loading,
        error: _error,
      );
    }

    return ChatScreen(
      messages: _feed,
      isRefreshing: _refreshing,
      onRefresh: _fetchTimeline,
      onSendMessage: _handleSendMessage,
      onLike: _handleLike,
      onRepost: _handleRepost,
      onReply: _handleReply,
      onQuote: _handleQuote,
      onDelete: _handleDelete,
    );
  }
}
