import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final bool isImage;
  final double size;

  const LoadingWidget({
    super.key,
    this.isImage = false,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}