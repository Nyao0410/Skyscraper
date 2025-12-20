import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';

class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final bool selectable;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeDefaultStyle = DefaultTextStyle.of(context).style;
    final defaultStyle = style != null 
        ? themeDefaultStyle.merge(style) 
        : themeDefaultStyle;
        
    final defaultLinkStyle = linkStyle != null
        ? defaultStyle.merge(linkStyle)
        : defaultStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          );

    final spans = _buildTextSpans(context, defaultStyle, defaultLinkStyle);

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
        style: defaultStyle,
      );
    }

    return RichText(
      text: TextSpan(children: spans, style: defaultStyle),
    );
  }

  List<InlineSpan> _buildTextSpans(
      BuildContext context, TextStyle style, TextStyle linkStyle) {
    final List<InlineSpan> spans = [];
    
    // Regex patterns
    // 1. URLs
    // 2. Handles (~.bsky.social)
    // 3. Hashtags (#~)
    final combinedRegex = RegExp(
      r'(https?:\/\/[^\s]+)|(@?[a-zA-Z0-9.-]+\.bsky\.social)|(#[^\s#]+)',
      caseSensitive: false,
    );

    int lastIndex = 0;
    for (final match in combinedRegex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: style,
        ));
      }

      final matchText = match.group(0)!;
      
      if (match.group(1) != null) {
        // URL
        spans.add(TextSpan(
          text: matchText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(matchText);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ));
      } else if (match.group(2) != null) {
        // Handle
        final handle = matchText.startsWith('@') ? matchText.substring(1) : matchText;
        spans.add(TextSpan(
          text: matchText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(actor: handle),
                ),
              );
            },
        ));
      } else if (match.group(3) != null) {
        // Hashtag
        spans.add(TextSpan(
          text: matchText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(initialQuery: matchText),
                ),
              );
            },
        ));
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return spans;
  }
}
