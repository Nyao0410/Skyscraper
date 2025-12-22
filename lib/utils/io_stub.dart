// Minimal stubs to allow referencing dart:io types on web builds.
// These are only used when `dart:io` is not available (e.g. web).

class FileSystemEntity {}

class File extends FileSystemEntity {
  final String _path;
  File(this._path);
  String get path => _path;
  Future<int> length() async => 0;
  bool existsSync() => false;
  Future<void> writeAsBytes(List<int> bytes, {bool flush = false}) async {}
  Future<void> writeAsString(String s, {bool flush = false}) async {}
  Future<void> delete() async {}
  Future<void> rename(String newPath) async {}
  int lastModifiedSync() => 0;
}

class Directory extends FileSystemEntity {
  final String _path;
  Directory(this._path);
  String get path => _path;
  bool existsSync() => false;
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = false}) async* {}
}
