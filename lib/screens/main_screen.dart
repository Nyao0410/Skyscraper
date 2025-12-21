import 'package:flutter/material.dart';
import '../services/bluesky_service.dart';
import '../services/database_service.dart';
import '../utils/avatar_provider.dart';
import 'talk_list_screen.dart';
import 'home_screen.dart';
import 'chat_detail_wrapper.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'drafts_screen.dart';
import 'settings_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Default to 'Talk' (index 1)
  final _service = BlueskyService();
  final _db = DatabaseService();
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    _updateDraftCount();
  }

  Future<void> _updateDraftCount() async {
    if (_service.did == null) return;
    final count = await _db.getDraftCount(_service.did!);
    if (mounted) {
      setState(() {
        _draftCount = count;
      });
    }
  }
  
  void _navigateToChat(String name, String uri) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailWrapper(feedName: name, feedUri: uri),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      TalkListScreen(onFeedSelected: _navigateToChat),
      const SearchScreen(),
      const NotificationsScreen(),
      _buildOtherScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _updateDraftCount();
        },
        selectedItemColor: const Color(0xFF00C300),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'ホーム'),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'トーク'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search), label: '検索'),
          const BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: '通知'),
          BottomNavigationBarItem(
            icon: Badge(
              label: _draftCount > 0 ? Text(_draftCount.toString()) : null,
              isLabelVisible: _draftCount > 0,
              child: const Icon(Icons.more_horiz),
            ),
            label: 'その他',
          ),
        ],
      ),
    );
  }

  Widget _buildOtherScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getAccounts(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        
        return Scaffold(
          appBar: AppBar(title: const Text('その他')),
          body: ListView(
            children: [
              // Current Account
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatarImageProvider(_service.avatar),
                  child: _service.avatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(_service.handle ?? 'ユーザー'),
                subtitle: Text(_service.did ?? ''),
                trailing: const Icon(Icons.check, color: Colors.green),
              ),
              const Divider(),
              
              // Other Accounts
              if (accounts.length > 1) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('アカウント切り替え', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ...accounts.where((a) => a['did'] != _service.did).map((account) => ListTile(
                    leading: CircleAvatar(
                    backgroundImage: avatarImageProvider(account['avatar']),
                    child: account['avatar'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(account['handle'] ?? ''),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await _service.switchAccount(account['did']);
                    if (mounted) {
                      // Reload the whole app state
                      navigator.pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                )),
                const Divider(),
              ],

              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('別のアカウントを追加'),
                onTap: () {
                  // Navigate to login but don't clear current session yet
                  Navigator.pushNamed(context, '/login');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('下書き・予約投稿'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DraftsScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('設定'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await _service.logout();
                  if (mounted) {
                    final remaining = await _service.getAccounts();
                    if (remaining.isEmpty) {
                      navigator.pushReplacementNamed('/login');
                    } else {
                      // Switch to the first remaining account
                      await _service.switchAccount(remaining.first['did']);
                      navigator.pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  }
                },
              ),
            ],
          ),
        );
      }
    );
  }
}

// ChatDetailWrapper moved to its own file: chat_detail_wrapper.dart
