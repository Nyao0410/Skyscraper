import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'Skyscraper'**
  String get appTitle;

  /// No description provided for @login_title.
  ///
  /// In ja, this message translates to:
  /// **'Skyscraper'**
  String get login_title;

  /// No description provided for @login_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'トーク形式で楽しむBluesky'**
  String get login_subtitle;

  /// No description provided for @login_info.
  ///
  /// In ja, this message translates to:
  /// **'ログイン方法: Blueskyでアプリパスワードを作成し、ハンドル名（example.bsky.social）と入力してください。'**
  String get login_info;

  /// No description provided for @login_handle_label.
  ///
  /// In ja, this message translates to:
  /// **'HANDLE'**
  String get login_handle_label;

  /// No description provided for @login_handle_hint.
  ///
  /// In ja, this message translates to:
  /// **'example.bsky.social'**
  String get login_handle_hint;

  /// No description provided for @login_password_label.
  ///
  /// In ja, this message translates to:
  /// **'APP PASSWORD'**
  String get login_password_label;

  /// No description provided for @login_password_hint.
  ///
  /// In ja, this message translates to:
  /// **'abcd-1234-efgh-5678'**
  String get login_password_hint;

  /// No description provided for @login_button.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get login_button;

  /// No description provided for @login_loading.
  ///
  /// In ja, this message translates to:
  /// **'ログイン中...'**
  String get login_loading;

  /// No description provided for @login_status_checking.
  ///
  /// In ja, this message translates to:
  /// **'SDK動作確認中...'**
  String get login_status_checking;

  /// No description provided for @login_status_ready.
  ///
  /// In ja, this message translates to:
  /// **'Bluesky SDK準備完了'**
  String get login_status_ready;

  /// No description provided for @home_welcome.
  ///
  /// In ja, this message translates to:
  /// **'Blueskyへようこそ'**
  String get home_welcome;

  /// No description provided for @home_post_button.
  ///
  /// In ja, this message translates to:
  /// **'投稿する'**
  String get home_post_button;

  /// No description provided for @home_menu_title.
  ///
  /// In ja, this message translates to:
  /// **'メニュー'**
  String get home_menu_title;

  /// No description provided for @home_timeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムライン'**
  String get home_timeline;

  /// No description provided for @home_my_profile.
  ///
  /// In ja, this message translates to:
  /// **'自分のプロフィール'**
  String get home_my_profile;

  /// No description provided for @home_saved_feeds.
  ///
  /// In ja, this message translates to:
  /// **'保存済みフィード'**
  String get home_saved_feeds;

  /// No description provided for @home_unknown_feed.
  ///
  /// In ja, this message translates to:
  /// **'不明なフィード'**
  String get home_unknown_feed;

  /// No description provided for @home_talk.
  ///
  /// In ja, this message translates to:
  /// **'トーク'**
  String get home_talk;

  /// No description provided for @post_new_title.
  ///
  /// In ja, this message translates to:
  /// **'新規投稿'**
  String get post_new_title;

  /// No description provided for @post_edit_draft_title.
  ///
  /// In ja, this message translates to:
  /// **'下書き編集'**
  String get post_edit_draft_title;

  /// No description provided for @post_reply_title.
  ///
  /// In ja, this message translates to:
  /// **'返信'**
  String get post_reply_title;

  /// No description provided for @post_quote_title.
  ///
  /// In ja, this message translates to:
  /// **'引用'**
  String get post_quote_title;

  /// No description provided for @post_image_limit.
  ///
  /// In ja, this message translates to:
  /// **'画像は最大4枚までです'**
  String get post_image_limit;

  /// No description provided for @post_reply_schedule_not_supported.
  ///
  /// In ja, this message translates to:
  /// **'返信の予約投稿は現在サポートされていません'**
  String get post_reply_schedule_not_supported;

  /// No description provided for @post_draft_saved.
  ///
  /// In ja, this message translates to:
  /// **'下書きを保存しました'**
  String get post_draft_saved;

  /// No description provided for @post_scheduled_success.
  ///
  /// In ja, this message translates to:
  /// **'投稿を予約しました（画像は現在サポートされていません）'**
  String get post_scheduled_success;

  /// No description provided for @post_reply_success.
  ///
  /// In ja, this message translates to:
  /// **'返信しました'**
  String get post_reply_success;

  /// No description provided for @post_quote_success.
  ///
  /// In ja, this message translates to:
  /// **'引用投稿しました'**
  String get post_quote_success;

  /// No description provided for @post_success.
  ///
  /// In ja, this message translates to:
  /// **'投稿しました'**
  String get post_success;

  /// No description provided for @post_draft_button.
  ///
  /// In ja, this message translates to:
  /// **'下書き'**
  String get post_draft_button;

  /// No description provided for @post_save_draft_button.
  ///
  /// In ja, this message translates to:
  /// **'下書き保存'**
  String get post_save_draft_button;

  /// No description provided for @post_schedule_button.
  ///
  /// In ja, this message translates to:
  /// **'予約'**
  String get post_schedule_button;

  /// No description provided for @post_button.
  ///
  /// In ja, this message translates to:
  /// **'投稿'**
  String get post_button;

  /// No description provided for @post_hint_reply.
  ///
  /// In ja, this message translates to:
  /// **'返信を入力...'**
  String get post_hint_reply;

  /// No description provided for @post_hint_default.
  ///
  /// In ja, this message translates to:
  /// **'いまどうしてる？'**
  String get post_hint_default;

  /// No description provided for @timeline_title.
  ///
  /// In ja, this message translates to:
  /// **'タイムライン'**
  String get timeline_title;

  /// No description provided for @timeline_no_posts.
  ///
  /// In ja, this message translates to:
  /// **'投稿がありません'**
  String get timeline_no_posts;

  /// No description provided for @timeline_reposted_by.
  ///
  /// In ja, this message translates to:
  /// **'{user} さんがリポスト'**
  String timeline_reposted_by(String user);

  /// No description provided for @timeline_quote_post.
  ///
  /// In ja, this message translates to:
  /// **'引用して投稿'**
  String get timeline_quote_post;

  /// No description provided for @search_hint.
  ///
  /// In ja, this message translates to:
  /// **'検索ワード、#タグ、@ユーザー...'**
  String get search_hint;

  /// No description provided for @search_clear_filter.
  ///
  /// In ja, this message translates to:
  /// **'フィルターをクリア'**
  String get search_clear_filter;

  /// No description provided for @search_specify_period.
  ///
  /// In ja, this message translates to:
  /// **'期間指定'**
  String get search_specify_period;

  /// No description provided for @search_tab_posts.
  ///
  /// In ja, this message translates to:
  /// **'投稿'**
  String get search_tab_posts;

  /// No description provided for @search_tab_users.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get search_tab_users;

  /// No description provided for @search_period_label.
  ///
  /// In ja, this message translates to:
  /// **'期間: {start} 〜 {end}'**
  String search_period_label(String start, String end);

  /// No description provided for @search_no_posts.
  ///
  /// In ja, this message translates to:
  /// **'投稿が見つかりませんでした'**
  String get search_no_posts;

  /// No description provided for @search_no_users.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりませんでした'**
  String get search_no_users;

  /// No description provided for @profile_not_found.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールが見つかりませんでした'**
  String get profile_not_found;

  /// No description provided for @profile_tab_posts.
  ///
  /// In ja, this message translates to:
  /// **'投稿'**
  String get profile_tab_posts;

  /// No description provided for @profile_tab_replies.
  ///
  /// In ja, this message translates to:
  /// **'返信'**
  String get profile_tab_replies;

  /// No description provided for @profile_tab_media.
  ///
  /// In ja, this message translates to:
  /// **'メディア'**
  String get profile_tab_media;

  /// No description provided for @profile_tab_video.
  ///
  /// In ja, this message translates to:
  /// **'ビデオ'**
  String get profile_tab_video;

  /// No description provided for @profile_tab_feeds.
  ///
  /// In ja, this message translates to:
  /// **'フィード'**
  String get profile_tab_feeds;

  /// No description provided for @profile_no_data.
  ///
  /// In ja, this message translates to:
  /// **'データがありません'**
  String get profile_no_data;

  /// No description provided for @profile_unmute.
  ///
  /// In ja, this message translates to:
  /// **'ミュート解除'**
  String get profile_unmute;

  /// No description provided for @profile_mute.
  ///
  /// In ja, this message translates to:
  /// **'ミュート'**
  String get profile_mute;

  /// No description provided for @profile_block.
  ///
  /// In ja, this message translates to:
  /// **'ブロック'**
  String get profile_block;

  /// No description provided for @profile_unblock.
  ///
  /// In ja, this message translates to:
  /// **'ブロック解除'**
  String get profile_unblock;

  /// No description provided for @profile_search_posts_title.
  ///
  /// In ja, this message translates to:
  /// **'@{handle} の投稿を検索'**
  String profile_search_posts_title(String handle);

  /// No description provided for @profile_search_posts_hint.
  ///
  /// In ja, this message translates to:
  /// **'キーワードを入力'**
  String get profile_search_posts_hint;

  /// No description provided for @profile_url_label.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールURL: {url}'**
  String profile_url_label(String url);

  /// No description provided for @profile_follows.
  ///
  /// In ja, this message translates to:
  /// **'フォロー'**
  String get profile_follows;

  /// No description provided for @profile_followers.
  ///
  /// In ja, this message translates to:
  /// **'フォロワー'**
  String get profile_followers;

  /// No description provided for @profile_edit_button.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを編集'**
  String get profile_edit_button;

  /// No description provided for @profile_following_status.
  ///
  /// In ja, this message translates to:
  /// **'フォロー中'**
  String get profile_following_status;

  /// No description provided for @profile_no_users.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーがいません'**
  String get profile_no_users;

  /// No description provided for @error_with_message.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {message}'**
  String error_with_message(String message);

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @search.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get search;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @share.
  ///
  /// In ja, this message translates to:
  /// **'共有'**
  String get share;

  /// No description provided for @copyText.
  ///
  /// In ja, this message translates to:
  /// **'テキストをコピー'**
  String get copyText;

  /// No description provided for @now.
  ///
  /// In ja, this message translates to:
  /// **'今'**
  String get now;

  /// No description provided for @minutes.
  ///
  /// In ja, this message translates to:
  /// **'分'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In ja, this message translates to:
  /// **'時間'**
  String get hours;

  /// No description provided for @user.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get user;

  /// No description provided for @unknown.
  ///
  /// In ja, this message translates to:
  /// **'不明'**
  String get unknown;

  /// No description provided for @others_title.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get others_title;

  /// No description provided for @others_account.
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get others_account;

  /// No description provided for @others_switch_account.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを切り替える'**
  String get others_switch_account;

  /// No description provided for @others_logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get others_logout;

  /// No description provided for @others_general.
  ///
  /// In ja, this message translates to:
  /// **'一般'**
  String get others_general;

  /// No description provided for @others_language.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get others_language;

  /// No description provided for @others_font_size.
  ///
  /// In ja, this message translates to:
  /// **'フォントサイズ'**
  String get others_font_size;

  /// No description provided for @others_theme.
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get others_theme;

  /// No description provided for @others_storage.
  ///
  /// In ja, this message translates to:
  /// **'ストレージ'**
  String get others_storage;

  /// No description provided for @others_app_settings.
  ///
  /// In ja, this message translates to:
  /// **'機能'**
  String get others_app_settings;

  /// No description provided for @others_drafts.
  ///
  /// In ja, this message translates to:
  /// **'下書き'**
  String get others_drafts;

  /// No description provided for @drafts_no_drafts.
  ///
  /// In ja, this message translates to:
  /// **'下書きはありません'**
  String get drafts_no_drafts;

  /// No description provided for @drafts_created_at.
  ///
  /// In ja, this message translates to:
  /// **'作成: {date}'**
  String drafts_created_at(String date);

  /// No description provided for @drafts_scheduled_at.
  ///
  /// In ja, this message translates to:
  /// **'予約: {date}'**
  String drafts_scheduled_at(String date);

  /// No description provided for @thread_title.
  ///
  /// In ja, this message translates to:
  /// **'スレッド'**
  String get thread_title;

  /// No description provided for @thread_not_found.
  ///
  /// In ja, this message translates to:
  /// **'スレッドが見つかりませんでした'**
  String get thread_not_found;

  /// No description provided for @thread_parse_error.
  ///
  /// In ja, this message translates to:
  /// **'スレッドデータを解析できませんでした'**
  String get thread_parse_error;

  /// No description provided for @post_not_viewable.
  ///
  /// In ja, this message translates to:
  /// **'この投稿は表示できません'**
  String get post_not_viewable;

  /// No description provided for @feed_search_title.
  ///
  /// In ja, this message translates to:
  /// **'フィード・リストを探す'**
  String get feed_search_title;

  /// No description provided for @feed_search_hint.
  ///
  /// In ja, this message translates to:
  /// **'フィードを検索'**
  String get feed_search_hint;

  /// No description provided for @feed_search_tab_feeds.
  ///
  /// In ja, this message translates to:
  /// **'フィード'**
  String get feed_search_tab_feeds;

  /// No description provided for @feed_search_tab_lists.
  ///
  /// In ja, this message translates to:
  /// **'マイリスト'**
  String get feed_search_tab_lists;

  /// No description provided for @feed_search_added.
  ///
  /// In ja, this message translates to:
  /// **'{name} を追加しました'**
  String feed_search_added(String name);

  /// No description provided for @others_advanced_settings.
  ///
  /// In ja, this message translates to:
  /// **'詳細設定'**
  String get others_advanced_settings;

  /// No description provided for @others_support.
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get others_support;

  /// No description provided for @others_help.
  ///
  /// In ja, this message translates to:
  /// **'ヘルプ'**
  String get others_help;

  /// No description provided for @others_terms.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get others_terms;

  /// No description provided for @others_privacy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get others_privacy;

  /// No description provided for @others_version.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get others_version;

  /// No description provided for @storage_title.
  ///
  /// In ja, this message translates to:
  /// **'ストレージ'**
  String get storage_title;

  /// No description provided for @storage_cache_title.
  ///
  /// In ja, this message translates to:
  /// **'キャッシュデータ'**
  String get storage_cache_title;

  /// No description provided for @storage_cache_desc.
  ///
  /// In ja, this message translates to:
  /// **'一時的なデータを削除して空き容量を増やします。投稿や画像は削除されません。'**
  String get storage_cache_desc;

  /// No description provided for @storage_clear_cache.
  ///
  /// In ja, this message translates to:
  /// **'キャッシュを削除'**
  String get storage_clear_cache;

  /// No description provided for @storage_clearing.
  ///
  /// In ja, this message translates to:
  /// **'削除中...'**
  String get storage_clearing;

  /// No description provided for @storage_calculating.
  ///
  /// In ja, this message translates to:
  /// **'計算中...'**
  String get storage_calculating;

  /// No description provided for @storage_clear_confirm_title.
  ///
  /// In ja, this message translates to:
  /// **'キャッシュを削除しますか？'**
  String get storage_clear_confirm_title;

  /// No description provided for @storage_clear_confirm_msg.
  ///
  /// In ja, this message translates to:
  /// **'一時的なデータを削除します。よろしいですか？'**
  String get storage_clear_confirm_msg;

  /// No description provided for @storage_clear_success.
  ///
  /// In ja, this message translates to:
  /// **'キャッシュを削除しました'**
  String get storage_clear_success;

  /// No description provided for @storage_clear_error.
  ///
  /// In ja, this message translates to:
  /// **'キャッシュの削除に失敗しました'**
  String get storage_clear_error;

  /// No description provided for @theme_title.
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get theme_title;

  /// No description provided for @theme_system.
  ///
  /// In ja, this message translates to:
  /// **'システム設定に従う'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In ja, this message translates to:
  /// **'ライトモード'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In ja, this message translates to:
  /// **'ダークモード'**
  String get theme_dark;

  /// No description provided for @chat_hint.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを入力'**
  String get chat_hint;

  /// No description provided for @nav_home.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get nav_home;

  /// No description provided for @nav_talk.
  ///
  /// In ja, this message translates to:
  /// **'トーク'**
  String get nav_talk;

  /// No description provided for @nav_search.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get nav_search;

  /// No description provided for @nav_notifications.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get nav_notifications;

  /// No description provided for @nav_others.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get nav_others;

  /// No description provided for @notifications_title.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get notifications_title;

  /// No description provided for @notifications_empty.
  ///
  /// In ja, this message translates to:
  /// **'通知はありません'**
  String get notifications_empty;

  /// No description provided for @notifications_liked.
  ///
  /// In ja, this message translates to:
  /// **'があなたの投稿を「いいね」しました'**
  String get notifications_liked;

  /// No description provided for @notifications_reposted.
  ///
  /// In ja, this message translates to:
  /// **'があなたの投稿をリポストしました'**
  String get notifications_reposted;

  /// No description provided for @notifications_followed.
  ///
  /// In ja, this message translates to:
  /// **'があなたをフォローしました'**
  String get notifications_followed;

  /// No description provided for @notifications_replied.
  ///
  /// In ja, this message translates to:
  /// **'があなたに返信しました'**
  String get notifications_replied;

  /// No description provided for @notifications_quoted.
  ///
  /// In ja, this message translates to:
  /// **'があなたの投稿を引用しました'**
  String get notifications_quoted;

  /// No description provided for @notifications_mentioned.
  ///
  /// In ja, this message translates to:
  /// **'があなたをメンションしました'**
  String get notifications_mentioned;

  /// No description provided for @font_size_title.
  ///
  /// In ja, this message translates to:
  /// **'フォントサイズ'**
  String get font_size_title;

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @rate_limit_banner.
  ///
  /// In ja, this message translates to:
  /// **'API残り: {remaining} / {limit} (リセット: {reset})'**
  String rate_limit_banner(int remaining, int limit, String reset);

  /// No description provided for @font_size_small.
  ///
  /// In ja, this message translates to:
  /// **'小'**
  String get font_size_small;

  /// No description provided for @font_size_medium.
  ///
  /// In ja, this message translates to:
  /// **'中'**
  String get font_size_medium;

  /// No description provided for @font_size_large.
  ///
  /// In ja, this message translates to:
  /// **'大'**
  String get font_size_large;

  /// No description provided for @font_size_extra_large.
  ///
  /// In ja, this message translates to:
  /// **'特大'**
  String get font_size_extra_large;

  /// No description provided for @font_size_preview.
  ///
  /// In ja, this message translates to:
  /// **'プレビュー'**
  String get font_size_preview;

  /// No description provided for @font_size_preview_msg.
  ///
  /// In ja, this message translates to:
  /// **'これはフォントサイズのプレビューです。スライダーを動かして調整してください。'**
  String get font_size_preview_msg;

  /// No description provided for @language_title.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language_title;

  /// No description provided for @language_japanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get language_japanese;

  /// No description provided for @language_english.
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @talk_list_title.
  ///
  /// In ja, this message translates to:
  /// **'トーク'**
  String get talk_list_title;

  /// No description provided for @talk_list_fetch_error.
  ///
  /// In ja, this message translates to:
  /// **'フィードの取得に失敗しました'**
  String get talk_list_fetch_error;

  /// No description provided for @post_error.
  ///
  /// In ja, this message translates to:
  /// **'投稿失敗'**
  String get post_error;

  /// No description provided for @following_feed_desc.
  ///
  /// In ja, this message translates to:
  /// **'フォロー中の投稿'**
  String get following_feed_desc;

  /// No description provided for @profile_handle.
  ///
  /// In ja, this message translates to:
  /// **'ハンドル'**
  String get profile_handle;

  /// No description provided for @profile_did.
  ///
  /// In ja, this message translates to:
  /// **'DID'**
  String get profile_did;

  /// No description provided for @version_label.
  ///
  /// In ja, this message translates to:
  /// **'バージョン {version}'**
  String version_label(String version);

  /// No description provided for @repost_undo.
  ///
  /// In ja, this message translates to:
  /// **'リポストを取り消す'**
  String get repost_undo;

  /// No description provided for @repost.
  ///
  /// In ja, this message translates to:
  /// **'リポスト'**
  String get repost;

  /// No description provided for @loading.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get loading;

  /// No description provided for @settings_title.
  ///
  /// In ja, this message translates to:
  /// **'詳細設定'**
  String get settings_title;

  /// No description provided for @settings_current_remaining.
  ///
  /// In ja, this message translates to:
  /// **'現在の残りリクエスト数'**
  String get settings_current_remaining;

  /// No description provided for @settings_fetching.
  ///
  /// In ja, this message translates to:
  /// **'取得中...'**
  String get settings_fetching;

  /// No description provided for @settings_enable_alert.
  ///
  /// In ja, this message translates to:
  /// **'レート制限アラートを有効にする'**
  String get settings_enable_alert;

  /// No description provided for @settings_alert_desc.
  ///
  /// In ja, this message translates to:
  /// **'残りリクエスト数が少なくなったときにアプリ内で通知します'**
  String get settings_alert_desc;

  /// No description provided for @settings_threshold.
  ///
  /// In ja, this message translates to:
  /// **'残りリクエストしきい値'**
  String get settings_threshold;

  /// No description provided for @settings_threshold_desc.
  ///
  /// In ja, this message translates to:
  /// **'しきい値以下になるとバナーが表示されます（現在: {threshold}）'**
  String settings_threshold_desc(int threshold);

  /// No description provided for @settings_usage_approx.
  ///
  /// In ja, this message translates to:
  /// **'現在の使用量（近似）'**
  String get settings_usage_approx;

  /// No description provided for @settings_no_data.
  ///
  /// In ja, this message translates to:
  /// **'データ未取得'**
  String get settings_no_data;

  /// No description provided for @settings_no_data_desc.
  ///
  /// In ja, this message translates to:
  /// **'APIヘッダ情報がまだ取得されていません。操作を実行すると取得されます。'**
  String get settings_no_data_desc;

  /// No description provided for @settings_remaining_label.
  ///
  /// In ja, this message translates to:
  /// **'残りリクエスト数: {remaining}'**
  String settings_remaining_label(String remaining);

  /// No description provided for @settings_limit_reset_label.
  ///
  /// In ja, this message translates to:
  /// **'上限: {limit} / リセット予定: {reset}'**
  String settings_limit_reset_label(String limit, String reset);

  /// No description provided for @settings_note_title.
  ///
  /// In ja, this message translates to:
  /// **'注意'**
  String get settings_note_title;

  /// No description provided for @settings_note_desc.
  ///
  /// In ja, this message translates to:
  /// **'表示はサーバーが返すヘッダ情報からの推定値です。実際の残りはサーバー側で変化します。'**
  String get settings_note_desc;

  /// No description provided for @parse_error.
  ///
  /// In ja, this message translates to:
  /// **'解析エラー'**
  String get parse_error;

  /// No description provided for @login_failed.
  ///
  /// In ja, this message translates to:
  /// **'ログイン失敗: {error}'**
  String login_failed(String error);

  /// No description provided for @api_error.
  ///
  /// In ja, this message translates to:
  /// **'API エラー: {error}'**
  String api_error(String error);

  /// No description provided for @network_error.
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラー: {error}'**
  String network_error(String error);

  /// No description provided for @not_logged_in.
  ///
  /// In ja, this message translates to:
  /// **'ログインしていません'**
  String get not_logged_in;

  /// No description provided for @auth_error.
  ///
  /// In ja, this message translates to:
  /// **'認証エラー: {error}'**
  String auth_error(String error);

  /// No description provided for @timeline_fetch_failed.
  ///
  /// In ja, this message translates to:
  /// **'タイムライン取得失敗: {error}'**
  String timeline_fetch_failed(String error);

  /// No description provided for @feed_fetch_failed.
  ///
  /// In ja, this message translates to:
  /// **'フィード取得失敗: {error}'**
  String feed_fetch_failed(String error);

  /// No description provided for @post_content_empty.
  ///
  /// In ja, this message translates to:
  /// **'投稿内容が空です'**
  String get post_content_empty;

  /// No description provided for @post_too_long.
  ///
  /// In ja, this message translates to:
  /// **'投稿は300文字以内にしてください'**
  String get post_too_long;

  /// No description provided for @post_failed.
  ///
  /// In ja, this message translates to:
  /// **'投稿失敗: {error}'**
  String post_failed(String error);

  /// No description provided for @language_not_implemented.
  ///
  /// In ja, this message translates to:
  /// **'言語切り替えはまだ実装されていません'**
  String get language_not_implemented;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
