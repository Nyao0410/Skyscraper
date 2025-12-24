class ActorItem {
  final String did;
  final String handle;
  final String? displayName;
  final String? avatar;
  final String? description;
  final bool followedByViewer;
  final bool followingViewer;

  ActorItem({
    required this.did,
    required this.handle,
    this.displayName,
    this.avatar,
    this.description,
    this.followedByViewer = false,
    this.followingViewer = false,
  });

  factory ActorItem.fromActorView(dynamic view) {
    // Handle both Map and SDK objects
    if (view is Map) {
      return ActorItem(
        did: view['did'] as String,
        handle: view['handle'] as String,
        displayName: view['displayName'] as String?,
        avatar: view['avatar'] as String?,
        description: view['description'] as String?,
        followedByViewer: view['viewer']?['following'] != null,
        followingViewer: view['viewer']?['followedBy'] != null,
      );
    } else {
      final viewer = view.viewer;
      return ActorItem(
        did: view.did,
        handle: view.handle,
        displayName: view.displayName,
        avatar: view.avatar,
        description: view.description,
        followedByViewer: viewer?.following != null,
        followingViewer: viewer?.followedBy != null,
      );
    }
  }
}
