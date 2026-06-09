// lib/core/navigation/navigator_key.dart

import 'package:flutter/material.dart';

/// Global navigator key shared between [MaterialApp] and [NotificationService]
/// so that notification tap callbacks can push routes without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
