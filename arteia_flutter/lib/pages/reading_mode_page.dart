import 'package:flutter/material.dart';
import '../theme/category_themes.dart';

class ReadingModePage extends StatefulWidget {
  final String title;
  final String author;
  final String content;
  final String category;

  const ReadingModePage({
    super.key,
    required this.title,
    required this.author,
    required this.content,
    required this.category,
  });

  @override
  State<ReadingModePage> createState() => _ReadingModePageState();
}

class _ReadingModePageState extends State<ReadingModePage> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showControls = true;
  double _fontSize = 18;
  bool _isDarkMode = true;
  late CategoryTheme _categoryTheme;

  final List<String> _pages = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _splitContentIntoPages();
  }

  CategoryTheme _getThemeForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return CategoryThemes.music;
      case 'film':
        return CategoryThemes.film;
      case 'visual-art':
        return CategoryThemes.visualArt;
      case 'manga':
        return CategoryThemes.manga;
      case 'literature':
        return CategoryThemes.literature;
      case 'animation':
        return CategoryThemes.animation;
      default:
        return CategoryThemes.music;
    }
  }

  void _splitContentIntoPages() {
    // Split content into pages of ~500 characters each
    final words = widget.content.split(' ');
    final List<String> pages = [];
    String currentPage = '';

    for (final word in words) {
      if ((currentPage + ' ' + word).length > 500 && currentPage.isNotEmpty) {
        pages.add(currentPage.trim());
        currentPage = word;
      } else {
        currentPage += ' ' + word;
      }
    }

    if (currentPage.trim().isNotEmpty) {
      pages.add(currentPage.trim());
    }

    // If content is short, keep it as one page
    if (pages.isEmpty) {
      pages.add(widget.content);
    }

    setState(() {
      _pages.clear();
      _pages.addAll(pages);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14.0, 28.0);
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF000000);
    final secondaryTextColor = _isDarkMode ? Colors.grey[400] : const Color(0xFF666666);
    final accentColor = _isDarkMode ? Colors.white : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _showControls
          ? AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.title,
                style: TextStyle(color: textColor, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: textColor,
                  ),
                  onPressed: _toggleTheme,
                ),
                IconButton(
                  icon: Icon(Icons.text_fields, color: textColor),
                  onPressed: () => _showFontSizeDialog(context),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // Reading progress bar
          if (_showControls)
            Container(
              height: 2,
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 56,
                left: 16,
                right: 16,
              ),
              child: LinearProgressIndicator(
                value: _pages.isEmpty ? 0.0 : (_currentPage + 1) / _pages.length,
                backgroundColor: secondaryTextColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  accentColor,
                ),
              ),
            ),

          // Reading content
          Expanded(
            child: GestureDetector(
              onTap: _toggleControls,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title on first page
                        if (index == 0) ...[
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: _fontSize + 8,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Par ${widget.author} · ${widget.category}',
                            style: TextStyle(
                              fontSize: _fontSize - 4,
                              color: secondaryTextColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 32,
                          ),
                        ],

                        // Content
                        Text(
                          _pages[index],
                          style: TextStyle(
                            fontSize: _fontSize,
                            color: textColor,
                            height: 1.8,
                            letterSpacing: 0.3,
                          ),
                        ),

                        // Page indicator at bottom
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            _pages.length > 1
                                ? 'Page ${index + 1} / ${_pages.length}'
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom controls
          if (_showControls)
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: (secondaryTextColor as Color?) ?? Colors.grey.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: textColor),
                    onPressed: () => _changeFontSize(-2),
                  ),
                  Text(
                    '${_fontSize.toInt()}px',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: textColor),
                    onPressed: () => _changeFontSize(2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Taille du texte',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _fontSize,
              min: 14,
              max: 28,
              divisions: 7,
              label: '${_fontSize.toInt()}px',
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
            Text(
              '${_fontSize.toInt()}px',
              style: TextStyle(
                fontSize: _fontSize,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}