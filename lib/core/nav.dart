import 'package:flutter/material.dart';

/// Clé de navigation globale, utilisable depuis n’importe où (interceptors, etc.)
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Context actuel du navigator racine (peut être null très tôt au boot)
BuildContext? get currentNavContext => appNavigatorKey.currentContext;
