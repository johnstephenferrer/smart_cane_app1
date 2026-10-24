import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryGreen = Color(0xFF16A34A);
const Color lightGreen = Color(0xFFDCFCE7);
const Color charcoalText = Color(0xFF1F2937);
const Color darkGreen = Color(0xFF166534);
const Color brightGreen = Color(0xFF4ADE80);
const Color softGreen = Color(0xFFDCFCE7);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartCaneApp());
}

class SmartCaneApp extends StatelessWidget {
  const SmartCaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Cane',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE5E7EB),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE5E7EB),
          foregroundColor: charcoalText,
        ),
      ),
      home: const AppEntry(),
    );
  }
}

// Loads first-launch state, then shows the tutorial before onboarding.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _loading = true;
  bool _firstLaunch = true;
  Widget? _activeScreen;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _firstLaunch = !(prefs.getBool('onboarding_complete') ?? false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  void _continue() {
    if (!mounted || _loading || _activeScreen != null) return;
    setState(() {
      _activeScreen = _firstLaunch
          ? TutorialScreen(onFinished: _finishTutorial)
          : const MainShell();
    });
  }

  void _finishTutorial() {
    if (!mounted) return;
    setState(() {
      _activeScreen = _firstLaunch
          ? OnboardingScreen(onFinished: _finishOnboarding)
          : const MainShell();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = _activeScreen;
    if (screen == null) {
      return SplashScreen(onComplete: _continue, loadingPreferences: _loading);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      child: KeyedSubtree(key: ValueKey(screen.runtimeType), child: screen),
    );
  }
}

// -------------------- SPLASH + CODE-DRAWN LOGO --------------------

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool loadingPreferences;
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.loadingPreferences = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _called = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _controller.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted || _called) return;
      _called = true;
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;
    final logoBox = compact ? 156.0 : 178.0;
    final logoSize = compact ? 116.0 : 136.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F0D),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF0B0F0D)),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final pulse = Curves.easeInOut.transform(
                        _controller.value,
                      );
                      return SizedBox(
                        width: logoBox,
                        height: logoBox,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Container(
                                width:
                                    logoBox * (0.70 + i * 0.12 + pulse * 0.025),
                                height:
                                    logoBox * (0.70 + i * 0.12 + pulse * 0.025),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: brightGreen.withValues(
                                      alpha:
                                          0.12 + (1 - pulse) * 0.08 - i * 0.025,
                                    ),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            child!,
                          ],
                        ),
                      );
                    },
                    child: SmartCaneLogo(size: logoSize),
                  ),
                  SizedBox(height: compact ? 18 : 28),
                  const Text(
                    'SMART CANE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SMARTER MOVEMENT. GREATER CONFIDENCE.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(flex: 2),
                  const SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      backgroundColor: Color(0x553A4A3F),
                      valueColor: AlwaysStoppedAnimation<Color>(brightGreen),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.loadingPreferences
                        ? 'Preparing your experience...'
                        : 'Ready when you are',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 12 : 24),
                    child: Text(
                      'SMART CANE  •  MOBILITY COMPANION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SmartCaneLogo extends StatelessWidget {
  final double size;
  const SmartCaneLogo({super.key, this.size = 112});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brightGreen, darkGreen],
        ),
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: brightGreen.withValues(alpha: 0.32),
            blurRadius: size * 0.24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const CustomPaint(painter: _SmartCaneLogoPainter()),
    );
  }
}

class _SmartCaneLogoPainter extends CustomPainter {
  const _SmartCaneLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cane = Path()
      ..moveTo(48, 85)
      ..lineTo(48, 34)
      ..cubicTo(48, 26, 52, 22, 60, 22)
      ..lineTo(70, 22)
      ..cubicTo(76, 22, 79, 25, 79, 31)
      ..moveTo(48, 85)
      ..lineTo(43, 97);
    canvas.drawPath(cane, line);

    final waves = <Path>[
      Path()
        ..moveTo(35, 42)
        ..quadraticBezierTo(24, 51, 35, 60),
      Path()
        ..moveTo(27, 34)
        ..quadraticBezierTo(10, 51, 27, 68),
      Path()
        ..moveTo(87, 42)
        ..quadraticBezierTo(98, 51, 87, 60),
      Path()
        ..moveTo(95, 34)
        ..quadraticBezierTo(112, 51, 95, 68),
    ];
    for (final wave in waves) {
      canvas.drawPath(wave, line);
    }
    canvas.drawCircle(const Offset(48, 85), 5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(79, 31), 4, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------- WELCOME + ONBOARDING --------------------

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _index = 0;
  late final AnimationController _animation;

  final List<_IntroPage> _pages = const [
    _IntroPage(
      icon: Icons.sensors_rounded,
      eyebrow: 'SMARTER DETECTION',
      title: 'More awareness,\nstep by step.',
      description: 'Two detection zones are designed to help identify obstacles above and near the ground.',
      tags: ['Upper zone', 'Lower zone'],
    ),
    _IntroPage(
      icon: Icons.vibration_rounded,
      eyebrow: 'CLEAR ALERTS',
      title: 'Feel and hear\nthe difference.',
      description: 'The cane is designed to use sound and vibration alerts to communicate detected obstacles.',
      tags: ['Buzzer alerts', 'Vibration alerts'],
    ),
    _IntroPage(
      icon: Icons.bluetooth_rounded,
      eyebrow: 'CONNECTED EXPERIENCE',
      title: 'Your cane,\nat a glance.',
      description: 'View sensor readings and device information here once compatible hardware is connected.',
      tags: ['Sensor readings', 'Device status'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animation.dispose();
    super.dispose();
  }

  bool _finishing = false;

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await widget.onFinished();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (_) {
      if (mounted) setState(() => _finishing = false);
      rethrow;
    }
  }

  Future<void> _skip() => _finish();

  Future<void> _next() async {
    if (_finishing) return;
    if (_index < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const SmartCaneLogo(size: 42),
                  const SizedBox(width: 10),
                  const Text(
                    'SMART CANE',
                    style: TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finishing ? null : _skip,
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    _animation
                      ..reset()
                      ..forward();
                  },
                  itemBuilder: (context, i) => FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animation,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: _IntroContent(page: _pages[i]),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 25 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index ? primaryGreen : softGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _finishing ? null : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _index == _pages.length - 1 ? "Let's Begin" : 'Next',
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Designed to support safer mobility',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> tags;

  const _IntroPage({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.tags,
  });
}

class _IntroContent extends StatelessWidget {
  final _IntroPage page;
  const _IntroContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            color: lightGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.10),
                blurRadius: 34,
                spreadRadius: 7,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 164,
                height: 164,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.14),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [brightGreen, darkGreen],
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Icon(page.icon, size: 64, color: Colors.white),
              ),
              Positioned(top: 24, right: 27, child: _dot()),
              Positioned(bottom: 32, left: 25, child: _dot()),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text(
          page.eyebrow,
          style: const TextStyle(
            color: primaryGreen,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: darkGreen,
            fontSize: 33,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: page.tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _dot() => Container(
    width: 13,
    height: 13,
    decoration: const BoxDecoration(color: brightGreen, shape: BoxShape.circle),
  );
}

// -------------------- MAIN NAVIGATION --------------------

enum AppTab { home, sensors, battery, bluetooth }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.home;

  void _openTutorial() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TutorialScreen(onFinished: () => Navigator.of(context).pop()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onOpenSensors: () => setState(() => _tab = AppTab.sensors),
        onOpenBluetooth: () => setState(() => _tab = AppTab.bluetooth),
        onOpenBattery: () => setState(() => _tab = AppTab.battery),
        onOpenTutorial: _openTutorial,
      ),
      const SensorsScreen(),
      const BatteryScreen(),
      const BluetoothScreen(),
    ];
    final selected = AppTab.values.indexOf(_tab);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < pages.length; i++)
            Positioned.fill(
              child: Semantics(
                hidden: i != selected,
                child: IgnorePointer(
                  ignoring: i != selected,
                  child: AnimatedOpacity(
                    opacity: i == selected ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: i == selected
                          ? Offset.zero
                          : const Offset(0.035, 0),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: TickerMode(
                        enabled: i == selected,
                        child: pages[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) {
          if (i != selected) setState(() => _tab = AppTab.values[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors_rounded),
            label: 'Sensors',
          ),
          NavigationDestination(
            icon: Icon(Icons.battery_charging_full_outlined),
            selectedIcon: Icon(Icons.battery_charging_full_rounded),
            label: 'Battery',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth_outlined),
            selectedIcon: Icon(Icons.bluetooth_rounded),
            label: 'Bluetooth',
          ),
        ],
      ),
    );
  }
}

// -------------------- HOME DASHBOARD --------------------

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSensors;
  final VoidCallback? onOpenBluetooth;
  final VoidCallback? onOpenBattery;
  final VoidCallback? onOpenTutorial;

  const HomeScreen({
    super.key,
    this.onOpenSensors,
    this.onOpenBluetooth,
    this.onOpenBattery,
    this.onOpenTutorial,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final start = (index * 0.085).clamp(0.0, 0.72).toDouble();
    final end = (start + 0.38).clamp(0.0, 1.0).toDouble();
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SMART CANE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SettingsScreen(onReplayTutorial: widget.onOpenTutorial),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _reveal(
              0,
              Container(
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF17231C), Color(0xFF263B2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: brightGreen.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -34,
                      top: -46,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final pulse = Curves.easeInOut.transform(
                            _pulse.value,
                          );
                          return Container(
                            width: 146 + 16 * pulse,
                            height: 146 + 16 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: brightGreen.withValues(
                                  alpha: 0.08 + pulse * 0.10,
                                ),
                                width: 1.4,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SmartCaneLogo(size: 54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SMART CANE',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 11,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  _ConnectionPill(
                                    onTap: widget.onOpenBluetooth,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 23),
                        const Text(
                          'Your safety,\nwithin reach.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Monitor your cane at a glance.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _reveal(1, const SectionTitle('DEVICE STATUS')),
            const SizedBox(height: 12),
            _reveal(
              1,
              _DashboardActionCard(
                onTap: widget.onOpenBluetooth,
                child: const Row(
                  children: [
                    _StatusGlyph(icon: Icons.bluetooth_rounded),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bluetooth',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Not connected',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Connect',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _reveal(
              2,
              SectionTitle(
                'SENSOR MONITOR',
                action: 'View all',
                onAction: widget.onOpenSensors,
              ),
            ),
            const SizedBox(height: 12),
            _reveal(
              2,
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 360 ? 1 : 2;
                  final tileWidth =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: SensorCard(
                          title: 'Upper sensor',
                          subtitle: 'Above-ground hazards',
                          range: '100 cm',
                          icon: Icons.vertical_align_top_rounded,
                          onTap: widget.onOpenSensors,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: SensorCard(
                          title: 'Lower sensor',
                          subtitle: 'Ground hazards',
                          range: '50 cm',
                          icon: Icons.vertical_align_bottom_rounded,
                          onTap: widget.onOpenSensors,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            _reveal(3, const SectionTitle('ALERT SYSTEM')),
            const SizedBox(height: 12),
            _reveal(
              3,
              const Row(
                children: [
                  Expanded(
                    child: StatusCard(
                      title: 'Buzzer',
                      subtitle: 'Not reporting',
                      icon: Icons.notifications_active_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatusCard(
                      title: 'Vibration',
                      subtitle: 'Not reporting',
                      icon: Icons.vibration_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _reveal(
              4,
              _DashboardActionCard(
                onTap: widget.onOpenBattery,
                child: const Row(
                  children: [
                    _StatusGlyph(icon: Icons.battery_unknown_rounded),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Battery',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Status unavailable',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: charcoalText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _reveal(5, const DemoNotice()),
            if (widget.onOpenTutorial != null) ...[
              const SizedBox(height: 14),
              _reveal(
                5,
                OutlinedButton.icon(
                  onPressed: widget.onOpenTutorial,
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Learn how Smart Cane works'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final VoidCallback? onTap;
  const _ConnectionPill({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: brightGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'DISCONNECTED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  final IconData icon;
  const _StatusGlyph({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: lightGreen,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: primaryGreen, size: 23),
  );
}

class _DashboardActionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _DashboardActionCard({required this.child, this.onTap});

  @override
  State<_DashboardActionCard> createState() => _DashboardActionCardState();
}

class _DashboardActionCardState extends State<_DashboardActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// -------------------- SENSORS / BATTERY / BLUETOOTH --------------------

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Sensors',
      subtitle: 'Two detection zones, one overview.',
      children: const [
        DemoNotice(),
        SizedBox(height: 16),
        SensorDetailCard(
          icon: Icons.vertical_align_top_rounded,
          title: 'Upper detection zone',
          description: 'Designed for obstacles above the lower walking path, such as walls or hanging objects.',
          range: '100 cm',
        ),
        SizedBox(height: 14),
        SensorDetailCard(
          icon: Icons.vertical_align_bottom_rounded,
          title: 'Lower detection zone',
          description: 'Designed for ground-level obstacles such as steps, debris, or uneven surfaces.',
          range: '50 cm',
        ),
        SizedBox(height: 18),
        SectionTitle('LIVE READINGS'),
        SizedBox(height: 8),
        InfoRow(
          icon: Icons.sensors_rounded,
          label: 'Upper sensor',
          value: '— cm',
        ),
        InfoRow(
          icon: Icons.sensors_rounded,
          label: 'Lower sensor',
          value: '— cm',
        ),
      ],
    );
  }
}

class BatteryScreen extends StatelessWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Battery',
      subtitle: 'Keep track of your cane power.',
      children: const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Icon(
              Icons.battery_unknown_rounded,
              size: 76,
              color: primaryGreen,
            ),
          ),
        ),
        Text(
          'Battery data unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: darkGreen,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Battery percentage and runtime estimates will be available after hardware integration and testing.',
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        InfoRow(
          icon: Icons.battery_std_rounded,
          label: 'Battery percentage',
          value: '—',
        ),
        InfoRow(
          icon: Icons.schedule_rounded,
          label: 'Estimated runtime',
          value: '—',
        ),
        InfoRow(
          icon: Icons.power_rounded,
          label: 'Power source',
          value: 'Not detected',
        ),
        SizedBox(height: 16),
        DemoNotice(),
      ],
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final FlutterClassicBluetooth _bluetooth = FlutterClassicBluetooth();
  final List<BtcDevice> _devices = [];
  BtcConnection? _connection;
  StreamSubscription<dynamic>? _inputSubscription;
  bool _scanning = false;
  bool _connecting = false;
  String _status = 'Not connected';
  String? _error;
  int _receivedBytes = 0;

  @override
  void dispose() {
    _inputSubscription?.cancel();
    final connection = _connection;
    if (connection != null) {
      unawaited(connection.close());
      connection.dispose();
    }
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning || _connecting) return;
    setState(() {
      _scanning = true;
      _error = null;
      _status = 'Looking for nearby Bluetooth devices…';
      _devices.clear();
    });

    try {
      if (!await _bluetooth.isSupported()) {
        throw StateError(
          'Bluetooth Classic is available in the Android app, not in a browser.',
        );
      }
      if (!await _bluetooth.isEnabled()) {
        await _bluetooth.enableBluetooth();
      }
      final paired = await _bluetooth.getPairedDevices();
      final nearby = await _bluetooth.scan(
        timeout: const Duration(seconds: 10),
      );
      final byAddress = <String, BtcDevice>{
        for (final device in paired) device.address: device,
        for (final device in nearby) device.address: device,
      };
      final found = byAddress.values.toList();
      if (!mounted) return;
      setState(() {
        _devices
          ..clear()
          ..addAll(found);
        _status = found.isEmpty
            ? 'No devices found. Make the HC-05 discoverable and scan again.'
            : 'Found ${found.length} device${found.length == 1 ? '' : 's'}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Scan could not start';
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(BtcDevice device) async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _error = null;
      _status = 'Pairing with ${_deviceName(device)}…';
    });
    try {
      final paired = device.bondState.name.toLowerCase() == 'bonded';
      if (!paired) {
        final bonded = await _bluetooth.bondDevice(device.address);
        if (!bonded) {
          throw StateError(
            'Pairing was not completed. You can pair the HC-05 in Android Bluetooth settings and try again.',
          );
        }
      }

      setState(() => _status = 'Connecting to ${_deviceName(device)}…');
      final connection = await _bluetooth.connect(
        address: device.address,
        timeout: const Duration(seconds: 15),
      );
      if (!mounted) {
        await connection.close();
        connection.dispose();
        return;
      }
      _connection = connection;
      setState(() {
        _receivedBytes = 0;
        _status = 'Connected to ${_deviceName(device)}';
      });
      _inputSubscription = connection.input.listen(
        (bytes) {
          if (!mounted) return;
          setState(() => _receivedBytes += bytes.length.toInt());
        },
        onDone: _connectionEnded,
        onError: (Object error) => _connectionEnded(error),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Not connected';
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _connectionEnded([Object? error]) {
    if (!mounted) return;
    setState(() {
      _status = 'Connection closed';
      _error = error?.toString();
      _connection = null;
    });
  }

  Future<void> _disconnect() async {
    final connection = _connection;
    if (connection == null) return;
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    try {
      await connection.close();
    } catch (_) {
      // The remote device may have already closed the serial link.
    }
    connection.dispose();
    if (!mounted) return;
    setState(() {
      _connection = null;
      _receivedBytes = 0;
      _status = 'Not connected';
    });
  }

  String _deviceName(BtcDevice device) {
    final name = device.displayName.trim();
    return name.isEmpty ? 'Unnamed device' : name;
  }

  @override
  Widget build(BuildContext context) {
    final connected = _connection?.isConnected ?? false;
    return AppPage(
      title: 'Bluetooth',
      subtitle: 'Find and connect to the HC-05 serial module.',
      children: [
        const Center(child: SmartCaneLogo(size: 92)),
        const SizedBox(height: 14),
        Text(
          connected ? _status : _status,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: darkGreen,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          connected
              ? 'The serial link is active. Sensor values will appear after the Arduino sends a defined data format.'
              : 'Turn on the cane and make its HC-05 module discoverable. Bluetooth Classic scanning works in the Android app, not the browser preview.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.45),
        ),
        const SizedBox(height: 18),
        if (connected)
          OutlinedButton.icon(
            onPressed: _disconnect,
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('Disconnect'),
          )
        else
          FilledButton.icon(
            onPressed: _scanning || _connecting ? null : _scan,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching_rounded),
            label: Text(_scanning ? 'Scanning…' : 'Find Bluetooth devices'),
          ),
        if (_connecting) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        if (_devices.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionTitle('NEARBY DEVICES'),
          const SizedBox(height: 8),
          for (final device in _devices)
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: lightGreen,
                  child: Icon(Icons.bluetooth_rounded, color: primaryGreen),
                ),
                title: Text(_deviceName(device)),
                subtitle: Text(
                  '${device.address} • ${device.bondState.name}'
                  '${device.rssi == null ? '' : ' • ${device.rssi} dBm'}',
                ),
                trailing: TextButton(
                  onPressed: _connecting ? null : () => _connect(device),
                  child: Text(
                    device.bondState.name.toLowerCase() == 'bonded'
                        ? 'Connect'
                        : 'Pair',
                  ),
                ),
              ),
            ),
        ],
        if (connected) ...[
          const SizedBox(height: 18),
          InfoRow(
            icon: Icons.sync_rounded,
            label: 'Serial bytes received',
            value: '$_receivedBytes',
          ),
        ],
        const SizedBox(height: 16),
        const DemoNotice(),
      ],
    );
  }
}
// -------------------- SETTINGS --------------------

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onReplayTutorial;
  const SettingsScreen({super.key, this.onReplayTutorial});

  Future<void> _resetIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The introduction will show the next time the app launches.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle('APP EXPERIENCE'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.school_outlined, color: primaryGreen),
              title: const Text('Replay quick tutorial'),
              subtitle: const Text('Review the app features.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onReplayTutorial,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.replay_rounded, color: primaryGreen),
              title: const Text('Show introduction again'),
              subtitle: const Text('Show onboarding on next launch.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _resetIntro(context),
            ),
          ),
          const SizedBox(height: 16),
          const DemoNotice(),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'SMART CANE • Confidence in every step',
              style: TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- QUICK TUTORIAL --------------------

class TutorialScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const TutorialScreen({super.key, required this.onFinished});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_TutorialStep> _steps = const [
    _TutorialStep(
      icon: Icons.dashboard_rounded,
      title: 'Your dashboard',
      description: 'Home gives you an overview of connection status, sensor zones, alert components, and device status.',
    ),
    _TutorialStep(
      icon: Icons.sensors_rounded,
      title: 'Sensor zones',
      description: 'The prototype is configured for an upper range up to 100 cm and a lower range up to 50 cm. Actual readings will appear after integration.',
    ),
    _TutorialStep(
      icon: Icons.vibration_rounded,
      title: 'Sound and vibration',
      description: 'The planned alert system uses different buzzer patterns and vibration levels to communicate obstacle distance. The app does not control these alerts yet.',
    ),
    _TutorialStep(
      icon: Icons.battery_charging_full_rounded,
      title: 'Battery and Bluetooth',
      description: 'Battery information, pairing, and live updates will be added after the hardware communication is implemented.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _steps.length - 1) {
      widget.onFinished();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quick tutorial'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final step = _steps[i];
                    return LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 32,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                key: ValueKey('tutorial-icon-$i'),
                                tween: Tween(begin: 0.82, end: 1),
                                duration: const Duration(milliseconds: 480),
                                curve: Curves.easeOutBack,
                                builder: (context, scale, child) =>
                                    Transform.scale(scale: scale, child: child),
                                child: Container(
                                  width: constraints.maxHeight < 560
                                      ? 132
                                      : 168,
                                  height: constraints.maxHeight < 560
                                      ? 132
                                      : 168,
                                  decoration: BoxDecoration(
                                    color: lightGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGreen.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    step.icon,
                                    size: constraints.maxHeight < 560 ? 64 : 76,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'STEP ${i + 1} OF ${_steps.length}',
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                transitionBuilder: (child, animation) =>
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.12),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                child: Text(
                                  step.title,
                                  key: ValueKey('tutorial-title-$i'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: darkGreen,
                                    fontSize: 29,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  step.description,
                                  key: ValueKey('tutorial-description-$i'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    height: 1.6,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index ? primaryGreen : softGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.96, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _index == _steps.length - 1
                            ? 'Finish tutorial'
                            : 'Next',
                        key: ValueKey(_index == _steps.length - 1),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onFinished,
                child: const Text('Skip tutorial'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// -------------------- SHARED WIDGETS --------------------

class AppPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AppPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: charcoalText,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String range;
  final IconData icon;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.range,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardActionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusGlyph(icon: icon),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 17,
                color: Colors.grey.shade500,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '—',
                style: TextStyle(
                  fontSize: 27,
                  color: primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'cm',
                  style: TextStyle(
                    color: charcoalText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Max range: $range',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const StatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(icon, color: primaryGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class SensorDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String range;

  const SensorDetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: lightGreen,
                  child: Icon(icon, color: primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Configured maximum range',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
                Text(
                  range,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAE5F3))),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: darkGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: darkGreen),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo mode: this screen is not receiving live data from the cane yet.',
              style: TextStyle(color: darkGreen, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
