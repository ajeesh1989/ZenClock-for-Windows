// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(380, 200),
    minimumSize: Size(250, 120),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setResizable(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ZenTimeApp());
}

class ZenTimeApp extends StatelessWidget {
  const ZenTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZenClock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const ClockScreen(),
    );
  }
}

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _glowController;
  DateTime _now = DateTime.now();
  String _location = 'Zen Mode';
  bool _isHovering = false;

  int _colorIndex = 0;
  int _fontIndex = 0;
  late SharedPreferences _prefs;

  final List<Color> _colors = [
    Colors.cyanAccent,
    Colors.deepPurpleAccent,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
    Colors.blueAccent,
    Colors.yellowAccent,
    Colors.redAccent,
    const Color(0xFF00FFD1),
    const Color(0xFFFF00FF),
    const Color(0xFF7B61FF),
    const Color(0xFFADFF2F),
  ];

  final List<
    TextStyle Function({
      TextStyle? textStyle,
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
    })
  >
  _fonts = [
    GoogleFonts.poppins,
    GoogleFonts.playfairDisplay,
    GoogleFonts.montserrat,
    GoogleFonts.quicksand,
    GoogleFonts.exo2,
    GoogleFonts.spaceMono,
    GoogleFonts.orbitron,
    GoogleFonts.dancingScript,
    GoogleFonts.bebasNeue,
    GoogleFonts.comfortaa,
    GoogleFonts.righteous,
    GoogleFonts.specialElite,
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _colorIndex = _prefs.getInt('colorIndex') ?? 0;
      _fontIndex = _prefs.getInt('fontIndex') ?? 0;
      _location = _prefs.getString('location') ?? 'Detecting...';
    });
    _fetchLocation();
  }

  void _cycleStyle() {
    setState(() {
      _colorIndex = Random().nextInt(_colors.length);
      _fontIndex = Random().nextInt(_fonts.length);
    });
    _prefs.setInt('colorIndex', _colorIndex);
    _prefs.setInt('fontIndex', _fontIndex);
  }

  Future<void> _fetchLocation() async {
    try {
      final res = await http
          .get(Uri.parse('https://ipinfo.io/json'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final city = "${data['city']}, ${data['country']}";
        setState(() => _location = city);
        _prefs.setString('location', city);
      }
    } catch (_) {}
  }

  void _showHelp() async {
    // 1. SMART EXPAND: If the window is too small, make it bigger for the guide
    await windowManager.setSize(const Size(450, 350), animate: true);

    showDialog(
      context: context,
      barrierDismissible:
          false, // Force them to click close so we can handle resize
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _colors[_colorIndex].withOpacity(0.3),
                  width: 1,
                ),
              ),
              title: Text(
                "ZenClock Guide",
                style: GoogleFonts.orbitron(
                  color: _colors[_colorIndex],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoRow(
                    Icons.expand,
                    "NOTE: Window expanded for readability.",
                  ),
                  const Divider(color: Colors.white10),
                  _infoRow(
                    Icons.touch_app,
                    "Click the time to change Fonts & Colors.",
                  ),
                  _infoRow(Icons.open_with, "Drag the top bar to move."),
                  _infoRow(
                    Icons.aspect_ratio,
                    "Drag edges to resize back down.",
                  ),
                  _infoRow(Icons.save, "Everything is saved automatically."),
                ],
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Optional: You could add code here to shrink it back,
                      // but usually users prefer to resize it themselves!
                    },
                    child: Text(
                      "Got it!",
                      style: TextStyle(
                        color: _colors[_colorIndex],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _colors[_colorIndex]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color currentAccent = _colors[_colorIndex % _colors.length];
    final Color textColor = Color.alphaBlend(
      currentAccent.withOpacity(0.4),
      Colors.white,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DragToResizeArea(
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: currentAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) => windowManager.startDragging(),
                      child: const SizedBox(height: 25, width: double.infinity),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _cycleStyle,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('hh:mm a').format(_now),
                                    style: _fonts[_fontIndex % _fonts.length](
                                          fontSize: 60,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        )
                                        .copyWith(
                                          shadows: [
                                            Shadow(
                                              blurRadius:
                                                  10 +
                                                  (_glowController.value * 15),
                                              color: currentAccent.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                            Shadow(
                                              blurRadius:
                                                  35 +
                                                  (_glowController.value * 20),
                                              color: currentAccent.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "${DateFormat('EEEE, MMM d').format(_now)}  •  $_location",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.5),
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // LEFT HELPER ICON
              Positioned(
                top: 15,
                left: 15,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 0.7 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _WindowButton(
                    icon: Icons.help_outline,
                    onPressed: _showHelp,
                  ),
                ),
              ),

              // RIGHT CONTROLS
              Positioned(
                top: 15,
                right: 15,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      _WindowButton(
                        icon: Icons.remove,
                        onPressed: () => windowManager.minimize(),
                      ),
                      const SizedBox(width: 8),
                      _WindowButton(
                        icon: Icons.close,
                        color: Colors.redAccent.withOpacity(0.7),
                        onPressed: () => windowManager.close(),
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
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.white.withOpacity(0.1),
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }
}
