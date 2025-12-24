// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Skyscraper';

  @override
  String get login_title => 'Skyscraper';

  @override
  String get login_subtitle => 'Enjoy Bluesky in Talk Format';

  @override
  String get login_info =>
      'How to login: Create an App Password on Bluesky and enter your handle (example.bsky.social).';

  @override
  String get login_handle_label => 'HANDLE';

  @override
  String get login_handle_hint => 'example.bsky.social';

  @override
  String get login_password_label => 'APP PASSWORD';

  @override
  String get login_password_hint => 'abcd-1234-efgh-5678';

  @override
  String get login_button => 'Login';

  @override
  String get login_loading => 'Logging in...';

  @override
  String get login_status_checking => 'Checking SDK...';

  @override
  String get login_status_ready => 'Bluesky SDK Ready';

  @override
  String get home_welcome => 'Welcome to Bluesky';

  @override
  String get home_post_button => 'Post';

  @override
  String get home_menu_title => 'Menu';

  @override
  String get home_timeline => 'Timeline';

  @override
  String get home_my_profile => 'My Profile';

  @override
  String get home_saved_feeds => 'Saved Feeds';

  @override
  String get home_unknown_feed => 'Unknown Feed';

  @override
  String get home_talk => 'Talk';

  @override
  String get post_new_title => 'New Post';

  @override
  String get post_edit_draft_title => 'Edit Draft';

  @override
  String get post_reply_title => 'Reply';

  @override
  String get post_quote_title => 'Quote';

  @override
  String get post_image_limit => 'Maximum 4 images allowed';

  @override
  String get post_reply_schedule_not_supported =>
      'Scheduled replies are not supported yet';

  @override
  String get post_draft_saved => 'Draft saved';

  @override
  String get post_scheduled_success =>
      'Post scheduled (Images not supported for scheduled posts yet)';

  @override
  String get post_reply_success => 'Replied';

  @override
  String get post_quote_success => 'Quoted';

  @override
  String get post_success => 'Posted successfully';

  @override
  String get post_draft_button => 'Draft';

  @override
  String get post_save_draft_button => 'Save Draft';

  @override
  String get post_schedule_button => 'Schedule';

  @override
  String get post_button => 'Post';

  @override
  String get post_hint_reply => 'Write a reply...';

  @override
  String get post_hint_default => 'What\'s happening?';

  @override
  String get timeline_title => 'Timeline';

  @override
  String get timeline_no_posts => 'No posts found';

  @override
  String timeline_reposted_by(String user) {
    return 'Reposted by $user';
  }

  @override
  String get timeline_quote_post => 'Quote Post';

  @override
  String get search_hint => 'Search words, #tags, @users...';

  @override
  String get search_clear_filter => 'Clear Filter';

  @override
  String get search_specify_period => 'Specify Period';

  @override
  String get search_tab_posts => 'Posts';

  @override
  String get search_tab_users => 'Users';

  @override
  String search_period_label(String start, String end) {
    return 'Period: $start - $end';
  }

  @override
  String get search_no_posts => 'No posts found';

  @override
  String get search_no_users => 'No users found';

  @override
  String get profile_not_found => 'Profile not found';

  @override
  String get profile_tab_posts => 'Posts';

  @override
  String get profile_tab_replies => 'Replies';

  @override
  String get profile_tab_media => 'Media';

  @override
  String get profile_tab_video => 'Video';

  @override
  String get profile_tab_feeds => 'Feeds';

  @override
  String get profile_no_data => 'No data';

  @override
  String get profile_unmute => 'Unmute';

  @override
  String get profile_mute => 'Mute';

  @override
  String get profile_block => 'Block';

  @override
  String get profile_unblock => 'Unblock';

  @override
  String profile_search_posts_title(String handle) {
    return 'Search posts from @$handle';
  }

  @override
  String get profile_search_posts_hint => 'Enter keywords';

  @override
  String profile_url_label(String url) {
    return 'Profile URL: $url';
  }

  @override
  String get profile_follows => 'Follows';

  @override
  String get profile_followers => 'Followers';

  @override
  String get profile_edit_button => 'Edit Profile';

  @override
  String get profile_following_status => 'Following';

  @override
  String get profile_edit_title => 'Edit Profile';

  @override
  String get profile_display_name => 'Display Name';

  @override
  String get profile_description => 'Description';

  @override
  String get save => 'Save';

  @override
  String get profile_no_users => 'No users found';

  @override
  String error_with_message(String message) {
    return 'Error: $message';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get search => 'Search';

  @override
  String get delete => 'Delete';

  @override
  String get share => 'Share';

  @override
  String get copyText => 'Copy Text';

  @override
  String get now => 'now';

  @override
  String get minutes => 'm';

  @override
  String get hours => 'h';

  @override
  String get user => 'User';

  @override
  String get unknown => 'Unknown';

  @override
  String get others_title => 'Others';

  @override
  String get others_account => 'Account';

  @override
  String get others_switch_account => 'Switch Account';

  @override
  String get others_logout => 'Logout';

  @override
  String get others_general => 'General';

  @override
  String get others_language => 'Language';

  @override
  String get others_font_size => 'Font Size';

  @override
  String get others_theme => 'Theme';

  @override
  String get others_storage => 'Storage';

  @override
  String get others_app_settings => 'Features';

  @override
  String get others_drafts => 'Drafts';

  @override
  String get drafts_no_drafts => 'No drafts';

  @override
  String drafts_created_at(String date) {
    return 'Created: $date';
  }

  @override
  String drafts_scheduled_at(String date) {
    return 'Scheduled: $date';
  }

  @override
  String get thread_title => 'Thread';

  @override
  String get thread_not_found => 'Thread not found';

  @override
  String get thread_parse_error => 'Could not parse thread data';

  @override
  String get post_not_viewable => 'This post is not viewable';

  @override
  String get feed_search_title => 'Find Feeds & Lists';

  @override
  String get feed_search_hint => 'Search feeds';

  @override
  String get feed_search_tab_feeds => 'Feeds';

  @override
  String get feed_search_tab_lists => 'My Lists';

  @override
  String feed_search_added(String name) {
    return 'Added $name';
  }

  @override
  String get others_advanced_settings => 'Advanced Settings';

  @override
  String get others_support => 'Support';

  @override
  String get others_help => 'Help';

  @override
  String get others_terms => 'Terms of Service';

  @override
  String get others_privacy => 'Privacy Policy';

  @override
  String get others_version => 'Version';

  @override
  String get storage_title => 'Storage';

  @override
  String get storage_cache_title => 'Cache Data';

  @override
  String get storage_cache_desc =>
      'Delete temporary data to free up space. Posts and images will not be deleted.';

  @override
  String get storage_clear_cache => 'Clear Cache';

  @override
  String get storage_clearing => 'Clearing...';

  @override
  String get storage_calculating => 'Calculating...';

  @override
  String get storage_clear_confirm_title => 'Clear Cache?';

  @override
  String get storage_clear_confirm_msg =>
      'Are you sure you want to delete temporary data?';

  @override
  String get storage_clear_success => 'Cache cleared';

  @override
  String get storage_clear_error => 'Failed to clear cache';

  @override
  String get theme_title => 'Theme';

  @override
  String get theme_system => 'System Default';

  @override
  String get theme_light => 'Light Mode';

  @override
  String get theme_dark => 'Dark Mode';

  @override
  String get chat_hint => 'Enter message';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_talk => 'Talk';

  @override
  String get nav_search => 'Search';

  @override
  String get nav_notifications => 'Notifications';

  @override
  String get nav_others => 'Others';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_empty => 'No notifications';

  @override
  String get notifications_liked => ' liked your post';

  @override
  String get notifications_reposted => ' reposted your post';

  @override
  String get notifications_followed => ' followed you';

  @override
  String get notifications_replied => ' replied to you';

  @override
  String get notifications_quoted => ' quoted your post';

  @override
  String get notifications_mentioned => ' mentioned you';

  @override
  String get font_size_title => 'Font Size';

  @override
  String get close => 'Close';

  @override
  String rate_limit_banner(int remaining, int limit, String reset) {
    return 'API Remaining: $remaining / $limit (Reset: $reset)';
  }

  @override
  String get font_size_small => 'Small';

  @override
  String get font_size_medium => 'Medium';

  @override
  String get font_size_large => 'Large';

  @override
  String get font_size_extra_large => 'Extra Large';

  @override
  String get font_size_preview => 'Preview';

  @override
  String get font_size_preview_msg =>
      'This is a font size preview. Move the slider to adjust.';

  @override
  String get language_title => 'Language';

  @override
  String get language_japanese => 'Japanese';

  @override
  String get language_english => 'English';

  @override
  String get talk_list_title => 'Talks';

  @override
  String get talk_list_fetch_error => 'Failed to fetch feeds';

  @override
  String get post_error => 'Post failed';

  @override
  String get following_feed_desc => 'Posts from people you follow';

  @override
  String get profile_handle => 'Handle';

  @override
  String get profile_did => 'DID';

  @override
  String version_label(String version) {
    return 'Version $version';
  }

  @override
  String get repost_undo => 'Undo Repost';

  @override
  String get repost => 'Repost';

  @override
  String get loading => 'Loading...';

  @override
  String get settings_title => 'Advanced Settings';

  @override
  String get settings_current_remaining => 'Current remaining requests';

  @override
  String get settings_fetching => 'Fetching...';

  @override
  String get settings_enable_alert => 'Enable rate limit alerts';

  @override
  String get settings_alert_desc =>
      'Notify in-app when remaining requests are low';

  @override
  String get settings_threshold => 'Remaining requests threshold';

  @override
  String settings_threshold_desc(int threshold) {
    return 'Banner will be shown when below threshold (Current: $threshold)';
  }

  @override
  String get settings_usage_approx => 'Current usage (approximate)';

  @override
  String get settings_no_data => 'No data fetched';

  @override
  String get settings_no_data_desc =>
      'API header info not yet fetched. It will be fetched when you perform an action.';

  @override
  String settings_remaining_label(String remaining) {
    return 'Remaining requests: $remaining';
  }

  @override
  String settings_limit_reset_label(String limit, String reset) {
    return 'Limit: $limit / Reset: $reset';
  }

  @override
  String get settings_note_title => 'Note';

  @override
  String get settings_note_desc =>
      'The display is an estimate from the header info returned by the server. The actual remaining amount changes on the server side.';

  @override
  String get parse_error => 'Parse Error';

  @override
  String login_failed(String error) {
    return 'Login failed: $error';
  }

  @override
  String api_error(String error) {
    return 'API Error: $error';
  }

  @override
  String network_error(String error) {
    return 'Network Error: $error';
  }

  @override
  String get not_logged_in => 'Not logged in';

  @override
  String auth_error(String error) {
    return 'Auth Error: $error';
  }

  @override
  String timeline_fetch_failed(String error) {
    return 'Failed to fetch timeline: $error';
  }

  @override
  String feed_fetch_failed(String error) {
    return 'Failed to fetch feed: $error';
  }

  @override
  String get post_content_empty => 'Post content is empty';

  @override
  String get post_too_long => 'Post must be within 300 characters';

  @override
  String post_failed(String error) {
    return 'Post failed: $error';
  }

  @override
  String get language_not_implemented =>
      'Language switching not implemented yet';
}
