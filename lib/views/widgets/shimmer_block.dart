import 'package:flutter/material.dart';

class ShimmerBlock extends StatefulWidget {
  final double height;
  final double width;
  final double radius;

  const ShimmerBlock({
    super.key,
    required this.height,
    required this.width,
    this.radius = 14,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade200;
    final hi = Colors.grey.shade100;

    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ Si width = infinity, on prend la largeur disponible
        final w = widget.width.isInfinite ? constraints.maxWidth : widget.width;

        return AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = _c.value; // 0..1
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: Container(
                height: widget.height,
                width: w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + (2.0 * t), -0.2),
                    end: Alignment(1.0 + (2.0 * t), 0.2),
                    colors: [base, hi, base],
                    stops: const [0.1, 0.5, 0.9],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
