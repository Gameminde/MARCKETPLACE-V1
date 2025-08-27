import 'package:flutter/material.dart';

class DraggableSection extends StatelessWidget {
  final String type; // header, hero, products, footer
  final Widget child;
  const DraggableSection({super.key, required this.type, required this.child});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: type,
      feedback: Opacity(
        opacity: 0.7,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
              ),
              child: child,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}





