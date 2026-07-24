import 'package:flutter/material.dart';

class DrawingCanvasPage extends StatefulWidget {
  const DrawingCanvasPage({super.key});

  @override
  State<DrawingCanvasPage> createState() => _DrawingCanvasPageState();
}

class _DrawingCanvasPageState extends State<DrawingCanvasPage> {
  final List<Offset?> _points = [];
  Color _color = Colors.black;
  double _strokeWidth = 4.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Dessiner pour Muse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() => _points.clear());
            },
            tooltip: 'Effacer',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _saveAndSend,
            tooltip: 'Envoyer',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(null);
                });
              },
              child: CustomPaint(
                painter: DrawingPainter(points: _points, color: _color, strokeWidth: _strokeWidth),
                size: Size.infinite,
                child: Container(color: Colors.white),
              ),
            ),
          ),
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Text('Couleur :'),
                const SizedBox(width: 8),
                _ColorOption(color: Colors.black, selected: _color == Colors.black, onTap: () => setState(() => _color = Colors.black)),
                _ColorOption(color: Colors.red, selected: _color == Colors.red, onTap: () => setState(() => _color = Colors.red)),
                _ColorOption(color: Colors.blue, selected: _color == Colors.blue, onTap: () => setState(() => _color = Colors.blue)),
                _ColorOption(color: Colors.green, selected: _color == Colors.green, onTap: () => setState(() => _color = Colors.green)),
                _ColorOption(color: Colors.orange, selected: _color == Colors.orange, onTap: () => setState(() => _color = Colors.orange)),
                const Spacer(),
                const Text('Épaisseur :'),
                Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _strokeWidth.round().toString(),
                  onChanged: (v) => setState(() => _strokeWidth = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndSend() async {
    if (_points.isEmpty) return;
    try {
      // In a production app, use RepaintBoundary + ImageGallerySaver here.
      Navigator.pop(context, 'drawing');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'envoyer le dessin")));
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  DrawingPainter({required this.points, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.blueAccent : Colors.transparent, width: 2),
        ),
      ),
    );
  }
}
