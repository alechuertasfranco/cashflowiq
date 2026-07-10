// lib/core/widgets/app_header_bar.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

/// Shared app bar shell — replaces the near-identical `AppBar(...)` block
/// that used to be copy-pasted across ~15 screens.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  /// Optional bottom widget (e.g. a `TabBar`) — same role as `AppBar.bottom`.
  final PreferredSizeWidget? bottom;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: context.heading4()),
      leading: leading,
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
    );
  }
}
