import 'package:flutter/material.dart';

class CarouselItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  const CarouselItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}

class CarouselStack extends StatefulWidget {
  final List<CarouselItem> items;
  final ValueChanged<int>? onItemTap;

  const CarouselStack({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  State<CarouselStack> createState() => _CarouselStackState();
}

class _CarouselStackState extends State<CarouselStack> {
  late List<int> _indices;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _indices = [0, 1, 2, 3];
  }

  void _paginate() {
    setState(() {
      _indices = [_indices[1], _indices[2], _indices[3], _indices[0]];
    });
    _dragOffset = 0.0;
  }

  double _swipePower(double offset, double velocity) {
    return offset.abs() * velocity;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth * 0.75;
    final cardHeight = cardWidth * 0.85;

    final scales = [1.0, 0.9, 0.85, 0.8];
    final yOffsets = [0.0, -12.0, 0.0, 12.0];
    final xOffsets = [0.0, 32.0, 48.0, 62.0];
    final rotations = [0.0, 2.0, 4.0, 7.0];

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _dragOffset += details.primaryDelta ?? 0.0;
      },
      onHorizontalDragEnd: (details) {
        final power = _swipePower(_dragOffset, details.velocity.pixelsPerSecond.dx);
        if (power < -10000 || power > 10000) {
          _paginate();
        } else {
          setState(() => _dragOffset = 0.0);
        }
      },
      child: SizedBox(
        height: cardHeight + 40,
        child: Stack(
          children: List.generate(4, (i) {
            final itemIndex = _indices[i];
            if (itemIndex >= widget.items.length) return const SizedBox.shrink();
            final item = widget.items[itemIndex];

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                // ignore: deprecated_member_use
                ..scale(scales[i])
                // ignore: deprecated_member_use
                ..translate(xOffsets[i], yOffsets[i])
                ..rotateZ(rotations[i] * 3.14159265359 / 180),
              child: GestureDetector(
                onTap: () => widget.onItemTap?.call(itemIndex),
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(color: Colors.grey[200]);
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}