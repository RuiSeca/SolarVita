// lib/widgets/social/mention_text_field.dart
import 'package:flutter/material.dart';
import '../../models/user_mention.dart';
import '../../theme/app_theme.dart';
import 'user_autocomplete_widget.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final Function(List<MentionInfo>)? onMentionsChanged;
  final Function(String)? onTextChanged;
  final FocusNode? focusNode;
  final TextStyle? textStyle;
  final bool enabled;

  const MentionTextField({
    super.key,
    required this.controller,
    this.hintText = 'What\'s on your mind?',
    this.maxLines = 6,
    this.onMentionsChanged,
    this.onTextChanged,
    this.focusNode,
    this.textStyle,
    this.enabled = true,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  final GlobalKey _textFieldKey = GlobalKey();
  List<MentionInfo> _mentions = [];
  String _currentMentionQuery = '';
  int _mentionStartIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    widget.onTextChanged?.call(text);
    
    // Parse mentions in the text
    _updateMentions(text);
    
    // Check for active mention typing
    _checkForMentionTyping(text, selection);
  }

  void _updateMentions(String text) {
    final RegExp mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    
    final newMentions = <MentionInfo>[];
    
    for (final match in matches) {
      // Check if this mention is already in our list
      final existingMention = _mentions.firstWhere(
        (mention) => mention.startIndex == match.start && 
                    mention.endIndex == match.end,
        orElse: () => MentionInfo(
          startIndex: -1,
          endIndex: -1,
          userId: '',
          userName: '',
          displayName: '',
        ),
      );
      
      if (existingMention.startIndex != -1) {
        newMentions.add(existingMention);
      }
    }
    
    _mentions = newMentions;
    widget.onMentionsChanged?.call(_mentions);
  }

  void _checkForMentionTyping(String text, TextSelection selection) {
    if (selection.baseOffset != selection.extentOffset) {
      _removeOverlay();
      return;
    }
    
    final cursorPosition = selection.baseOffset;
    
    // Find the last @ symbol before cursor position
    int mentionStart = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        mentionStart = i;
        break;
      } else if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }
    
    if (mentionStart != -1) {
      // Check if there's a space or end of string after the cursor
      bool validMentionEnd = cursorPosition == text.length || 
                            text[cursorPosition] == ' ' || 
                            text[cursorPosition] == '\n';
      
      if (validMentionEnd) {
        final mentionText = text.substring(mentionStart + 1, cursorPosition);
        
        // Only show autocomplete if mention is valid (letters, numbers, underscore)
        if (RegExp(r'^[a-zA-Z0-9_]*$').hasMatch(mentionText)) {
          _mentionStartIndex = mentionStart;
          _currentMentionQuery = mentionText;
          _showAutocomplete();
          return;
        }
      }
    }
    
    _removeOverlay();
  }

  void _showAutocomplete() {
    _removeOverlay();
    
    final renderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: UserAutocompleteWidget(
            query: _currentMentionQuery,
            onUserSelected: _onUserSelected,
            onDismiss: _removeOverlay,
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onUserSelected(MentionableUser user) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    // Use the actual cursor position if available, otherwise fall back to calculated position
    final cursorPosition = selection.isValid ? selection.baseOffset : -1;
    final mentionEndIndex = cursorPosition >= 0 ? cursorPosition : _mentionStartIndex + 1 + _currentMentionQuery.length;
    
    // Replace the partial mention with the complete username
    final newText = '${text.substring(0, _mentionStartIndex)}@${user.userName}${text.substring(mentionEndIndex)}';
    
    // Create mention info
    final mentionInfo = MentionInfo(
      startIndex: _mentionStartIndex,
      endIndex: _mentionStartIndex + user.userName.length + 1,
      userId: user.userId,
      userName: user.userName,
      displayName: user.displayName,
    );
    
    // Add to mentions list
    _mentions.add(mentionInfo);
    
    // Update text and cursor position with more precise positioning
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: _mentionStartIndex + user.userName.length + 1,
      ),
    );
    
    _removeOverlay();
    widget.onMentionsChanged?.call(_mentions);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _textFieldKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(51),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          border: InputBorder.none,
        ),
        style: widget.textStyle ?? TextStyle(
          color: AppTheme.textColor(context),
          fontSize: 16,
        ),
      ),
    );
  }
}