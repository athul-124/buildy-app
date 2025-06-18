import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Pre-warm Flutter engine
  WidgetsBinding.instance.deferFirstFrame();
  
  // Enable Impeller on iOS (already enabled by default)
  // Disable debug flags in release mode
  if (!kDebugMode) {
    debugPrintRebuildDirtyWidgets = false;
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  // Allow frame to be drawn
  WidgetsBinding.instance.allowFirstFrame();
  
  runApp(const BuildlyApp());
}
