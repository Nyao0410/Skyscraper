// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Skyscraper';

  @override
  String get login_title => 'Skyscraper';

  @override
  String get login_subtitle => 'トーク形式で楽しむBluesky';

  @override
  String get login_info =>
      'ログイン方法: Blueskyでアプリパスワードを作成し、ハンドル名（example.bsky.social）と入力してください。';

  @override
  String get login_handle_label => 'HANDLE';

  @override
  String get login_handle_hint => 'example.bsky.social';

  @override
  String get login_password_label => 'APP PASSWORD';

  @override
  String get login_password_hint => 'abcd-1234-efgh-5678';

  @override
  String get login_button => 'ログイン';

  @override
  String get login_loading => 'ログイン中...';

  @override
  String get login_status_checking => 'SDK動作確認中...';

  @override
  String get login_status_ready => 'Bluesky SDK準備完了';

  @override
  String get home_welcome => 'Blueskyへようこそ';

  @override
  String get home_post_button => '投稿する';

  @override
  String get home_menu_title => 'メニュー';

  @override
  String get home_timeline => 'タイムライン';

  @override
  String get home_my_profile => '自分のプロフィール';

  @override
  String get home_saved_feeds => '保存済みフィード';

  @override
  String get home_unknown_feed => '不明なフィード';

  @override
  String get home_talk => 'トーク';

  @override
  String get post_new_title => '新規投稿';

  @override
  String get post_edit_draft_title => '下書き編集';

  @override
  String get post_reply_title => '返信';

  @override
  String get post_quote_title => '引用';

  @override
  String get post_image_limit => '画像は最大4枚までです';

  @override
  String get post_reply_schedule_not_supported => '返信の予約投稿は現在サポートされていません';

  @override
  String get post_draft_saved => '下書きを保存しました';

  @override
  String get post_scheduled_success => '投稿を予約しました（画像は現在サポートされていません）';

  @override
  String get post_reply_success => '返信しました';

  @override
  String get post_quote_success => '引用投稿しました';

  @override
  String get post_success => '投稿しました';

  @override
  String get post_draft_button => '下書き';

  @override
  String get post_save_draft_button => '下書き保存';

  @override
  String get post_schedule_button => '予約';

  @override
  String get post_button => '投稿';

  @override
  String get post_hint_reply => '返信を入力...';

  @override
  String get post_hint_default => 'いまどうしてる？';

  @override
  String get timeline_title => 'タイムライン';

  @override
  String get timeline_no_posts => '投稿がありません';

  @override
  String timeline_reposted_by(String user) {
    return '$user さんがリポスト';
  }

  @override
  String get timeline_quote_post => '引用して投稿';

  @override
  String get search_hint => '検索ワード、#タグ、@ユーザー...';

  @override
  String get search_clear_filter => 'フィルターをクリア';

  @override
  String get search_specify_period => '期間指定';

  @override
  String get search_tab_posts => '投稿';

  @override
  String get search_tab_users => 'ユーザー';

  @override
  String search_period_label(String start, String end) {
    return '期間: $start 〜 $end';
  }

  @override
  String get search_no_posts => '投稿が見つかりませんでした';

  @override
  String get search_no_users => 'ユーザーが見つかりませんでした';

  @override
  String get profile_not_found => 'プロフィールが見つかりませんでした';

  @override
  String get profile_tab_posts => '投稿';

  @override
  String get profile_tab_replies => '返信';

  @override
  String get profile_tab_media => 'メディア';

  @override
  String get profile_tab_video => 'ビデオ';

  @override
  String get profile_tab_feeds => 'フィード';

  @override
  String get profile_no_data => 'データがありません';

  @override
  String get profile_unmute => 'ミュート解除';

  @override
  String get profile_mute => 'ミュート';

  @override
  String get profile_block => 'ブロック';

  @override
  String get profile_unblock => 'ブロック解除';

  @override
  String profile_search_posts_title(String handle) {
    return '@$handle の投稿を検索';
  }

  @override
  String get profile_search_posts_hint => 'キーワードを入力';

  @override
  String profile_url_label(String url) {
    return 'プロフィールURL: $url';
  }

  @override
  String get profile_follows => 'フォロー';

  @override
  String get profile_followers => 'フォロワー';

  @override
  String get profile_edit_button => 'プロフィールを編集';

  @override
  String get profile_following_status => 'フォロー中';

  @override
  String get profile_edit_title => 'プロフィールを編集';

  @override
  String get profile_display_name => '表示名';

  @override
  String get profile_description => '自己紹介';

  @override
  String get save => '保存';

  @override
  String get profile_no_users => 'ユーザーがいません';

  @override
  String error_with_message(String message) {
    return 'エラー: $message';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get search => '検索';

  @override
  String get delete => '削除';

  @override
  String get share => '共有';

  @override
  String get copyText => 'テキストをコピー';

  @override
  String get now => '今';

  @override
  String get minutes => '分';

  @override
  String get hours => '時間';

  @override
  String get user => 'ユーザー';

  @override
  String get unknown => '不明';

  @override
  String get others_title => 'その他';

  @override
  String get others_account => 'アカウント';

  @override
  String get others_switch_account => 'アカウントを切り替える';

  @override
  String get others_logout => 'ログアウト';

  @override
  String get others_general => '一般';

  @override
  String get others_language => '言語';

  @override
  String get others_font_size => 'フォントサイズ';

  @override
  String get others_theme => 'テーマ';

  @override
  String get others_storage => 'ストレージ';

  @override
  String get others_app_settings => '機能';

  @override
  String get others_drafts => '下書き';

  @override
  String get drafts_no_drafts => '下書きはありません';

  @override
  String drafts_created_at(String date) {
    return '作成: $date';
  }

  @override
  String drafts_scheduled_at(String date) {
    return '予約: $date';
  }

  @override
  String get thread_title => 'スレッド';

  @override
  String get thread_not_found => 'スレッドが見つかりませんでした';

  @override
  String get thread_parse_error => 'スレッドデータを解析できませんでした';

  @override
  String get post_not_viewable => 'この投稿は表示できません';

  @override
  String get feed_search_title => 'フィード・リストを探す';

  @override
  String get feed_search_hint => 'フィードを検索';

  @override
  String get feed_search_tab_feeds => 'フィード';

  @override
  String get feed_search_tab_lists => 'マイリスト';

  @override
  String feed_search_added(String name) {
    return '$name を追加しました';
  }

  @override
  String get others_advanced_settings => '詳細設定';

  @override
  String get others_support => 'サポート';

  @override
  String get others_help => 'ヘルプ';

  @override
  String get others_terms => '利用規約';

  @override
  String get others_privacy => 'プライバシーポリシー';

  @override
  String get others_version => 'バージョン';

  @override
  String get storage_title => 'ストレージ';

  @override
  String get storage_cache_title => 'キャッシュデータ';

  @override
  String get storage_cache_desc => '一時的なデータを削除して空き容量を増やします。投稿や画像は削除されません。';

  @override
  String get storage_clear_cache => 'キャッシュを削除';

  @override
  String get storage_clearing => '削除中...';

  @override
  String get storage_calculating => '計算中...';

  @override
  String get storage_clear_confirm_title => 'キャッシュを削除しますか？';

  @override
  String get storage_clear_confirm_msg => '一時的なデータを削除します。よろしいですか？';

  @override
  String get storage_clear_success => 'キャッシュを削除しました';

  @override
  String get storage_clear_error => 'キャッシュの削除に失敗しました';

  @override
  String get theme_title => 'テーマ';

  @override
  String get theme_system => 'システム設定に従う';

  @override
  String get theme_light => 'ライトモード';

  @override
  String get theme_dark => 'ダークモード';

  @override
  String get chat_hint => 'メッセージを入力';

  @override
  String get nav_home => 'ホーム';

  @override
  String get nav_talk => 'トーク';

  @override
  String get nav_search => '検索';

  @override
  String get nav_notifications => '通知';

  @override
  String get nav_others => 'その他';

  @override
  String get notifications_title => '通知';

  @override
  String get notifications_empty => '通知はありません';

  @override
  String get notifications_liked => 'があなたの投稿を「いいね」しました';

  @override
  String get notifications_reposted => 'があなたの投稿をリポストしました';

  @override
  String get notifications_followed => 'があなたをフォローしました';

  @override
  String get notifications_replied => 'があなたに返信しました';

  @override
  String get notifications_quoted => 'があなたの投稿を引用しました';

  @override
  String get notifications_mentioned => 'があなたをメンションしました';

  @override
  String get font_size_title => 'フォントサイズ';

  @override
  String get close => '閉じる';

  @override
  String rate_limit_banner(int remaining, int limit, String reset) {
    return 'API残り: $remaining / $limit (リセット: $reset)';
  }

  @override
  String get font_size_small => '小';

  @override
  String get font_size_medium => '中';

  @override
  String get font_size_large => '大';

  @override
  String get font_size_extra_large => '特大';

  @override
  String get font_size_preview => 'プレビュー';

  @override
  String get font_size_preview_msg => 'これはフォントサイズのプレビューです。スライダーを動かして調整してください。';

  @override
  String get language_title => '言語';

  @override
  String get language_japanese => '日本語';

  @override
  String get language_english => 'English';

  @override
  String get talk_list_title => 'トーク';

  @override
  String get talk_list_fetch_error => 'フィードの取得に失敗しました';

  @override
  String get post_error => '投稿失敗';

  @override
  String get following_feed_desc => 'フォロー中の投稿';

  @override
  String get profile_handle => 'ハンドル';

  @override
  String get profile_did => 'DID';

  @override
  String version_label(String version) {
    return 'バージョン $version';
  }

  @override
  String get repost_undo => 'リポストを取り消す';

  @override
  String get repost => 'リポスト';

  @override
  String get loading => '読み込み中...';

  @override
  String get settings_title => '詳細設定';

  @override
  String get settings_current_remaining => '現在の残りリクエスト数';

  @override
  String get settings_fetching => '取得中...';

  @override
  String get settings_enable_alert => 'レート制限アラートを有効にする';

  @override
  String get settings_alert_desc => '残りリクエスト数が少なくなったときにアプリ内で通知します';

  @override
  String get settings_threshold => '残りリクエストしきい値';

  @override
  String settings_threshold_desc(int threshold) {
    return 'しきい値以下になるとバナーが表示されます（現在: $threshold）';
  }

  @override
  String get settings_usage_approx => '現在の使用量（近似）';

  @override
  String get settings_no_data => 'データ未取得';

  @override
  String get settings_no_data_desc => 'APIヘッダ情報がまだ取得されていません。操作を実行すると取得されます。';

  @override
  String settings_remaining_label(String remaining) {
    return '残りリクエスト数: $remaining';
  }

  @override
  String settings_limit_reset_label(String limit, String reset) {
    return '上限: $limit / リセット予定: $reset';
  }

  @override
  String get settings_note_title => '注意';

  @override
  String get settings_note_desc => '表示はサーバーが返すヘッダ情報からの推定値です。実際の残りはサーバー側で変化します。';

  @override
  String get parse_error => '解析エラー';

  @override
  String login_failed(String error) {
    return 'ログイン失敗: $error';
  }

  @override
  String api_error(String error) {
    return 'API エラー: $error';
  }

  @override
  String network_error(String error) {
    return 'ネットワークエラー: $error';
  }

  @override
  String get not_logged_in => 'ログインしていません';

  @override
  String auth_error(String error) {
    return '認証エラー: $error';
  }

  @override
  String timeline_fetch_failed(String error) {
    return 'タイムライン取得失敗: $error';
  }

  @override
  String feed_fetch_failed(String error) {
    return 'フィード取得失敗: $error';
  }

  @override
  String get post_content_empty => '投稿内容が空です';

  @override
  String get post_too_long => '投稿は300文字以内にしてください';

  @override
  String post_failed(String error) {
    return '投稿失敗: $error';
  }

  @override
  String get language_not_implemented => '言語切り替えはまだ実装されていません';
}
