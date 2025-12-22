// Minimal generated localization stub for analyzer/runtime.
// This file is intentionally small: it provides the keys used in the app.

// Localization getters intentionally use snake_case-like keys to match ARB
// keys and generated code. Suppress the identifier-name lint for this file.
// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final inherit = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return inherit ?? AppLocalizations(const Locale('ja'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  bool get _isEn => locale.languageCode == 'en';

  String get appTitle => 'Skyscraper';
  String get login_title => 'Skyscraper';
  String get login_subtitle => _isEn ? 'Enjoy Bluesky in Talk Format' : 'トーク形式で楽しむBluesky';
  String get login_info => _isEn ? 'How to login: Create an App Password on Bluesky and enter your handle (example.bsky.social).' : 'ログイン方法: Blueskyでアプリパスワードを作成し、ハンドル名（example.bsky.social）と入力してください。';
  String get login_handle_label => _isEn ? 'HANDLE' : 'HANDLE';
  String get login_handle_hint => _isEn ? 'example.bsky.social' : 'example.bsky.social';
  String get login_password_label => _isEn ? 'APP PASSWORD' : 'APP PASSWORD';
  String get login_password_hint => _isEn ? 'abcd-1234-efgh-5678' : 'abcd-1234-efgh-5678';
  String get login_button => _isEn ? 'Login' : 'ログイン';
  String get login_loading => _isEn ? 'Logging in...' : 'ログイン中...';
  String get login_status_checking => _isEn ? 'Checking SDK...' : 'SDK動作確認中...';
  String get login_status_ready => _isEn ? 'Bluesky SDK Ready' : 'Bluesky SDK準備完了';
  String get home_welcome => _isEn ? 'Welcome to Bluesky' : 'Blueskyへようこそ';
  String get home_post_button => _isEn ? 'Post' : '投稿する';
  String get home_menu_title => _isEn ? 'Menu' : 'メニュー';
  String get home_timeline => _isEn ? 'Timeline' : 'タイムライン';
  String get home_my_profile => _isEn ? 'My Profile' : '自分のプロフィール';
  String get home_saved_feeds => _isEn ? 'Saved Feeds' : '保存済みフィード';
  String get home_unknown_feed => _isEn ? 'Unknown Feed' : '不明なフィード';
  String get home_talk => _isEn ? 'Talk' : 'トーク';
  String get post_new_title => _isEn ? 'New Post' : '新規投稿';
  String get post_edit_draft_title => _isEn ? 'Edit Draft' : '下書き編集';
  String get post_reply_title => _isEn ? 'Reply' : '返信';
  String get post_quote_title => _isEn ? 'Quote' : '引用';
  String get post_image_limit => _isEn ? 'Maximum 4 images allowed' : '画像は最大4枚までです';
  String get post_reply_schedule_not_supported => _isEn ? 'Scheduled replies are not supported yet' : '返信の予約投稿は現在サポートされていません';
  String get post_draft_saved => _isEn ? 'Draft saved' : '下書きを保存しました';
  String get post_scheduled_success => _isEn ? 'Post scheduled (Images not supported for scheduled posts yet)' : '投稿を予約しました（画像は現在サポートされていません）';
  String get post_reply_success => _isEn ? 'Replied' : '返信しました';
  String get post_quote_success => _isEn ? 'Quoted' : '引用投稿しました';
  
  String get post_draft_button => _isEn ? 'Draft' : '下書き';
  String get post_save_draft_button => _isEn ? 'Save Draft' : '下書き保存';
  String get post_schedule_button => _isEn ? 'Schedule' : '予約';
  String get post_button => _isEn ? 'Post' : '投稿';
  String get post_hint_reply => _isEn ? 'Write a reply...' : '返信を入力...';
  String get post_hint_default => _isEn ? "What's happening?" : 'いまどうしてる？';
  String get timeline_title => _isEn ? 'Timeline' : 'タイムライン';
  String get timeline_no_posts => _isEn ? 'No posts found' : '投稿がありません';
  String timeline_reposted_by(String user) => _isEn ? 'Reposted by $user' : '$user さんがリポスト';
  String get timeline_quote_post => _isEn ? 'Quote Post' : '引用して投稿';
  String get search_hint => _isEn ? 'Search words, #tags, @users...' : '検索ワード、#タグ、@ユーザー...';
  String get search_clear_filter => _isEn ? 'Clear Filter' : 'フィルターをクリア';
  String get search_specify_period => _isEn ? 'Specify Period' : '期間指定';
  String get search_tab_posts => _isEn ? 'Posts' : '投稿';
  String get search_tab_users => _isEn ? 'Users' : 'ユーザー';
  String search_period_label(String start, String end) => _isEn ? 'Period: $start - $end' : '期間: $start 〜 $end';
  String get search_no_posts => _isEn ? 'No posts found' : '投稿が見つかりませんでした';
  String get search_no_users => _isEn ? 'No users found' : 'ユーザーが見つかりませんでした';
  String get profile_not_found => _isEn ? 'Profile not found' : 'プロフィールが見つかりませんでした';
  String get profile_tab_posts => _isEn ? 'Posts' : '投稿';
  String get profile_tab_replies => _isEn ? 'Replies' : '返信';
  String get profile_tab_media => _isEn ? 'Media' : 'メディア';
  String get profile_tab_video => _isEn ? 'Video' : 'ビデオ';
  String get profile_tab_feeds => _isEn ? 'Feeds' : 'フィード';
  String get profile_no_data => _isEn ? 'No data' : 'データがありません';
  String get profile_unmute => _isEn ? 'Unmute' : 'ミュート解除';
  String get profile_mute => _isEn ? 'Mute' : 'ミュート';
  String get profile_block => _isEn ? 'Block' : 'ブロック';
  String get profile_unblock => _isEn ? 'Unblock' : 'ブロック解除';
  String profile_search_posts_title(String handle) => _isEn ? 'Search posts from @$handle' : '@$handle の投稿を検索';
  String get profile_search_posts_hint => _isEn ? 'Enter keywords' : 'キーワードを入力';
  String profile_url_label(String url) => _isEn ? 'Profile URL: $url' : 'プロフィールURL: $url';
  String get profile_follows => _isEn ? 'Follows' : 'フォロー';
  String get profile_followers => _isEn ? 'Followers' : 'フォロワー';
  String get profile_edit_button => _isEn ? 'Edit Profile' : 'プロフィールを編集';
  String get profile_following_status => _isEn ? 'Following' : 'フォロー中';
  String get profile_no_users => _isEn ? 'No users found' : 'ユーザーがいません';
  String error_with_message(String message) => _isEn ? 'Error: $message' : 'エラー: $message';
  String get cancel => _isEn ? 'Cancel' : 'キャンセル';
  String get search => _isEn ? 'Search' : '検索';
  String get delete => _isEn ? 'Delete' : '削除';
  String get share => _isEn ? 'Share' : '共有';
  String get copyText => _isEn ? 'Copy Text' : 'テキストをコピー';
  String get now => _isEn ? 'now' : '今';
  String get minutes => _isEn ? 'm' : '分';
  String get hours => _isEn ? 'h' : '時間';
  String get user => _isEn ? 'User' : 'ユーザー';
  String get unknown => _isEn ? 'Unknown' : '不明';
  String get others_title => _isEn ? 'Others' : 'その他';
  String get others_account => _isEn ? 'Account' : 'アカウント';
  String get others_switch_account => _isEn ? 'Switch Account' : 'アカウントを切り替える';
  String get others_logout => _isEn ? 'Logout' : 'ログアウト';
  String get others_general => _isEn ? 'General' : '一般';
  String get others_language => _isEn ? 'Language' : '言語';
  String get others_font_size => _isEn ? 'Font' : 'フォント';
  String get others_theme => _isEn ? 'Theme' : 'テーマ';
  String get others_storage => _isEn ? 'Storage' : 'ストレージ';
  String get others_app_settings => _isEn ? 'Features' : '機能';
  String get others_drafts => _isEn ? 'Drafts' : '下書き';
  String get drafts_no_drafts => _isEn ? 'No drafts' : '下書きはありません';
  String drafts_created_at(String date) => _isEn ? 'Created: $date' : '作成: $date';
  String drafts_scheduled_at(String date) => _isEn ? 'Scheduled: $date' : '予約: $date';
  String get post_success => _isEn ? 'Posted successfully' : '投稿しました';
  String get thread_title => _isEn ? 'Thread' : 'スレッド';
  String get thread_not_found => _isEn ? 'Thread not found' : 'スレッドが見つかりませんでした';
  String get thread_parse_error => _isEn ? 'Could not parse thread data' : 'スレッドデータを解析できませんでした';
  String get post_not_viewable => _isEn ? 'This post is not viewable' : 'この投稿は表示できません';
  String get feed_search_title => _isEn ? 'Find Feeds & Lists' : 'フィード・リストを探す';
  String get feed_search_hint => _isEn ? 'Search feeds' : 'フィードを検索';
  String get feed_search_tab_feeds => _isEn ? 'Feeds' : 'フィード';
  String get feed_search_tab_lists => _isEn ? 'My Lists' : 'マイリスト';
  String feed_search_added(String name) => _isEn ? 'Added $name' : '$name を追加しました';
  String get others_advanced_settings => _isEn ? 'Advanced Settings' : '詳細設定';
  String get others_support => _isEn ? 'Support' : 'サポート';
  String get others_help => _isEn ? 'Help' : 'ヘルプ';
  String get others_terms => _isEn ? 'Terms of Service' : '利用規約';
  String get others_privacy => _isEn ? 'Privacy Policy' : 'プライバシーポリシー';
  String get others_version => _isEn ? 'Version' : 'バージョン';
  String get storage_title => _isEn ? 'Storage' : 'ストレージ';
  String get storage_cache_title => _isEn ? 'Cache Data' : 'キャッシュデータ';
  String get storage_cache_desc => _isEn ? 'Delete temporary data to free up space. Posts and images will not be deleted.' : '一時的なデータを削除して空き容量を増やします。投稿や画像は削除されません。';
  String get storage_clear_cache => _isEn ? 'Clear Cache' : 'キャッシュを削除';
  String get storage_clearing => _isEn ? 'Clearing...' : '削除中...';
  String get storage_calculating => _isEn ? 'Calculating...' : '計算中...';
  String get storage_clear_confirm_title => _isEn ? 'Clear Cache?' : 'キャッシュを削除しますか？';
  String get storage_clear_confirm_msg => _isEn ? 'Are you sure you want to delete temporary data?' : '一時的なデータを削除します。よろしいですか？';
  String get storage_clear_success => _isEn ? 'Cache cleared' : 'キャッシュを削除しました';
  String get storage_clear_error => _isEn ? 'Failed to clear cache' : 'キャッシュの削除に失敗しました';
  String get theme_title => _isEn ? 'Theme' : 'テーマ';
  String get theme_system => _isEn ? 'System Default' : 'システム設定に従う';
  String get theme_light => _isEn ? 'Light Mode' : 'ライトモード';
  String get theme_dark => _isEn ? 'Dark Mode' : 'ダークモード';
  String get font_size_title => _isEn ? 'Font' : 'フォント';
  String get font_size_small => _isEn ? 'Small' : '小';
  String get font_size_medium => _isEn ? 'Medium' : '中';
  String get font_size_large => _isEn ? 'Large' : '大';
  String get font_size_extra_large => _isEn ? 'Extra Large' : '特大';
  String get font_size_preview => _isEn ? 'Preview' : 'プレビュー';
  String get font_size_preview_msg => _isEn ? 'This is a font size preview. Move the slider to adjust.' : 'これはフォントサイズのプレビューです。スライダーを動かして調整してください。';
  String get fontFamilyLabel => _isEn ? 'Font Family' : 'フォントファミリー';
  String get language_title => _isEn ? 'Language' : '言語';
  String get language_japanese => _isEn ? 'Japanese' : '日本語';
  String get language_english => _isEn ? 'English' : 'English';
  String get close => _isEn ? 'Close' : '閉じる';
  String get talk_list_title => _isEn ? 'Talks' : 'トーク';
  String get talk_list_fetch_error => _isEn ? 'Failed to fetch feeds' : 'フィードの取得に失敗しました';
  String get post_error => _isEn ? 'Post failed' : '投稿失敗';
  String get following_feed_desc => _isEn ? 'Posts from people you follow' : 'フォロー中の投稿';
  String get profile_handle => _isEn ? 'Handle' : 'ハンドル';
  String get profile_did => _isEn ? 'DID' : 'DID';
  String version_label(String version) => _isEn ? 'Version $version' : 'バージョン $version';
  String get repost_undo => _isEn ? 'Undo Repost' : 'リポストを取り消す';
  String get repost => _isEn ? 'Repost' : 'リポスト';
  String get loading => _isEn ? 'Loading...' : '読み込み中...';
  String get settings_title => _isEn ? 'Advanced Settings' : '詳細設定';
  String get settings_current_remaining => _isEn ? 'Current remaining requests' : '現在の残りリクエスト数';
  String get settings_fetching => _isEn ? 'Fetching...' : '取得中...';
  String get settings_enable_alert => _isEn ? 'Enable rate limit alerts' : 'レート制限アラートを有効にする';
  String get settings_alert_desc => _isEn ? 'Notify in-app when remaining requests are low' : '残りリクエスト数が少なくなったときにアプリ内で通知します';
  String get settings_threshold => _isEn ? 'Remaining requests threshold' : '残りリクエストしきい値';
  String settings_threshold_desc(int threshold) => _isEn ? 'Banner will be shown when below threshold (Current: $threshold)' : 'しきい値以下になるとバナーが表示されます（現在: $threshold）';
  String get settings_usage_approx => _isEn ? 'Current usage (approximate)' : '現在の使用量（近似）';
  String get settings_no_data => _isEn ? 'No data fetched' : 'データ未取得';
  String get settings_no_data_desc => _isEn ? 'API header info not yet fetched. It will be fetched when you perform an action.' : 'APIヘッダ情報がまだ取得されていません。操作を実行すると取得されます。';
  String settings_remaining_label(String remaining) => _isEn ? 'Remaining requests: $remaining' : '残りリクエスト数: $remaining';
  String settings_limit_reset_label(String limit, String reset) => _isEn ? 'Limit: $limit / Reset: $reset' : '上限: $limit / リセット予定: $reset';
  String get settings_note_title => _isEn ? 'Note' : '注意';
  String get settings_note_desc => _isEn ? 'The display is an estimate from the header info returned by the server. The actual remaining amount changes on the server side.' : '表示はサーバーが返すヘッダ情報からの推定値です。実際の残りはサーバー側で変化します。';
  String rate_limit_banner(int remaining, int limit, String reset) => _isEn 
    ? 'API Remaining: $remaining / $limit (Reset: $reset)' 
    : 'API残り: $remaining / $limit (リセット: $reset)';

  // Legacy keys (to avoid breaking existing code during transition)
  String get others_legacy => others_title;
  String get account_legacy => others_account;
  String get profile_legacy => home_my_profile;
  String get switchAccount => others_switch_account;
  String get addAccount => _isEn ? 'Add Account' : '別のアカウントを追加';
  String get logout => others_logout;
  String get general => others_general;
  String get language => others_language;
  String get fontSize => others_font_size;
  String get theme => others_theme;
  String get storage => others_storage;
  String get appSettings => others_app_settings;
  String get drafts => others_drafts;
  String get draftsSubtitle => _isEn ? 'Check your drafts' : '作成済みの下書きを確認';
  String get advancedSettings => others_advanced_settings;
  String get advancedSettingsSubtitle => _isEn ? 'Rate limits, notifications, etc.' : 'レート制限・通知設定など';
  String get support => others_support;
  String get appInfo => _isEn ? 'App Info' : 'アプリ情報';
  String get themeSystem => theme_system;
  String get themeLight => theme_light;
  String get themeDark => theme_dark;
  String get chat_hint => _isEn ? 'Enter message' : 'メッセージを入力';
  String get nav_home => _isEn ? 'Home' : 'ホーム';
  String get nav_talk => _isEn ? 'Talk' : 'トーク';
  String get nav_search => _isEn ? 'Search' : '検索';
  String get nav_notifications => _isEn ? 'Notifications' : '通知';
  String get nav_others => _isEn ? 'Others' : 'その他';
  String get notifications_title => _isEn ? 'Notifications' : '通知';
  String get notifications_empty => _isEn ? 'No notifications' : '通知はありません';
  String get notifications_liked => _isEn ? ' liked your post' : 'があなたの投稿を「いいね」しました';
  String get notifications_reposted => _isEn ? ' reposted your post' : 'があなたの投稿をリポストしました';
  String get notifications_followed => _isEn ? ' followed you' : 'があなたをフォローしました';
  String get notifications_replied => _isEn ? ' replied to you' : 'があなたに返信しました';
  String get notifications_quoted => _isEn ? ' quoted your post' : 'があなたの投稿を引用しました';
  String get notifications_mentioned => _isEn ? ' mentioned you' : 'があなたをメンションしました';
  String get cacheData => storage_cache_title;
  String get cacheDataSubtitle => storage_cache_desc;
  String get clearCache => storage_clear_cache;
  String get clearCacheMessage => storage_clear_success;
  String clearCacheError(String error) => storage_clear_error;
  String get clearCacheConfirmTitle => storage_clear_confirm_title;
  String get clearCacheConfirmMessage => storage_clear_confirm_msg;
  String get cacheDescription => storage_cache_desc;
  String get fontSizePreview => font_size_preview_msg;
  String get fontSizeSmall => font_size_small;
  String get fontSizeLarge => font_size_large;
  String get fontSizeNote => _isEn ? '* May not apply to some screens.' : '※一部の画面では反映されない場合があります。';

  String get parse_error => _isEn ? 'Parse Error' : '解析エラー';
  String login_failed(String error) => _isEn ? 'Login failed: $error' : 'ログイン失敗: $error';
  String api_error(String error) => _isEn ? 'API Error: $error' : 'API エラー: $error';
  String network_error(String error) => _isEn ? 'Network Error: $error' : 'ネットワークエラー: $error';
  String get not_logged_in => _isEn ? 'Not logged in' : 'ログインしていません';
  String auth_error(String error) => _isEn ? 'Auth Error: $error' : '認証エラー: $error';
  String timeline_fetch_failed(String error) => _isEn ? 'Failed to fetch timeline: $error' : 'タイムライン取得失敗: $error';
  String feed_fetch_failed(String error) => _isEn ? 'Failed to fetch feed: $error' : 'フィード取得失敗: $error';
  String get post_content_empty => _isEn ? 'Post content is empty' : '投稿内容が空です';
  String get post_too_long => _isEn ? 'Post must be within 300 characters' : '投稿は300文字以内にしてください';
  String post_failed_with_error(String error) => _isEn ? 'Post failed: $error' : '投稿失敗: $error';
  String get language_not_implemented => _isEn ? 'Language switching not implemented yet' : '言語切り替えはまだ実装されていません';
  // Additional convenience keys to satisfy callers across the codebase
  String get today => _isEn ? 'Today' : '今日';
  String get yesterday => _isEn ? 'Yesterday' : '昨日';
  String reply_to(String user) => _isEn ? 'Reply to $user' : '$user に返信';
  String reposted_by(String user) => _isEn ? 'Reposted by $user' : '$user さんがリポスト';
  String get me => _isEn ? 'Me' : '自分';
  String get unlike => _isEn ? 'Unlike' : 'いいねを取り消す';
  String get like => _isEn ? 'Like' : 'いいね';
  String get unrepost => _isEn ? 'Undo Repost' : 'リポストを取り消す';
  String get quote => _isEn ? 'Quote' : '引用';
  String get reply => _isEn ? 'Reply' : '返信';
  String get delete_local => _isEn ? 'Delete (local)' : 'ローカルで削除';
  String get new_post_max_images => _isEn ? 'Maximum 4 images allowed' : '画像は最大4枚までです';
  String get profile_edit => _isEn ? 'Edit Profile' : 'プロフィールを編集';
  String get profile_unfollow => _isEn ? 'Unfollow' : 'フォローを外す';
  String get profile_follow => _isEn ? 'Follow' : 'フォローする';
  String get no_results => _isEn ? 'No results' : '結果がありません';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ja', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
