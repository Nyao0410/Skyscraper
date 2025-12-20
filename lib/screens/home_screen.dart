import 'package:flutter/material.dart';
import 'timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<dynamic> _customFeeds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _fetchFeeds();
  }

  Future<void> _fetchFeeds() async {
    try {
      // In a real app, we might fetch the user's pinned feeds here
      // For now, we just have "Following"
      if (mounted) {
        setState(() {
          // We could add more feeds here
        });
      }
    } catch (e) {
      debugPrint('Error fetching feeds: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: _customFeeds.isEmpty 
          ? null 
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                const Tab(text: 'Following'),
                ..._customFeeds.map((f) => Tab(text: f.displayName)),
              ],
            ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const TimelineScreen(showAppBar: false), // Use the existing TimelineScreen as the "Following" feed
          ..._customFeeds.map((f) => Center(child: Text('Feed: ${f.displayName}'))),
        ],
      ),
    );
  }
}
