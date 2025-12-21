import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';

// Compound recognizer that supports both tap and long-press and delegates
// to internal recognizers. Used so a TextSpan can respond to both tap and long-press.
class _TapLongGestureRecognizer extends OneSequenceGestureRecognizer {
  VoidCallback? onTap;
  VoidCallback? onLongPress;

  final TapGestureRecognizer _tap = TapGestureRecognizer();
  final LongPressGestureRecognizer _long = LongPressGestureRecognizer();

  @override
  void addPointer(PointerDownEvent event) {
    _tap.addPointer(event);
    _long.addPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    // Intentionally empty: internal recognizers handle events after addPointer.
  }

  @override
  String get debugDescription => 'tap_long_press';

  @override
  void dispose() {
    _tap.dispose();
    _long.dispose();
    super.dispose();
  }
}

class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final void Function(String tag)? onHashtagLongPress;
  final int? maxLines;
  final TextOverflow overflow;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.onHashtagLongPress,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Clear old recognizers
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final themeDefaultStyle = DefaultTextStyle.of(context).style;
    final defaultStyle = widget.style != null 
        ? themeDefaultStyle.merge(widget.style) 
        : themeDefaultStyle;
        
    final defaultLinkStyle = widget.linkStyle != null
        ? defaultStyle.merge(widget.linkStyle)
        : defaultStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          );

    final spans = _buildTextSpans(context, defaultStyle, defaultLinkStyle);

    return RichText(
      text: TextSpan(children: spans, style: defaultStyle),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }

  List<InlineSpan> _buildTextSpans(
      BuildContext context, TextStyle style, TextStyle linkStyle) {
    final List<InlineSpan> spans = [];
    
    // Regex patterns
    // 1. URLs with scheme (http, https, etc.)
    // 2. URLs without scheme (google.com, etc.)
    // 3. Handles (@name.bsky.social or @name.com)
    // 4. Hashtags (#topic)
    final combinedRegex = RegExp(
      r'((?:https?:\/\/|[a-z0-9]+:\/\/)[^\s]+(?<![.,?!:;]))|'
      r'((?:[a-z0-9-]+\.)+[a-z]{2,}(?:\/[^\s]*[^\s.,?!:;])?)|'
      r'(@[a-zA-Z0-9.-]+)|'
      r'(#[^\s#]+)',
      caseSensitive: false,
    );

    int lastIndex = 0;
    for (final match in combinedRegex.allMatches(widget.text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: widget.text.substring(lastIndex, match.start),
          style: style,
        ));
      }

      final matchText = match.group(0)!;
      
      if (match.group(1) != null || match.group(2) != null) {
        // URL
        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            String url = matchText;
            if (!url.contains('://')) {
              url = 'https://$url';
            }
            final uri = Uri.parse(url);
            try {
              // Try launching with inAppBrowserView first, fallback to platform default
              final launched = await launchUrl(
                uri, 
                mode: LaunchMode.inAppBrowserView,
              );
              if (!launched) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
            } catch (e) {
              debugPrint('Could not launch $url: $e');
              // Last resort fallback
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            }
          };
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          text: matchText,
          style: linkStyle,
          recognizer: recognizer,
        ));
      } else if (match.group(3) != null) {
        // Handle
        final handle = matchText.startsWith('@') ? matchText.substring(1) : matchText;
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(actor: handle),
              ),
            );
          };
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          text: matchText,
          style: linkStyle,
          recognizer: recognizer,
        ));
      } else if (match.group(4) != null) {
        // Hashtag: use compound recognizer to support both tap and long-press
        final recognizer = _TapLongGestureRecognizer();
        recognizer._tap.onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchScreen(initialQuery: matchText),
            ),
          );
        };
        recognizer._long.onLongPress = () {
          if (widget.onHashtagLongPress != null) {
            widget.onHashtagLongPress!(matchText);
          }
        };
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          text: matchText,
          style: linkStyle,
          recognizer: recognizer,
        ));
      }
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastIndex),
        style: style,
      ));
    }

    return spans;
  }
}
