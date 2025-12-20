import 'package:flutter/material.dart';

import 'models/post_item.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'services/bluesky_service.dart';

void main() {
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
      debugPrint('Main: Fetched ${list.length} posts');
      setState(() => _feed = list);
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タイムラインの取得に失敗しました: $e')),
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
    );
  }
}
