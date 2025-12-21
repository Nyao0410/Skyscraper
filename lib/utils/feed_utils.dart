import '../models/post_item.dart';

List<T> mergePosts<T>(List<T> existing, List<T> incoming, {bool atTop = false}) {
  final Map<String, T> itemMap = {};
  
  String? getUri(dynamic item) {
    if (item is PostItem) return item.uri;
    try {
      // Some SDK types have a uri property
      return item.uri?.toString();
    } catch (_) {
      return null;
    }
  }

  if (atTop) {
    for (var item in existing) {
      final uri = getUri(item);
      if (uri != null) itemMap[uri] = item;
    }
    for (var item in incoming) {
      final uri = getUri(item);
      if (uri != null) itemMap[uri] = item;
    }
    
    final List<T> result = List.from(incoming);
    final incomingUris = incoming.map((item) => getUri(item)).whereType<String>().toSet();
    for (var item in existing) {
      final uri = getUri(item);
      if (uri == null || !incomingUris.contains(uri)) {
        result.add(item);
      }
    }
    return result;
  } else {
    for (var item in existing) {
      final uri = getUri(item);
      if (uri != null) itemMap[uri] = item;
    }
    final List<T> result = List.from(existing);
    for (var item in incoming) {
      final uri = getUri(item);
      if (uri == null || !itemMap.containsKey(uri)) {
        result.add(item);
        if (uri != null) itemMap[uri] = item;
      }
    }
    return result;
  }
}
