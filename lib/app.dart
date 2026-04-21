import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router.dart';

class CentPlayApp extends StatelessWidget {
  const CentPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CentPlay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.light,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      routerConfig: router,
    );
  }
}
