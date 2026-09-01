import 'package:flutter/material.dart';

/// Where the layout stops being a phone layout.
abstract final class AppBreakpoints {
  /// Below this there is only ever room for one column.
  static const double wide = 600;

  /// Content never grows past this, however wide the window gets.
  ///
  /// A line of text that runs the full width of a tablet is hard to read: the
  /// eye loses its place on the way back to the start of the next line. Every
  /// screen is capped and centred instead of stretched.
  static const double maxContentWidth = 720;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;
}

/// Caps its child at [AppBreakpoints.maxContentWidth] and centres it.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, this.hugHeight = false, super.key});

  final Widget child;

  /// Take only the height the child needs instead of filling what is offered.
  ///
  /// Centring expands to the constraints it is given, which is what a page body
  /// wants and exactly wrong anywhere the parent hands down loose ones. A bottom
  /// bar is the case that matters: left to expand, it claims the whole screen
  /// and the body renders nothing at all.
  final bool hugHeight;

  @override
  Widget build(BuildContext context) {
    return Align(
      heightFactor: hugHeight ? 1 : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

/// A sliver that does the same for scrolling content.
class SliverContentWidth extends StatelessWidget {
  const SliverContentWidth({required this.sliver, super.key});

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double slack = width - AppBreakpoints.maxContentWidth;
    if (slack <= 0) {
      return sliver;
    }

    // Padding rather than a nested scroll view: a sliver cannot be centred by
    // wrapping it, and the scroll has to stay one continuous list.
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: slack / 2),
      sliver: sliver,
    );
  }
}
