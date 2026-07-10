import 'package:flutter/material.dart';
import '../services/word_predictor_service.dart';

class SuggestionOverlay extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSelect;

  const SuggestionOverlay({
    super.key,
    required this.controller,
    required this.onSelect,
  });

  @override
  State<SuggestionOverlay> createState() => _SuggestionOverlayState();
}

class _SuggestionOverlayState extends State<SuggestionOverlay> {
  final WordPredictorService _predictor = WordPredictorService();
  List<String> _suggestions = [];
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text == _lastText) return;
    _lastText = text;

    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0) {
      setState(() => _suggestions = []);
      return;
    }

    final beforeCursor = text.substring(0, cursorPos);
    final words = beforeCursor.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final currentWord = words.last;
    if (currentWord.isEmpty || currentWord.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    final previousWord = words.length >= 2 ? words[words.length - 2] : null;

    final suggestions = _predictor.suggest(currentWord, previousWord: previousWord);
    if (mounted) {
      setState(() => _suggestions = suggestions);
    }
  }

  void _applySuggestion(String suggestion) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0) return;

    final beforeCursor = text.substring(0, cursorPos);
    final afterCursor = text.substring(cursorPos);
    final words = beforeCursor.split(RegExp(r'\s+'));
    if (words.isEmpty) return;

    final currentWord = words.last;
    final beforeLastWord = beforeCursor.substring(0, beforeCursor.length - currentWord.length);

    widget.controller.text = '$beforeLastWord$suggestion $afterCursor';
    widget.controller.selection = TextSelection.collapsed(
      offset: beforeLastWord.length + suggestion.length + 1,
    );
    widget.onSelect();
    setState(() => _suggestions = []);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final word = _suggestions[index];
          return GestureDetector(
            onTap: () => _applySuggestion(word),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.text_fields, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    word,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
