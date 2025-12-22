// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'flutter_gen/gen_l10n/app_localizations.dart';
import 'services/locale_controller.dart';
import 'services/font_controller.dart';
import 'services/theme_controller.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'widgets/rate_limit_notifier.dart';
import 'services/bluesky_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize saved locale before setting Intl.defaultLocale so
  // date/time formatting uses the user's preferred language.
  await LocaleController.init();
  await FontController.init();
  await ThemeController.init();
  final savedLocale = LocaleController.locale.value;
  String intlLocaleTag;
  if (savedLocale == null) {
    intlLocaleTag = 'ja_JP';
  } else if (savedLocale.languageCode == 'ja') {
    intlLocaleTag = 'ja_JP';
  } else if (savedLocale.languageCode == 'en') {
    intlLocaleTag = 'en_US';
  } else {
    intlLocaleTag = '${savedLocale.languageCode}_${savedLocale.countryCode ?? ''}'.replaceAll('__', '_');
  }
  Intl.defaultLocale = intlLocaleTag;
  await initializeDateFormatting(intlLocaleTag, null);

  await BackgroundService().init();
  
  runApp(const BskyApp());
}

class BskyApp extends StatefulWidget {
  const BskyApp({super.key});

  @override
  State<BskyApp> createState() => _BskyAppState();
}

class _BskyAppState extends State<BskyApp> {
  @override
  void initState() {
    super.initState();
    LocaleController.locale.addListener(_onLocaleChanged);
    FontController.fontScale.addListener(_onFontChanged);
    FontController.fontFamily.addListener(_onFontChanged);
    ThemeController.mode.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    LocaleController.locale.removeListener(_onLocaleChanged);
    FontController.fontScale.removeListener(_onFontChanged);
    FontController.fontFamily.removeListener(_onFontChanged);
    ThemeController.mode.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});
  void _onFontChanged() => setState(() {});
  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final currentLocale = LocaleController.locale.value;
    final currentScale = FontController.fontScale.value;
    final currentFontFamily = FontController.fontFamily.value;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skyscraper',
      locale: currentLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ja'), // Japanese
        const Locale('en'), // English
      ],
      // Build base themes and apply text theme scaling based on currentScale
      theme: _buildScaledLightTheme(currentScale, currentFontFamily),
      darkTheme: _buildScaledDarkTheme(currentScale, currentFontFamily),
      themeMode: ThemeController.mode.value,
      builder: (context, child) {
        // Wrap the app content so we can show MaterialBanners from a central place
        final wrapped = RateLimitNotifier(child: child ?? const SizedBox.shrink());
        return wrapped;
      },
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginWrapper(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

ThemeData _buildScaledLightTheme(double scale, String fontFamily) {
  final base = ThemeData(
    useMaterial3: true,
    // We will apply Google Fonts to the textTheme below for reliable rendering.
    fontFamily: fontFamily == 'system' ? null : (fontFamily.startsWith('Noto') ? null : fontFamily),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00C300),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    textTheme: _baseTextTheme(),
  );
  // Apply selected font family via GoogleFonts when possible by wrapping
  // each TextStyle. Some google_fonts helper methods for TextTheme may
  // not be available on all package versions, so apply per-style to be
  // robust.
  TextStyle? applyFamily(TextStyle? s) {
    if (s == null) return null;
    if (fontFamily == 'system') return s;
    String fontName;
    if (fontFamily == 'NotoSansJP') {
      fontName = 'Noto Sans JP';
    } else if (fontFamily == 'Roboto') {
      fontName = 'Roboto';
    } else if (fontFamily == 'Georgia') {
      fontName = 'Georgia';
    } else {
      fontName = fontFamily;
    }
    try {
      return GoogleFonts.getFont(fontName, textStyle: s);
    } catch (_) {
      // Fallback to original style if requested font isn't available
      return s;
    }
  }

  final applied = TextTheme(
    displayLarge: applyFamily(base.textTheme.displayLarge),
    displayMedium: applyFamily(base.textTheme.displayMedium),
    displaySmall: applyFamily(base.textTheme.displaySmall),
    headlineLarge: applyFamily(base.textTheme.headlineLarge),
    headlineMedium: applyFamily(base.textTheme.headlineMedium),
    headlineSmall: applyFamily(base.textTheme.headlineSmall),
    titleLarge: applyFamily(base.textTheme.titleLarge),
    titleMedium: applyFamily(base.textTheme.titleMedium),
    titleSmall: applyFamily(base.textTheme.titleSmall),
    bodyLarge: applyFamily(base.textTheme.bodyLarge),
    bodyMedium: applyFamily(base.textTheme.bodyMedium),
    bodySmall: applyFamily(base.textTheme.bodySmall),
    labelLarge: applyFamily(base.textTheme.labelLarge),
    labelMedium: applyFamily(base.textTheme.labelMedium),
    labelSmall: applyFamily(base.textTheme.labelSmall),
  );

  final scaled = _scaledTextTheme(applied, scale);
  return base.copyWith(textTheme: scaled, primaryTextTheme: scaled);
}

ThemeData _buildScaledDarkTheme(double scale, String fontFamily) {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily == 'system' ? null : (fontFamily.startsWith('Noto') ? null : fontFamily),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00C300),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: _baseTextTheme(),
  );
  TextStyle? applyFamily(TextStyle? s) {
    if (s == null) return null;
    if (fontFamily == 'system') return s;
    String fontName;
    if (fontFamily == 'NotoSansJP') {
      fontName = 'Noto Sans JP';
    } else if (fontFamily == 'Roboto') {
      fontName = 'Roboto';
    } else if (fontFamily == 'Georgia') {
      fontName = 'Georgia';
    } else {
      fontName = fontFamily;
    }
    try {
      return GoogleFonts.getFont(fontName, textStyle: s);
    } catch (_) {
      return s;
    }
  }

  final applied = TextTheme(
    displayLarge: applyFamily(base.textTheme.displayLarge),
    displayMedium: applyFamily(base.textTheme.displayMedium),
    displaySmall: applyFamily(base.textTheme.displaySmall),
    headlineLarge: applyFamily(base.textTheme.headlineLarge),
    headlineMedium: applyFamily(base.textTheme.headlineMedium),
    headlineSmall: applyFamily(base.textTheme.headlineSmall),
    titleLarge: applyFamily(base.textTheme.titleLarge),
    titleMedium: applyFamily(base.textTheme.titleMedium),
    titleSmall: applyFamily(base.textTheme.titleSmall),
    bodyLarge: applyFamily(base.textTheme.bodyLarge),
    bodyMedium: applyFamily(base.textTheme.bodyMedium),
    bodySmall: applyFamily(base.textTheme.bodySmall),
    labelLarge: applyFamily(base.textTheme.labelLarge),
    labelMedium: applyFamily(base.textTheme.labelMedium),
    labelSmall: applyFamily(base.textTheme.labelSmall),
  );

  final scaled = _scaledTextTheme(applied, scale);
  return base.copyWith(textTheme: scaled, primaryTextTheme: scaled);
}

// Safely scale a TextTheme's font sizes. Some TextStyle entries may have
// null `fontSize` (which `TextStyle.apply(fontSizeFactor: ...)` asserts
// against on certain Flutter versions). We only scale when a concrete
// fontSize exists to avoid assertion failures.
TextTheme _scaledTextTheme(TextTheme src, double scale) {
  TextStyle? scaleStyle(TextStyle? s) {
    if (s == null) return null;
    if (s.fontSize == null) return s;
    return s.copyWith(fontSize: s.fontSize! * scale);
  }

  return TextTheme(
    displayLarge: scaleStyle(src.displayLarge),
    displayMedium: scaleStyle(src.displayMedium),
    displaySmall: scaleStyle(src.displaySmall),
    headlineLarge: scaleStyle(src.headlineLarge),
    headlineMedium: scaleStyle(src.headlineMedium),
    headlineSmall: scaleStyle(src.headlineSmall),
    titleLarge: scaleStyle(src.titleLarge),
    titleMedium: scaleStyle(src.titleMedium),
    titleSmall: scaleStyle(src.titleSmall),
    bodyLarge: scaleStyle(src.bodyLarge),
    bodyMedium: scaleStyle(src.bodyMedium),
    bodySmall: scaleStyle(src.bodySmall),
    labelLarge: scaleStyle(src.labelLarge),
    labelMedium: scaleStyle(src.labelMedium),
    labelSmall: scaleStyle(src.labelSmall),
  );
}

// Provide an explicit base TextTheme with concrete fontSize values so that
// scaling works predictably across all text styles.
TextTheme _baseTextTheme() {
  return const TextTheme(
    displayLarge: TextStyle(fontSize: 57),
    displayMedium: TextStyle(fontSize: 45),
    displaySmall: TextStyle(fontSize: 36),
    headlineLarge: TextStyle(fontSize: 32),
    headlineMedium: TextStyle(fontSize: 28),
    headlineSmall: TextStyle(fontSize: 24),
    titleLarge: TextStyle(fontSize: 22),
    titleMedium: TextStyle(fontSize: 16),
    titleSmall: TextStyle(fontSize: 14),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12),
    labelLarge: TextStyle(fontSize: 14),
    labelMedium: TextStyle(fontSize: 12),
    labelSmall: TextStyle(fontSize: 11),
  );
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final _service = BlueskyService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final success = await _service.restoreSession();
    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginWrapper extends StatefulWidget {
  const LoginWrapper({super.key});

  @override
  State<LoginWrapper> createState() => _LoginWrapperState();
}

class _LoginWrapperState extends State<LoginWrapper> {
  final _service = BlueskyService();
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin(String handle, String password) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.login(handle, password);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onLogin: _handleLogin,
      isLoading: _loading,
      error: _error,
    );
  }
}
