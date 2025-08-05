/// 投稿者を表す、手動で実装されたプレーンなDartクラス。
class Author {
  /// Creates an [Author] instance.
  const Author({
    required this.handle,
    this.displayName,
    this.avatar,
  });

  /// JSONからAuthorインスタンスを生成するファクトリコンストラクタ。
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      handle: json['handle'] as String,
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  /// ユーザーハンドル。
  final String handle;

  /// 表示名。
  final String? displayName;

  /// アバター画像のURL。
  final String? avatar;
}
