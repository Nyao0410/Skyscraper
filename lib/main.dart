import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      theme: ThemeData(primaryColor: const Color(0xFF00C300)),
      home: const HomePage(),
    );
  }
}

class PostItem {
  final String id;
  final String author;
  final String handle;
  final String? avatar;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final List<MediaItem> media;

  PostItem({
    required this.id,
    required this.author,
    required this.handle,
    this.avatar,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.media = const [],
  });

  factory PostItem.fromMap(Map<String, dynamic> item, String? myHandle) {
    final post = item['post'] ?? {};
    final author = post['author'] ?? {};
    final record = post['record'] ?? {};
    final embed = post['embed'];

    List<MediaItem> mediaList = [];
    if (embed != null) {
      // Handle images embed
      if (embed['\$type'] == 'app.bsky.embed.images#view' ||
          embed['\$type'] == 'app.bsky.embed.images') {
        final images = embed['images'] as List<dynamic>? ?? [];
        mediaList = images
            .map((img) {
              final url = img['fullsize'] ?? img['thumb'] ?? '';
              if (url.isEmpty) return null;
              return MediaItem(
                type: MediaType.image,
                url: url,
                alt: img['alt'] ?? '',
              );
            })
            .whereType<MediaItem>()
            .toList();
      }
      // Handle video embed
      else if (embed['\$type'] == 'app.bsky.embed.video#view' ||
          embed['\$type'] == 'app.bsky.embed.video') {
        final playlist = embed['playlist'] ?? embed['thumbnail'] ?? '';
        if (playlist is String && playlist.isNotEmpty) {
          mediaList = [
            MediaItem(type: MediaType.video, url: playlist, alt: 'Video'),
          ];
        }
      }
      // Handle external embed with thumbnail
      else if (embed['\$type'] == 'app.bsky.embed.external#view') {
        final external = embed['external'];
        final thumbUrl = external?['thumb'] ?? '';
        if (external != null && thumbUrl is String && thumbUrl.isNotEmpty) {
          mediaList = [
            MediaItem(
              type: MediaType.image,
              url: thumbUrl,
              alt: external['title'] ?? 'External link',
            ),
          ];
        }
      }
      // Handle record with media (quote posts with images)
      else if (embed['\$type'] == 'app.bsky.embed.recordWithMedia#view') {
        final media = embed['media'];
        if (media != null && media['images'] != null) {
          final images = media['images'] as List<dynamic>? ?? [];
          mediaList = images
              .map((img) {
                final url = img['fullsize'] ?? img['thumb'] ?? '';
                if (url.isEmpty) return null;
                return MediaItem(
                  type: MediaType.image,
                  url: url,
                  alt: img['alt'] ?? '',
                );
              })
              .whereType<MediaItem>()
              .toList();
        }
      }
    }

    return PostItem(
      id: (post['cid'] ?? '') as String,
      author: (author['displayName'] ?? author['handle'] ?? '') as String,
      handle: (author['handle'] ?? '') as String,
      avatar: author['avatar'] as String?,
      text: (record['text'] ?? '') as String,
      createdAt: DateTime.tryParse(record['createdAt'] ?? '') ?? DateTime.now(),
      isMe: (author['handle'] ?? '') == myHandle,
      media: mediaList,
    );
  }
}

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;
  final String alt;

  MediaItem({required this.type, required this.url, this.alt = ''});
}

class BskyService {
  final String host;
  String? jwt;
  String? refreshJwt;
  String? handle;
  String? did;

  BskyService({this.host = 'https://bsky.social'});

  Future<void> login(String inputHandle, String password) async {
    // If user did not include a domain, append .bsky.social
    final normalized = inputHandle.contains('.')
        ? inputHandle
        : '$inputHandle.bsky.social';
    final url = Uri.parse('$host/xrpc/com.atproto.server.createSession');

    try {
      final resp = await http.post(
        url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'identifier': normalized, 'password': password}),
      );

      if (resp.statusCode != 200) {
        final errorBody = resp.body;
        String errorMsg = 'ログインに失敗しました';
        try {
          final errorJson = jsonDecode(errorBody);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {
          errorMsg = '$errorMsg (${resp.statusCode})';
        }
        throw Exception(errorMsg);
      }

      final js = jsonDecode(resp.body);
      jwt = js['accessJwt'] as String?;
      refreshJwt = js['refreshJwt'] as String?;
      handle = js['handle'] as String?;
      did = js['did'] as String?;

      if (jwt == null || handle == null || did == null) {
        throw Exception('ログイン応答が不完全です');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('ネットワークエラー: $e');
    }
  }

  Future<List<PostItem>> getTimeline({int limit = 40}) async {
    if (jwt == null) throw Exception('ログインしていません');
    final url = Uri.parse('$host/xrpc/app.bsky.feed.getTimeline?limit=$limit');

    try {
      final resp = await http.get(
        url,
        headers: {'authorization': 'Bearer $jwt'},
      );

      if (resp.statusCode != 200) {
        final errorBody = resp.body;
        String errorMsg = 'タイムライン取得失敗';
        try {
          final errorJson = jsonDecode(errorBody);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {
          errorMsg = '$errorMsg (${resp.statusCode})';
        }
        throw Exception(errorMsg);
      }

      final js = jsonDecode(resp.body) as Map<String, dynamic>;
      final feed = (js['feed'] as List<dynamic>? ?? [])
          .map((e) {
            try {
              return PostItem.fromMap(e as Map<String, dynamic>, handle);
            } catch (e) {
              // Skip malformed posts
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();
      // Reverse to match chat bottom-first behavior
      return feed.reversed.toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('ネットワークエラー: $e');
    }
  }

  Future<void> post(String text) async {
    if (jwt == null || did == null) {
      throw Exception('ログインしていません');
    }

    if (text.trim().isEmpty) {
      throw Exception('投稿内容が空です');
    }

    if (text.length > 300) {
      throw Exception('投稿は300文字以内にしてください');
    }

    final url = Uri.parse('$host/xrpc/com.atproto.repo.createRecord');

    try {
      final resp = await http.post(
        url,
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'repo': did,
          'collection': 'app.bsky.feed.post',
          'record': {
            'text': text,
            'createdAt': DateTime.now().toIso8601String(),
            '\$type': 'app.bsky.feed.post',
          },
        }),
      );

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        final errorBody = resp.body;
        String errorMsg = '投稿に失敗しました';
        try {
          final errorJson = jsonDecode(errorBody);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {
          errorMsg = '$errorMsg (${resp.statusCode})';
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('ネットワークエラー: $e');
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = BskyService();
  final _scrollController = ScrollController();

  bool _isLoggedIn = false;
  bool _loading = false;
  bool _refreshing = false;
  String _handle = '';
  String _password = '';
  String _error = '';
  List<PostItem> _feed = [];
  String _inputText = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_handle.isEmpty || _password.isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _service.login(_handle.trim(), _password);
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
      setState(() => _feed = list);
      // scroll to bottom
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _send() async {
    final text = _inputText.trim();
    if (text.isEmpty) return;
    setState(() {
      _inputText = '';
    });
    try {
      await _service.post(text);
      await _fetchTimeline();
    } catch (e) {
      setState(() => _error = e.toString());
      // put text back
      setState(() => _inputText = text);
    }
  }

  List<Widget> _buildMediaWidgets(List<MediaItem> media, bool isMe) {
    return media.map((item) {
      if (item.type == MediaType.image) {
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260, maxHeight: 300),
              child: Image.network(
                item.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
        );
      } else if (item.type == MediaType.video) {
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260, maxHeight: 200),
              color: Colors.black87,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '動画',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  Widget _buildLogin() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C300),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bluesky LINE Client',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'トーク形式で楽しむBluesky',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ログイン方法: Blueskyでアプリパスワードを作成し、ハンドル名（example.bsky.social）と入力してください。',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'HANDLE',
                  hintText: 'example.bsky.social',
                ),
                onChanged: (v) => setState(() => _handle = v),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'APP PASSWORD',
                  hintText: 'abcd-1234-efgh-5678',
                ),
                onChanged: (v) => setState(() => _password = v),
              ),
              const SizedBox(height: 12),
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_loading) ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 8),
                            Text('ログイン中...'),
                          ],
                        )
                      : const Text(
                          'ログイン',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (_loading) ? 'SDK動作確認中...' : 'SDK準備完了',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Scaffold(
      backgroundColor: const Color(0xFF7494C0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7494C0),
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Bluesky タイムライン',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('オンライン', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchTimeline,
            icon: _refreshing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: _feed.isEmpty && !_refreshing
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white30,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '投稿を読み込んでいます',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _feed.length,
                      itemBuilder: (context, idx) {
                        final msg = _feed[idx];
                        final isMe = msg.isMe;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    msg.avatar ??
                                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(msg.author)}&background=random',
                                  ),
                                  radius: 20,
                                ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg.author,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (msg.text.isNotEmpty)
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 260,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? const Color(0xFF8DE055)
                                                : Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                18,
                                              ),
                                              topRight: const Radius.circular(
                                                18,
                                              ),
                                              bottomLeft: Radius.circular(
                                                isMe ? 18 : 4,
                                              ),
                                              bottomRight: Radius.circular(
                                                isMe ? 4 : 18,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                msg.text,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.black
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Text(
                                                  '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (msg.media.isNotEmpty)
                                        ..._buildMediaWidgets(msg.media, isMe),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'メッセージを入力',
                        ),
                        controller: TextEditingController(text: _inputText)
                          ..selection = TextSelection.collapsed(
                            offset: _inputText.length,
                          ),
                        onChanged: (v) => setState(() => _inputText = v),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _inputText.trim().isEmpty ? null : _send,
                    icon: Icon(
                      Icons.send,
                      color: _inputText.trim().isEmpty
                          ? Colors.grey.shade300
                          : const Color(0xFF00C300),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? _buildChat() : _buildLogin();
  }
}
