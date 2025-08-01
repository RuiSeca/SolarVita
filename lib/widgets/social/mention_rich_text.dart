// lib/widgets/social/mention_rich_text.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../models/user/user_mention.dart';
import '../../theme/app_theme.dart';

class MentionRichText extends StatelessWidget {
  final String text;
  final List<MentionInfo> mentions;
  final TextStyle? baseStyle;
  final TextStyle? mentionStyle;
  final Function(MentionInfo)? onMentionTap;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;

  const MentionRichText({
    super.key,
    required this.text,
    required this.mentions,
    this.baseStyle,
    this.mentionStyle,
    this.onMentionTap,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    if (mentions.isEmpty) {
      return Text(
        text,
        style:
            baseStyle ??
            TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              height: 1.4,
            ),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final spans = _buildTextSpans(context);

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign,
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    final spans = <TextSpan>[];
    int currentIndex = 0;

    // Sort mentions by start index to process them in order
    final sortedMentions = List<MentionInfo>.from(mentions)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    for (final mention in sortedMentions) {
      // Add text before mention
      if (mention.startIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, mention.startIndex),
            style:
                baseStyle ??
                TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  height: 1.4,
                ),
          ),
        );
      }

      // Add mention span
      spans.add(
        TextSpan(
          text: mention.mentionText,
          style:
              mentionStyle ??
              TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
          recognizer: onMentionTap != null
              ? (TapGestureRecognizer()..onTap = () => onMentionTap!(mention))
              : null,
        ),
      );

      currentIndex = mention.endIndex;
    }

    // Add remaining text after last mention
    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style:
              baseStyle ??
              TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                height: 1.4,
              ),
        ),
      );
    }

    return spans;
  }
}

class MentionUtils {
  /// Parses text to find @username mentions and returns mention info
  static List<MentionInfo> parseMentions(
    String text, {
    List<MentionableUser>? knownUsers,
  }) {
    final mentions = <MentionInfo>[];
    final RegExp mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);

    for (final match in matches) {
      final username = match.group(1)!;

      // Try to find user info from known users
      MentionableUser? user;
      if (knownUsers != null) {
        try {
          user = knownUsers.firstWhere((u) => u.userName == username);
        } catch (e) {
          // User not found in known users
        }
      }

      mentions.add(
        MentionInfo(
          startIndex: match.start,
          endIndex: match.end,
          userId: user?.userId ?? '',
          userName: username,
          displayName: user?.displayName ?? username,
        ),
      );
    }

    return mentions;
  }

  /// Validates that all mentions in the text have valid user data
  static List<MentionInfo> validateMentions(
    String text,
    List<MentionInfo> mentions,
  ) {
    final validMentions = <MentionInfo>[];

    for (final mention in mentions) {
      // Check if mention still exists in the text at the specified position
      if (mention.startIndex >= 0 &&
          mention.endIndex <= text.length &&
          text.substring(mention.startIndex, mention.endIndex) ==
              mention.mentionText) {
        validMentions.add(mention);
      }
    }

    return validMentions;
  }

  /// Extracts user IDs from mentions for notification purposes
  static List<String> extractUserIds(List<MentionInfo> mentions) {
    return mentions
        .where((mention) => mention.userId.isNotEmpty)
        .map((mention) => mention.userId)
        .toSet() // Remove duplicates
        .toList();
  }

  /// Creates a display-friendly version of text with mentions highlighted
  static String getDisplayText(String text, List<MentionInfo> mentions) {
    if (mentions.isEmpty) return text;

    String displayText = text;
    int offset = 0;

    // Sort mentions by start index in reverse order to maintain correct indices
    final sortedMentions = List<MentionInfo>.from(mentions)
      ..sort((a, b) => b.startIndex.compareTo(a.startIndex));

    for (final mention in sortedMentions) {
      final startIndex = mention.startIndex + offset;
      final endIndex = mention.endIndex + offset;

      if (startIndex >= 0 && endIndex <= displayText.length) {
        // Replace @username with display name or keep username
        final replacement = mention.displayName.isNotEmpty
            ? '@${mention.displayName}'
            : mention.mentionText;

        displayText =
            displayText.substring(0, startIndex) +
            replacement +
            displayText.substring(endIndex);

        offset += replacement.length - (endIndex - startIndex);
      }
    }

    return displayText;
  }
}
