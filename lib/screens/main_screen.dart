import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import 'talk_list_screen.dart';
import 'home_screen.dart';
import 'chat_detail_wrapper.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'others_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Default to 'Talk' (index 1)

  @override
  void initState() {
    super.initState();
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
      const OthersScreen(),
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
        },
        selectedItemColor: const Color(0xFF00C300),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: AppLocalizations.of(context).nav_home),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_outlined), activeIcon: const Icon(Icons.chat), label: AppLocalizations.of(context).nav_talk),
          BottomNavigationBarItem(icon: const Icon(Icons.search), activeIcon: const Icon(Icons.search), label: AppLocalizations.of(context).nav_search),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_outlined), activeIcon: const Icon(Icons.notifications), label: AppLocalizations.of(context).nav_notifications),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
            label: AppLocalizations.of(context).nav_others,
          ),
        ],
      ),
    );
  }
}

// ChatDetailWrapper moved to its own file: chat_detail_wrapper.dart
