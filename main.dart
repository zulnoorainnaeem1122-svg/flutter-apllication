import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sfx.dart';
import 'jigsaw.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, File;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
//import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DarkJigsawApp());
}

class DarkJigsawApp extends StatefulWidget {
  const DarkJigsawApp({super.key});

  @override
  State<DarkJigsawApp> createState() => _DarkJigsawAppState();
}

class _DarkJigsawAppState extends State<DarkJigsawApp> {
  int _currentThemeIndex = 0;

  void _changeTheme(int index) => setState(() => _currentThemeIndex = index);

  @override
  Widget build(BuildContext context) {
    final theme = themes[_currentThemeIndex];
    final isWhite = theme.name == 'White & Mint';
    return MaterialApp(
      title: 'Jigsaw Puzzle',
      debugShowCheckedModeBanner: false,
      theme: isWhite
          ? ThemeData.light(useMaterial3: true)
          : ThemeData.dark(useMaterial3: true),
      home: Builder(
        builder: (context) {
          void startApp() {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomePage(
                  currentTheme: theme,
                  onThemeChange: _changeTheme,
                  currentThemeIndex: _currentThemeIndex,
                ),
              ),
            );
          }

          return WelcomeScreen(theme: theme, onStart: startApp);
        },
      ),
    );
  }
}

// ---------------------- WELCOME SCREEN ----------------------
class WelcomeScreen extends StatefulWidget {
  final PuzzleTheme theme;
  final VoidCallback onStart;

  const WelcomeScreen({super.key, required this.theme, required this.onStart});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.theme.background, widget.theme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Floating jigsaw pieces in welcome background
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    final size = MediaQuery.of(context).size;
                    return Stack(
                      children: List.generate(12, (index) {
                        final cols = [
                          Colors.redAccent,
                          Colors.blueAccent,
                          Colors.greenAccent,
                          Colors.orangeAccent,
                          Colors.purpleAccent,
                          Colors.tealAccent,
                        ];
                        final c = cols[index % cols.length];
                        final x =
                            (sin(_animController.value * 2 * pi + index) * 0.5 +
                                0.5) *
                            size.width;
                        final y =
                            (cos(_animController.value * 2 * pi + index * 1.1) *
                                    0.45 +
                                0.5) *
                            size.height;
                        final sz = 30.0 + (index % 4) * 10.0;
                        final angle =
                            (_animController.value * 2 * pi) *
                            (index.isEven ? 1 : -1) /
                            (4 + (index % 3));
                        return Positioned(
                          left: x - sz / 2,
                          top: y - sz / 2,
                          child: Opacity(
                            opacity: 0.16,
                            child: Transform.rotate(
                              angle: angle,
                              child: JigsawMini(color: c, size: sz),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Puzzle Master',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.name == 'White & Mint'
                            ? Colors.black87
                            : widget.theme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Arrange. Connect. Celebrate!',
                      style: TextStyle(
                        fontSize: 18,
                        color: widget.theme.accent.withAlpha(
                          (0.9 * 255).round(),
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 36),
                    ElevatedButton.icon(
                      onPressed: widget.onStart,
                      icon: const Icon(Icons.play_arrow),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Start Game',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PuzzleTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color accent;

  const PuzzleTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.accent,
  });
}

// Available themes
final List<PuzzleTheme> themes = [
  const PuzzleTheme(
    name: 'Dark Purple',
    primary: Colors.deepPurpleAccent,
    secondary: Color(0xFF2A2A72),
    background: Colors.black,
    accent: Colors.cyanAccent,
  ),
  const PuzzleTheme(
    name: 'Ocean Blue',
    primary: Color(0xFF0077BE),
    secondary: Color(0xFF1B4965),
    background: Color(0xFF0A1929),
    accent: Color(0xFF62B6CB),
  ),
  const PuzzleTheme(
    name: 'Forest Green',
    primary: Color(0xFF2D6A4F),
    secondary: Color(0xFF1B4332),
    background: Color(0xFF081C15),
    accent: Color(0xFF95D5B2),
  ),
  const PuzzleTheme(
    name: 'Sunset Orange',
    primary: Color(0xFFE85D04),
    secondary: Color(0xFF9D4EDD),
    background: Color(0xFF1A0F0F),
    accent: Color(0xFFFAA307),
  ),
  const PuzzleTheme(
    name: 'Rose Pink',
    primary: Color(0xFFD8315B),
    secondary: Color(0xFF3E1F47),
    background: Color(0xFF1E1320),
    accent: Color(0xFFFFC8DD),
  ),
  const PuzzleTheme(
    name: 'Midnight Blue',
    primary: Color(0xFF4361EE),
    secondary: Color(0xFF3F37C9),
    background: Color(0xFF0D1B2A),
    accent: Color(0xFF7209B7),
  ),
  const PuzzleTheme(
    name: 'White & Mint',
    primary: Color(0xFF00BCD4),
    secondary: Color(0xFF26C6DA),
    background: Color(0xFFFFFFFF),
    accent: Color(0xFF00897B),
  ),
];

// History entry model
class HistoryEntry {
  final String imageName;
  final int rows;
  final int cols;
  final int timeSeconds;
  final int score;
  final DateTime completedAt;

  HistoryEntry({
    required this.imageName,
    required this.rows,
    required this.cols,
    required this.timeSeconds,
    required this.score,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'imageName': imageName,
    'rows': rows,
    'cols': cols,
    'timeSeconds': timeSeconds,
    'score': score,
    'completedAt': completedAt.toIso8601String(),
  };
}

// Level configuration model
class GameLevel {
  final int levelNumber;
  final String imageAsset;
  final List<int> gridSizes; // e.g. [4,5,6]
  final Map<int, int> gridScores; // score per grid size
  final Map<int, int> gridTimers; // timer per grid size (seconds)
  final int requiredScore; // total required to unlock next level
  bool unlocked;
  Map<int, bool> completedGrids; // gridSize -> completed

  GameLevel({
    required this.levelNumber,
    required this.imageAsset,
    required this.gridSizes,
    required this.gridScores,
    required this.gridTimers,
    required this.requiredScore,
    this.unlocked = false,
    Map<int, bool>? completedGrids,
  }) : completedGrids = completedGrids ?? {for (var s in gridSizes) s: false};

  // Sum of points obtained in this level
  int get currentScore {
    var sum = 0;
    for (var e in completedGrids.entries) {
      if (e.value) sum += gridScores[e.key] ?? 0;
    }
    return sum;
  }

  // Fully completed when all grids done and requiredScore reached
  bool get isFullyCompleted {
    final allDone =
        completedGrids.values.isNotEmpty &&
        completedGrids.values.every((v) => v);
    return allDone && currentScore >= requiredScore;
  }

  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'imageAsset': imageAsset,
    'gridSizes': gridSizes,
    'gridScores': gridScores.map((k, v) => MapEntry(k.toString(), v)),
    'gridTimers': gridTimers.map((k, v) => MapEntry(k.toString(), v)),
    'requiredScore': requiredScore,
    'unlocked': unlocked,
    'completedGrids': completedGrids.map((k, v) => MapEntry(k.toString(), v)),
  };

  static GameLevel fromJson(Map<String, dynamic> json) {
    final gridSizes = (json['gridSizes'] as List<dynamic>).cast<int>();
    final gridScoresRaw = (json['gridScores'] as Map<String, dynamic>?) ?? {};
    final gridTimersRaw = (json['gridTimers'] as Map<String, dynamic>?) ?? {};
    final completedRaw =
        (json['completedGrids'] as Map<String, dynamic>?) ?? {};

    final gridScores = <int, int>{};
    final gridTimers = <int, int>{};
    final completed = <int, bool>{};
    for (var k in gridScoresRaw.keys) {
      gridScores[int.parse(k)] = gridScoresRaw[k] as int;
    }
    for (var k in gridTimersRaw.keys) {
      gridTimers[int.parse(k)] = gridTimersRaw[k] as int;
    }
    for (var k in completedRaw.keys) {
      completed[int.parse(k)] = completedRaw[k] as bool;
    }

    return GameLevel(
      levelNumber: json['levelNumber'] as int,
      imageAsset: json['imageAsset'] as String,
      gridSizes: gridSizes,
      gridScores: gridScores,
      gridTimers: gridTimers,
      requiredScore: json['requiredScore'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      completedGrids: completed.isEmpty ? null : completed,
    );
  }
}

// Small jigsaw mini widget used in headers
class JigsawMini extends StatelessWidget {
  final Color color;
  final double size;
  const JigsawMini({super.key, this.color = Colors.redAccent, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MiniJigsawPainter(color),
    );
  }
}

class _MiniJigsawPainter extends CustomPainter {
  final Color color;
  _MiniJigsawPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;
    final tab = w * 0.28;

    path.moveTo(0, h * 0.2);
    path.lineTo(0, h * 0.8);
    path.quadraticBezierTo(0, h, tab, h);
    path.lineTo(w * 0.4, h);
    path.arcToPoint(
      Offset(w * 0.6, h),
      radius: Radius.circular(tab),
      clockwise: false,
    );
    path.lineTo(w - tab, h);
    path.quadraticBezierTo(w, h, w, h * 0.8);
    path.lineTo(w, h * 0.2);
    path.quadraticBezierTo(w, 0, w - tab, 0);
    path.lineTo(w * 0.6, 0);
    path.arcToPoint(
      Offset(w * 0.4, 0),
      radius: Radius.circular(tab),
      clockwise: false,
    );
    path.lineTo(tab, 0);
    path.quadraticBezierTo(0, 0, 0, h * 0.2);
    path.close();

    canvas.drawShadow(path, Colors.black26, 3, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------- HOME PAGE ----------------------
class HomePage extends StatefulWidget {
  final PuzzleTheme currentTheme;
  final Function(int) onThemeChange;
  final int currentThemeIndex;

  const HomePage({
    super.key,
    required this.currentTheme,
    required this.onThemeChange,
    required this.currentThemeIndex,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PageController controller = PageController();
  int _currentPageIndex = 0;
  late final AnimationController _headerController;
  late PuzzleTheme activeTheme;
  late int activeThemeIndex;
  String? selectedAsset;
  Uint8List? selectedBytes;
  bool selectedViaSaved = false;
  bool showSavedGrid = false;
  bool showLevelsExpanded = false; // For Play Levels section
  bool enhancedLook = false;
  bool imageSelected = false;
  bool gridChosen = false;
  int selectedRows = 4;
  int selectedCols = 4;
  bool playLevelMode = false; // true if Play Levels flow is active
  bool _hasSavedPuzzle = false;
  final List<int> _options = [4, 5, 6, 7, 8];
  bool soundEnabled = true;
  List<HistoryEntry> history = [];
  int totalScore = 0;
  List<Uint8List> savedPictures = [];
  bool showingSavedPictures = false;
  List<GameLevel> gameLevels = [];
  GameLevel? currentLevel; // Track which level is being played
  int? currentLevelGridSize; // Track which grid size for multi-grid levels

  final List<String> images = [
    'assets/puzzle1.png',
    'assets/puzzle2.png',
    'assets/puzzle3.png',
    'assets/puzzle4.png',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    // initialize local theme state so HomePage can react to theme changes
    activeTheme = widget.currentTheme;
    activeThemeIndex = widget.currentThemeIndex;
    _initializeLevels();
    _loadLevels();
    _loadHistory();
    _loadScore();
    _loadSavedPictures();
    _loadSavedPuzzleState();
  }

  Future<void> _loadSavedPuzzleState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('saved_puzzle_state');
      if (s == null) return;
      final map = jsonDecode(s) as Map<String, dynamic>;
      final imgType = map['imageType'] as String? ?? 'asset';
      if (imgType == 'file') {
        final path = map['imageFilePath'] as String?;
        if (path != null) {
          final f = File(path);
          if (await f.exists()) {
            final bytes = await f.readAsBytes();
            setState(() {
              selectedBytes = bytes;
              selectedAsset = null;
              selectedViaSaved = true;
              imageSelected = true;
              selectedRows = map['rows'] as int? ?? selectedRows;
              selectedCols = map['cols'] as int? ?? selectedCols;
              showSavedGrid = true;
              _hasSavedPuzzle = true;
            });
          }
        }
      } else {
        final asset = map['imageAsset'] as String?;
        if (asset != null) {
          setState(() {
            selectedAsset = asset;
            selectedBytes = null;
            selectedViaSaved = false;
            imageSelected = true;
            selectedRows = map['rows'] as int? ?? selectedRows;
            selectedCols = map['cols'] as int? ?? selectedCols;
            showSavedGrid = true;
            _hasSavedPuzzle = true;
          });
        }
      }
      // If we loaded a saved puzzle, navigate to the Puzzle page so it can restore
      if (_hasSavedPuzzle) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    } catch (e) {
      developer.log('Failed to load saved puzzle state: $e');
    }
  }

  void _initializeLevels() {
    // Use images from the assets/themes folder for level images.
    final themeImages = const [
      'assets/themes/animal1.png',
      'assets/themes/animal2.png',
      'assets/themes/architecture1.png',
      'assets/themes/architecture2.png',
      'assets/themes/beach1.png',
      'assets/themes/beach2.png',
      'assets/themes/nature1.png',
      'assets/themes/nature2.png',
      'assets/themes/night1.png',
      'assets/themes/night2.png',
    ];
    // Per-level configuration following requested spec
    final configs = <Map<String, dynamic>>[
      // Level 1
      {
        'gridSizes': [4],
        'scores': {4: 14},
        'timers': {4: 100},
        'required': 14,
      },
      // Level 2
      {
        'gridSizes': [4, 5],
        'scores': {4: 12, 5: 13},
        'timers': {4: 100, 5: 150},
        'required': 25,
      },
      // Level 3
      {
        'gridSizes': [4, 5, 6],
        'scores': {4: 10, 5: 12, 6: 14},
        'timers': {4: 100, 5: 150, 6: 210},
        'required': 36,
      },
      // Level 4
      {
        'gridSizes': [5, 6, 7],
        'scores': {5: 12, 6: 14, 7: 16},
        'timers': {5: 150, 6: 210, 7: 260},
        'required': 42,
      },
      // Level 5
      {
        'gridSizes': [4, 5, 6, 7],
        'scores': {4: 10, 5: 12, 6: 14, 7: 14},
        'timers': {4: 100, 5: 150, 6: 210, 7: 260},
        'required': 50,
      },
      // Level 6
      {
        'gridSizes': [5, 6, 7, 8],
        'scores': {5: 12, 6: 14, 7: 16, 8: 16},
        'timers': {5: 150, 6: 210, 7: 260, 8: 320},
        'required': 58,
      },
      // Level 7
      {
        'gridSizes': [6, 7, 8],
        'scores': {6: 18, 7: 21, 8: 21},
        'timers': {6: 210, 7: 260, 8: 320},
        'required': 60,
      },
      // Level 8
      {
        'gridSizes': [5, 6, 7, 8],
        'scores': {5: 12, 6: 14, 7: 18, 8: 18},
        'timers': {5: 150, 6: 210, 7: 260, 8: 320},
        'required': 62,
      },
      // Level 9
      {
        'gridSizes': [6, 7, 8],
        'scores': {6: 18, 7: 22, 8: 24},
        'timers': {6: 210, 7: 260, 8: 320},
        'required': 64,
      },
      // Level 10
      {
        'gridSizes': [7, 8],
        'scores': {7: 34, 8: 36},
        'timers': {7: 260, 8: 320},
        'required': 70,
      },
    ];

    gameLevels = List.generate(themeImages.length, (i) {
      final cfg = configs[i];
      final levelNum = i + 1;
      return GameLevel(
        levelNumber: levelNum,
        imageAsset: themeImages[i],
        gridSizes: (cfg['gridSizes'] as List).cast<int>(),
        gridScores: Map<int, int>.from(cfg['scores'] as Map),
        gridTimers: Map<int, int>.from(cfg['timers'] as Map),
        requiredScore: cfg['required'] as int,
        unlocked: i == 0,
      );
    });
  }

  Future<void> _loadLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final levelsJson = prefs.getStringList('game_levels') ?? [];
    if (levelsJson.isEmpty) {
      // First time: save initial state
      await _saveLevels();
      return;
    }
    setState(() {
      gameLevels = levelsJson
          .map((json) {
            try {
              return GameLevel.fromJson(
                jsonDecode(json) as Map<String, dynamic>,
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<GameLevel>()
          .toList();
    });
  }

  Future<void> _saveLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final levelsJson = gameLevels.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList('game_levels', levelsJson);
  }

  Future<void> _updateLevelsAfterCompletion() async {
    // Determine levels that become unlocked now
    final newlyUnlocked = <int>[];
    for (int i = 0; i < gameLevels.length; i++) {
      final level = gameLevels[i];
      if (level.isFullyCompleted && i + 1 < gameLevels.length) {
        if (!gameLevels[i + 1].unlocked) {
          gameLevels[i + 1].unlocked = true;
          newlyUnlocked.add(i + 1);
        }
      }
    }

    // Save updated levels
    await _saveLevels();

    // Show unlock celebration(s) for any newly unlocked levels
    if (mounted) {
      setState(() {});
      for (var idx in newlyUnlocked) {
        // small delay between multiple unlocks
        await Future.delayed(const Duration(milliseconds: 300));
        await _showLevelUnlockCelebration(idx + 1);
      }
    }
  }

  Future<void> _showLevelUnlockCelebration(int unlockedLevelNumber) async {
    final String effectText;
    final BuildContext dialogContext = context;
    switch (unlockedLevelNumber) {
      case 2:
        effectText = 'Level 2 Unlocked! 🔑✨';
        break;
      case 3:
        effectText = 'Level 3 Unlocked! 🚪🌈';
        break;
      case 4:
        effectText = 'Level 4 Unlocked! 🧩✨';
        break;
      case 5:
        effectText = 'Level 5 Unlocked! 🎉';
        break;
      case 6:
        effectText = 'Level 6 Unlocked! 🔓💥';
        break;
      case 7:
        effectText = 'Level 7 Unlocked! 🚀';
        break;
      case 8:
        effectText = 'Level 8 Unlocked! ✨';
        break;
      case 9:
        effectText = 'Level 9 Unlocked! 🏆';
        break;
      case 10:
        effectText = 'Level 10 Unlocked! 🥇';
        break;
      default:
        effectText = 'Level $unlockedLevelNumber Unlocked!';
    }

    // Play an unlock sound if available
    try {
      Sfx.play('assets/sounds/correct-6033.mp3');
    } catch (_) {}

    if (!mounted) return;
    final navigator = Navigator.of(dialogContext);
    await showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (dialogBuilderContext) {
        // Simple celebration: big text + confetti emojis
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted && navigator.canPop()) {
            navigator.pop();
          }
        });
        return AlertDialog(
          backgroundColor: activeTheme.background,
          content: SizedBox(
            height: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  effectText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: activeTheme.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: List.generate(
                    12,
                    (i) => Text(
                      ['🎉', '✨', '🔑', '🎊', '💥', '🌟'][i % 6],
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Ensure music stopped when home disposes
    try {
      Sfx.stopMusic();
    } catch (_) {}
    _headerController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Stop music when app is detached or paused (window closed / backgrounded)
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      try {
        Sfx.stopMusic();
      } catch (_) {}
    }
  }

  // Handle request to continue to the next grid within the same level
  Future<void> _handleRequestNextGrid() async {
    if (currentLevel == null) return;
    final level = currentLevel!;
    final sizes = level.gridSizes;
    final int currentSize = currentLevelGridSize ?? selectedRows;
    int currentIndex = sizes.indexOf(currentSize);
    int nextIndex = -1;
    // Find next grid after current one
    for (int i = currentIndex + 1; i < sizes.length; i++) {
      if (level.completedGrids[sizes[i]] != true) {
        nextIndex = i;
        break;
      }
    }
    // If none after, try from beginning
    if (nextIndex == -1) {
      for (int i = 0; i < sizes.length; i++) {
        if (level.completedGrids[sizes[i]] != true) {
          nextIndex = i;
          break;
        }
      }
    }
    if (nextIndex == -1) {
      // No more grids; finish level and return home
      setState(() {
        currentLevel = null;
        currentLevelGridSize = null;
      });
      await _updateLevelsAfterCompletion();
      controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    final nextSize = sizes[nextIndex];
    setState(() {
      selectedRows = nextSize;
      selectedCols = nextSize;
      currentLevelGridSize = nextSize;
      // Keep the same selected image (don't clear selectedBytes)
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('puzzle_history') ?? [];
    setState(() {
      history = historyJson
          .map((json) {
            try {
              final parts = json.split('&');
              final map = <String, String>{};
              for (var part in parts) {
                final kv = part.split('=');
                if (kv.length == 2) map[kv[0]] = kv[1];
              }
              return HistoryEntry(
                imageName: map['imageName'] ?? 'Unknown',
                rows: int.tryParse(map['rows'] ?? '4') ?? 4,
                cols: int.tryParse(map['cols'] ?? '4') ?? 4,
                timeSeconds: int.tryParse(map['timeSeconds'] ?? '0') ?? 0,
                score: int.tryParse(map['score'] ?? '0') ?? 0,
                completedAt:
                    DateTime.tryParse(map['completedAt'] ?? '') ??
                    DateTime.now(),
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<HistoryEntry>()
          .toList();
    });
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('total_score') ?? 0;
    if (!mounted) return;
    setState(() => totalScore = stored);
  }

  Future<void> _loadSavedPictures() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_pictures') ?? [];
    if (!mounted) return;
    setState(() {
      savedPictures = savedList
          .map((base64String) {
            try {
              final bytes = base64Decode(base64String);
              return bytes;
            } catch (e) {
              return null;
            }
          })
          .whereType<Uint8List>()
          .toList();
    });
  }

  Future<void> _showHistory() async {
    await _loadHistory();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: widget.currentTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: widget.currentTheme.primary, width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.currentTheme.primary.withAlpha(
                    (0.2 * 255).round(),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: widget.currentTheme.accent),
                    const SizedBox(width: 12),
                    const Text(
                      'Play History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 64,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No history yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final entry = history[index];
                          return Card(
                            color: widget.currentTheme.secondary.withAlpha(
                              (0.3 * 255).round(),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: widget.currentTheme.primary,
                                child: Icon(
                                  Icons.extension,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${entry.rows}×${entry.cols} Grid',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                'Score: ${entry.score} • ${formatSeconds(entry.timeSeconds)} • ${_formatDate(entry.completedAt)}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Icon(
                                Icons.check_circle,
                                color: widget.currentTheme.accent,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _takeCameraPhoto() async {
    try {
      // On web, fall back to gallery. On desktop (Windows) try native camera UI via `camera` plugin.
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera not supported on web — opening gallery instead',
              ),
            ),
          );
        }
        final picker = ImagePicker();
        final XFile? file = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            selectedBytes = bytes;
            selectedAsset = null;
            selectedViaSaved = false;
            imageSelected = true;
            gridChosen = false;
            showSavedGrid = true;
          });
        }
        return;
      }

      // If running on Windows, attempt to use the `camera` plugin native UI
      if (Platform.isWindows) {
        try {
          // Store navigator reference before any async call to avoid context issues
          final navigator = Navigator.of(context);
          // Navigate to the in-app camera capture page which uses camera plugin
          final bytes = await navigator.push<Uint8List?>(
            MaterialPageRoute(builder: (_) => const CameraCapturePage()),
          );
          if (bytes == null) return;
          if (mounted) {
            setState(() {
              selectedBytes = bytes;
              selectedAsset = null;
              selectedViaSaved = false;
              imageSelected = true;
              gridChosen = false;
              showSavedGrid = true;
            });
          }
          return;
        } catch (e) {
          developer.log('Windows camera capture failed: $e');
          // fall back to gallery below
        }
      }

      // Let image_picker handle permissions automatically
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          selectedBytes = bytes;
          selectedAsset = null;
          selectedViaSaved = false;
          imageSelected = true;
          gridChosen = false;
          showSavedGrid = true;
        });
      }
    } catch (e) {
      developer.log('Error taking camera photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _openGalleryDirectly() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          selectedBytes = bytes;
          selectedAsset = null;
          selectedViaSaved = false;
          imageSelected = true;
          gridChosen = false;
          showSavedGrid = true;
        });
      }
    } catch (e) {
      developer.log('Error opening gallery: $e');
    }
  }

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: activeTheme.background,
        title: const Text(
          'Choose Theme',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final selected = index == activeThemeIndex;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primary,
                  child: Icon(
                    selected ? Icons.check : Icons.palette,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  theme.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_circle, color: theme.accent)
                    : null,
                onTap: () {
                  // update local active theme so HomePage updates immediately
                  setState(() {
                    activeTheme = themes[index];
                    activeThemeIndex = index;
                  });
                  // also notify parent to keep global state in sync
                  widget.onThemeChange(index);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _startGame() {
    if (selectedAsset == null && selectedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      onPageChanged: (idx) => setState(() => _currentPageIndex = idx),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildHome(),
        if (selectedAsset != null || selectedBytes != null)
          PuzzlePage(
            imageAsset: selectedAsset ?? '',
            imageBytes: selectedBytes,
            rows: selectedRows,
            cols: selectedCols,
            soundEnabled: soundEnabled,
            currentTheme: activeTheme,
            isActive: _currentPageIndex == 1,
            levelMode: currentLevel != null,
            level: currentLevel,
            timeLimit: currentLevel?.gridTimers[selectedRows],
            onRequestNextGrid: _handleRequestNextGrid,
            // If HomePage detected a saved puzzle on startup, instruct PuzzlePage
            // to attempt restoration from SharedPreferences.
            restoreSaved: _hasSavedPuzzle,
            savedStateKey: 'saved_puzzle_state',
            onBack: () async {
              setState(() {
                currentLevel = null;
                currentLevelGridSize = null;
                // Reset image/grid selection to show "Select Picture" section again
                imageSelected = false;
                gridChosen = false;
                selectedAsset = null;
                selectedBytes = null;
                selectedViaSaved = false;
                showSavedGrid = false;
                showingSavedPictures = false;
              });
              // Update level states in case any were completed
              await _updateLevelsAfterCompletion();
              controller.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            onComplete: (scorePoints, timeSeconds) async {
              final imageName =
                  selectedAsset?.split('/').last ?? 'Custom Image';
              final entry = HistoryEntry(
                imageName: imageName,
                rows: selectedRows,
                cols: selectedCols,
                timeSeconds: timeSeconds,
                score: scorePoints,
                completedAt: DateTime.now(),
              );
              final prefs = await SharedPreferences.getInstance();
              final historyJson = prefs.getStringList('puzzle_history') ?? [];
              final jsonStr = entry
                  .toJson()
                  .entries
                  .map((e) => '${e.key}=${e.value}')
                  .join('&');
              historyJson.insert(0, jsonStr);
              await prefs.setStringList(
                'puzzle_history',
                historyJson.take(50).toList(),
              );
              await _loadHistory();
              await _loadScore();
              await _loadLevels();
            },
          ),
      ],
    );
  }

  Widget _buildHome() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jigsaw Puzzle"),
        centerTitle: true,
        backgroundColor: activeTheme.background,
        elevation: 4,
        actions: [
          IconButton(
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          IconButton(
            onPressed: () {
              _showThemePicker();
              // Trigger rebuild to update all theme colors
              setState(() {});
            },
            icon: const Icon(Icons.palette),
            tooltip: 'Change Theme',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [activeTheme.background, activeTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Play Regular Puzzle Section
              GestureDetector(
                onTap: () => setState(() {
                  playLevelMode = false;
                  showLevelsExpanded =
                      false; // Collapse levels when switching to regular
                  showSavedGrid = !showSavedGrid;
                }),
                child: Card(
                  color: activeTheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.photo, size: 32, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              'Play Regular Puzzle',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          (!playLevelMode && showSavedGrid)
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!playLevelMode && showSavedGrid) ...[
                const SizedBox(height: 12),
                if (showingSavedPictures) ...[
                  Card(
                    color: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Select Image:',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () => setState(
                                  () => showingSavedPictures = false,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Back'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: images.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedAsset = images[index];
                                    selectedBytes = null;
                                    selectedViaSaved = true;
                                    imageSelected = true;
                                    gridChosen = false;
                                    showingSavedPictures = false;
                                  });
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: selectedAsset == images[index]
                                          ? activeTheme.accent
                                          : Colors.grey.shade700,
                                      width: selectedAsset == images[index]
                                          ? 3
                                          : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      images[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Grid:',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (imageSelected || selectedBytes != null)
                                Expanded(child: _buildGridSelector())
                              else
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!showingSavedPictures || savedPictures.isEmpty) ...[
                  Card(
                    color: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (selectedBytes == null) ...[
                            Row(
                              children: [
                                Text(
                                  'Select Picture:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                // Gallery icon button
                                IconButton(
                                  onPressed: _openGalleryDirectly,
                                  icon: const Icon(Icons.photo_library),
                                  iconSize: 28,
                                  color: activeTheme.primary,
                                  tooltip: 'Gallery',
                                ),
                                // Saved pictures icon button
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showingSavedPictures = true;
                                    });
                                  },
                                  icon: const Icon(Icons.image),
                                  iconSize: 28,
                                  color: Colors.blueAccent,
                                  tooltip: 'Saved Pictures',
                                ),
                                // Camera icon button
                                IconButton(
                                  onPressed: _takeCameraPhoto,
                                  icon: const Icon(Icons.camera_alt),
                                  iconSize: 28,
                                  color: Colors.orangeAccent,
                                  tooltip: 'Camera',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (selectedViaSaved && selectedBytes != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 150,
                                  child: Image.memory(
                                    selectedBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Do not display a large preview for gallery-selected images.
                              // Keep the space compact so the grid selector appears immediately.
                              const SizedBox.shrink(),
                            ],
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Grid:',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (imageSelected || selectedBytes != null)
                                Expanded(child: _buildGridSelector())
                              else
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (imageSelected && gridChosen) ? 1.0 : 0.5,
                  child: ElevatedButton(
                    onPressed: (imageSelected && gridChosen)
                        ? _startGame
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: activeTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() {
                  playLevelMode = true;
                  showSavedGrid =
                      false; // Collapse regular puzzle when switching to levels
                  showLevelsExpanded = !showLevelsExpanded;
                }),
                child: Card(
                  color: activeTheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Play Levels',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          showLevelsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (playLevelMode && showLevelsExpanded)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Select a Level:',
                      style: TextStyle(
                        color: activeTheme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gameLevels.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (context, index) {
                        final level = gameLevels[index];
                        return _buildLevelCard(level);
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(GameLevel level) {
    final isLocked = !level.unlocked;
    final isCompleted = level.isFullyCompleted;
    final totalGrids = level.gridSizes.length;
    final completedCount = level.completedGrids.values.where((v) => v).length;
    final progressFraction = level.requiredScore > 0
        ? (level.currentScore / level.requiredScore).clamp(0.0, 1.0)
        : (totalGrids == 0 ? 0.0 : (completedCount / totalGrids));

    return GestureDetector(
      onTap: isLocked
          ? () => _showLevelLockedDialog(level)
          : () => _startLevel(level),
      child: Card(
        color: isCompleted
            ? Colors.green.shade800
            : isLocked
            ? Colors.grey.shade700
            : widget.currentTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCompleted
                ? Colors.greenAccent
                : widget.currentTheme.accent,
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Full-screen image background covering entire card
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: isLocked ? 0.4 : 1,
                  child: Image.asset(
                    level.imageAsset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            // Dark gradient overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha((0.7 * 255).round()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Info at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${level.levelNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isCompleted)
                      const Text(
                        '✓ Completed',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else ...[
                      Text(
                        'Progress: $completedCount/$totalGrids grids',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLocked ? Colors.grey : Colors.yellowAccent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${level.currentScore}/${level.requiredScore} pts',
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Lock icon overlay
            if (isLocked)
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.lock, color: Colors.white, size: 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLevelLockedDialog(GameLevel level) {
    final reqGrids = level.gridSizes.join(', ');
    final requirement =
        'Complete the required grids ($reqGrids) and earn at least ${level.requiredScore} points to unlock this level.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: activeTheme.background,
        title: Text(
          'Level ${level.levelNumber} Locked',
          style: TextStyle(color: activeTheme.accent),
        ),
        content: Text(
          requirement,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: activeTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _startLevel(GameLevel level) {
    // Determine which grid size to start: choose next incomplete grid if any,
    // otherwise default to the first available size.
    int gridSize = level.gridSizes.first;
    for (var s in level.gridSizes) {
      if (!(level.completedGrids[s] ?? false)) {
        gridSize = s;
        break;
      }
    }

    // Start a level: set both selectedRows and selectedCols to gridSize
    setState(() {
      currentLevel = level;
      selectedAsset = level.imageAsset;
      selectedBytes = null;
      selectedRows = gridSize;
      selectedCols = gridSize;
      imageSelected = true;
      gridChosen = true;
    });

    controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildGridSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        if (narrow) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedRows,
                dropdownColor: widget.currentTheme.background,
                style: TextStyle(
                  color: widget.currentTheme.name == 'White & Mint'
                      ? Colors.black87
                      : Colors.white,
                ),
                items: _options
                    .map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text('${n}x$n', style: TextStyle(fontSize: 16)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    selectedRows = v;
                    selectedCols = v;
                    gridChosen = true;
                  });
                },
              ),
            ],
          );
        } else {
          // Wide layout: use ToggleButtons
          return ToggleButtons(
            isSelected: _options.map((o) => o == selectedRows).toList(),
            onPressed: (i) {
              setState(() {
                selectedRows = _options[i];
                selectedCols = _options[i];
                gridChosen = true;
              });
            },
            color: widget.currentTheme.name == 'White & Mint'
                ? Colors.black54
                : Colors.white70,
            selectedColor: widget.currentTheme.name == 'White & Mint'
                ? widget.currentTheme.accent
                : widget.currentTheme.accent,
            fillColor: widget.currentTheme.primary.withAlpha(
              (0.25 * 255).round(),
            ),
            borderRadius: BorderRadius.circular(12),
            constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            children: _options
                .map(
                  (o) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text('${o}x$o'),
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }
}

// ---------------------- PUZZLE PAGE ----------------------
class PuzzlePage extends StatefulWidget {
  final String imageAsset;
  final Uint8List? imageBytes;
  final VoidCallback onBack;
  final Function(int, int) onComplete; // (score, timeSeconds)
  final bool isActive;
  final int rows;
  final int cols;
  final bool soundEnabled;
  final PuzzleTheme currentTheme;
  final bool levelMode; // true if playing a level
  final int? timeLimit; // time limit in seconds for level
  final GameLevel? level; // reference to the level being played
  final Future<void> Function()?
  onRequestNextGrid; // request next grid in level flow
  // If true, PuzzlePage will attempt to restore a previously-saved puzzle state
  // stored under `savedStateKey` in SharedPreferences.
  final bool restoreSaved;
  final String savedStateKey;

  const PuzzlePage({
    super.key,
    required this.imageAsset,
    this.imageBytes,
    required this.onBack,
    required this.onComplete,
    this.isActive = true,
    this.rows = 4,
    this.cols = 4,
    this.soundEnabled = true,
    required this.currentTheme,
    this.levelMode = false,
    this.timeLimit,
    this.level,
    this.onRequestNextGrid,
    this.restoreSaved = false,
    this.savedStateKey = 'saved_puzzle_state',
  });

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  int get rows => widget.rows;
  int get cols => widget.cols;
  double boardSize = 400; // Will be calculated dynamically

  bool loading = true;
  late ui.Image fullImage;
  List<JigsawPiece> pieces = []; // List of jigsaw pieces

  Timer? _timer;
  int elapsedSeconds = 0;
  bool paused = false;
  bool musicPlaying = false;
  int? bestTimeSeconds;
  int? _countdownSeconds;
  Timer? _countdownTimer;
  int? _levelTimeRemaining; // for level mode countdown

  // Scoring system
  int score = 0;
  final Map<int, int> _pieceLastPlacedTime =
      {}; // Track when each piece was last placed

  // Animation overlay for correct placement
  final List<AnimatedSticker> _stickers = [];

  @override
  void initState() {
    super.initState();
    _preparePuzzle();
  }

  @override
  void didUpdateWidget(covariant PuzzlePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If user navigates away from the puzzle page, silently pause and stop music.
    if (oldWidget.isActive && !widget.isActive) {
      _silentPauseOnLeave();
    }
    // If user returns to the puzzle page, offer resume or exit if paused,
    // otherwise (fresh start) auto-play music if enabled.
    else if (!oldWidget.isActive && widget.isActive) {
      if (paused) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResumeOrExitDialog();
        });
      } else {
        if (widget.soundEnabled && !musicPlaying) {
          Sfx.playMusic('assets/sounds/music-for-puzzle-game-146738.mp3')
              .then((_) {
                if (!mounted) return;
                setState(() => musicPlaying = true);
              })
              .catchError((_) {});
        }
      }
    }
  }

  void _silentPauseOnLeave() {
    if (paused) return;
    _timer?.cancel();
    setState(() => paused = true);
    if (musicPlaying) {
      try {
        Sfx.stopMusic();
      } catch (_) {}
      setState(() => musicPlaying = false);
    }
    // Save current puzzle state so it can be resumed when app reopens
    _savePuzzleState();
  }

  void _startGameTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() {
        elapsedSeconds++;
        if (widget.levelMode && _levelTimeRemaining != null) {
          _levelTimeRemaining = _levelTimeRemaining! - 1;
        }
      });

      // Check if level time limit exceeded
      if (widget.levelMode &&
          _levelTimeRemaining != null &&
          _levelTimeRemaining! <= 0) {
        _timer?.cancel();
        if (musicPlaying) {
          try {
            Sfx.stopMusic();
          } catch (_) {}
          setState(() => musicPlaying = false);
        }
        _showLevelTimeOutDialog();
        return;
      }

      // Note: Puzzle completion is now handled by PuzzleBoard internally
      // We no longer check for completed status here
    });
  }

  void _showResumeOrExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.currentTheme.background,
        title: const Text('Game Paused', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You left the game. Resume where you left off or exit?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startCountdown();
            },
            child: Text(
              'Resume',
              style: TextStyle(color: widget.currentTheme.accent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Stop music and timers, then exit the app completely
              if (musicPlaying) {
                try {
                  Sfx.stopMusic();
                } catch (_) {}
                setState(() => musicPlaying = false);
              }
              _timer?.cancel();
              _countdownTimer?.cancel();
              // A short delay to allow UI to settle before closing
              Future.delayed(const Duration(milliseconds: 80), () {
                SystemNavigator.pop();
              });
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _preparePuzzle() async {
    setState(() {
      loading = true;
      elapsedSeconds = 0;
      score = 0;
      _pieceLastPlacedTime.clear();
    });

    try {
      // Load image
      final Uint8List bytes;
      if (widget.imageBytes != null) {
        bytes = widget.imageBytes!;
      } else {
        bytes = (await rootBundle.load(widget.imageAsset)).buffer.asUint8List();
      }
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      fullImage = frame.image;

      if (!mounted) return;

      // Generate jigsaw pieces with proper edges
      final generated = await JigsawGenerator.generateAsync(fullImage, rows, cols);
      
      // Convert JigsawPieceModel to JigsawPiece (old format) with jigsaw edges
      final List<JigsawPiece> jigsawPieces = [];
      for (final model in generated) {
        final piece = JigsawPiece(
          model.id,
          model.row,
          model.col,
          fullImage, // full image, piece will crop from srcRect
          hasTopTab: model.top == EdgeType.tab,
          hasRightTab: model.right == EdgeType.tab,
          hasBottomTab: model.bottom == EdgeType.tab,
          hasLeftTab: model.left == EdgeType.tab,
          srcRect: model.srcRect,
        );
        jigsawPieces.add(piece);
      }
      
      jigsawPieces.shuffle(Random());
      
      if (!mounted) return;
      setState(() {
        pieces = jigsawPieces;
        loading = false;
      });

      // Load best time from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final assetId = widget.imageBytes != null
          ? 'gallery_${widget.imageBytes!.lengthInBytes}'
          : widget.imageAsset;
      final key = '${assetId}_${rows}x${cols}_best';
      final loadedBest = prefs.getInt(key);
      if (mounted) {
        setState(() => bestTimeSeconds = loadedBest);
      }

      // If restoring saved state, load it
      if (widget.restoreSaved) {
        try {
          final s = prefs.getString(widget.savedStateKey);
          if (s != null) {
            final map = jsonDecode(s) as Map<String, dynamic>;
            final int savedRows = map['rows'] as int? ?? -1;
            final int savedCols = map['cols'] as int? ?? -1;
            if (savedRows == rows && savedCols == cols && mounted) {
              setState(() {
                elapsedSeconds = map['elapsedSeconds'] as int? ?? 0;
                score = map['score'] as int? ?? 0;
              });
              paused = true;
              _timer?.cancel();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showResumeOrExitDialog();
              });
            }
          }
        } catch (e) {
          developer.log('Failed to restore saved state: $e');
        }
      }

      if (mounted) {
        setState(() {
          paused = false;
          if (widget.levelMode && widget.timeLimit != null) {
            _levelTimeRemaining = widget.timeLimit;
          }
        });
      }

      _timer?.cancel();
      if (widget.levelMode) {
        _startCountdown();
      } else {
        _startGameTimer();
      }

      setState(() => musicPlaying = false);
      if (widget.isActive && widget.soundEnabled) {
        try {
          await Sfx.playMusic('assets/sounds/music-for-puzzle-game-146738.mp3');
          if (!mounted) return;
          setState(() => musicPlaying = true);
        } catch (_) {}
      }
    } catch (e) {
      developer.log('Error preparing puzzle: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }


  // Persist the current puzzle state so it can be resumed later.
  Future<void> _savePuzzleState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Note: PuzzleBoard handles piece state internally
      // We save only the game-level state (elapsed time, score)
      String? imageType = 'asset';
      String? imageAsset = widget.imageAsset;
      String? imageFilePath;
      // If image came from bytes (gallery/camera), write to file
      if (widget.imageBytes != null) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/saved_puzzle_image.png');
        await file.writeAsBytes(widget.imageBytes!);
        imageType = 'file';
        imageFilePath = file.path;
        imageAsset = null;
      }
      final map = {
        'imageType': imageType,
        'imageAsset': imageAsset,
        'imageFilePath': imageFilePath,
        'rows': rows,
        'cols': cols,
        'elapsedSeconds': elapsedSeconds,
        'score': score,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(widget.savedStateKey, jsonEncode(map));
    } catch (e) {
      developer.log('Failed to save puzzle state: $e');
    }
  }

  // Clear persisted puzzle state and delete stored image file if present.
  Future<void> _clearSavedPuzzleState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(widget.savedStateKey);
      if (s != null) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final path = map['imageFilePath'] as String?;
        if (path != null) {
          try {
            final f = File(path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
        await prefs.remove(widget.savedStateKey);
      }
    } catch (e) {
      developer.log('Failed to clear saved puzzle state: $e');
    }
  }

  String get timerText {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Completion is now handled by PuzzleBoard internally
  // bool get completed => pieces.every((p) => p.placed >= 0 && p.isCorrect);

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    if (widget.soundEnabled) {
      Sfx.stopMusic();
    }
    super.dispose();
  }

  void _pause() {
    if (paused) return;
    _timer?.cancel();
    setState(() => paused = true);
    if (widget.soundEnabled && musicPlaying) {
      Sfx.stopMusic();
      setState(() => musicPlaying = false);
    }
    _showPauseDialog();
    // Persist state when user pauses
    _savePuzzleState();
  }

  void _showPauseDialog() {
    developer.log('DEBUG: Showing pause dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.currentTheme.background,
        title: const Text('Game Paused', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Do you want to continue or exit?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startCountdown();
            },
            child: Text(
              'Resume',
              style: TextStyle(color: widget.currentTheme.accent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog when the user wants to go back to the Home/Select Image
  // Provides an option to continue playing or to go back and select an image again
  void _showSelectImageAgainDialog() {
    developer.log('DEBUG: Showing select-image-again dialog');
    // Ensure the game is paused and music stopped while the user decides
    _silentPauseOnLeave();
    // Pause briefly to ensure UI feedback
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.currentTheme.background,
        title: Text(
          'Game Options',
          style: TextStyle(
            color: widget.currentTheme.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Do you want to continue playing or select an image again?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Resume after a short countdown so the user can get ready
              _startCountdown();
            },
            child: Text(
              'Continue Playing',
              style: TextStyle(color: widget.currentTheme.accent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Debug log and stop music/timers before navigating back
              developer.log(
                'DEBUG: User chose Select Image Again — stopping music/timers and returning home',
              );
              if (musicPlaying) {
                try {
                  Sfx.stopMusic();
                  developer.log('DEBUG: Stopped music');
                } catch (_) {
                  developer.log('DEBUG: Error stopping music');
                }
                setState(() => musicPlaying = false);
              }
              _timer?.cancel();
              _countdownTimer?.cancel();
              // Clear saved puzzle state since user explicitly chose to reselect image
              _clearSavedPuzzleState();
              // Go back to home page (select image again)
              widget.onBack();
            },
            child: const Text(
              'Select Image Again',
              style: TextStyle(color: Colors.amberAccent),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog when the platform/system back (or close) is invoked.
  // Offers to continue playing or exit the app entirely.
  void _showExitConfirmDialog() {
    developer.log('DEBUG: Showing exit-confirm dialog');
    // Ensure the game is paused and music stopped while the user decides
    _silentPauseOnLeave();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.currentTheme.background,
        title: Text(
          'Exit Game',
          style: TextStyle(
            color: widget.currentTheme.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Do you want to continue playing or exit the app?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Resume after a short countdown so the user can get ready
              _startCountdown();
            },
            child: Text(
              'Continue Playing',
              style: TextStyle(color: widget.currentTheme.accent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              developer.log(
                'DEBUG: User chose Exit — stopping music/timers and exiting',
              );
              // Stop music and timers, then exit the app
              if (musicPlaying) {
                try {
                  Sfx.stopMusic();
                  developer.log('DEBUG: Stopped music');
                } catch (_) {
                  developer.log('DEBUG: Error stopping music');
                }
              }
              _timer?.cancel();
              _countdownTimer?.cancel();
              Future.delayed(const Duration(milliseconds: 80), () {
                SystemNavigator.pop();
              });
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _startCountdown() {
    setState(() => _countdownSeconds = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _countdownSeconds = _countdownSeconds! - 1);
      if (_countdownSeconds! <= 0) {
        _countdownTimer?.cancel();
        setState(() => _countdownSeconds = null);
        // Start the proper game timer after countdown
        if (widget.levelMode) {
          _startGameTimer();
        } else {
          _resume();
        }
      }
    });
  }

  void _resume() {
    if (!paused) return;
    _timer?.cancel();
    // Start the unified game timer (handles levelMode and regular mode)
    _startGameTimer();
    setState(() => paused = false);
    if (widget.soundEnabled) {
      try {
        if (!musicPlaying) {
          Sfx.playMusic('assets/sounds/music-for-puzzle-game-146738.mp3').then((
            _,
          ) {
            if (!mounted) return;
            setState(() => musicPlaying = true);
          });
        }
      } catch (_) {}
    }
  }

  void _showLevelCompletionDialog() {
    if (widget.level == null) return;

    final level = widget.level!;
    final withinTimeLimit = elapsedSeconds <= (widget.timeLimit ?? 999);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.currentTheme.background,
        title: Text(
          withinTimeLimit ? '🎉 Level Complete!' : '⏱ Time\'s Up!',
          style: TextStyle(color: widget.currentTheme.accent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Time: ${formatSeconds(elapsedSeconds)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Limit: ${formatSeconds(widget.timeLimit ?? 0)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (withinTimeLimit) ...[
              const SizedBox(height: 16),
              Text(
                '+${level.gridScores[cols] ?? 0} Points!',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progress: ${level.currentScore}/${level.requiredScore} pts',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'Try again to earn points!',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
        actions: [
          if (!withinTimeLimit)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _restartLevel();
              },
              child: const Text(
                'Play Again',
                style: TextStyle(color: Colors.amberAccent),
              ),
            )
          else ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Save level completion and award points
                await _completeLevelGrid();
                // If level now fully completed, show a short celebration then return home
                if (level.isFullyCompleted) {
                  await _showLocalLevelCelebration(level.levelNumber);
                  widget.onBack();
                  return;
                }
                // Otherwise, continue to the next grid in the same level
                _timer?.cancel();
                _countdownTimer?.cancel();
                if (widget.onRequestNextGrid != null) {
                  await widget.onRequestNextGrid!();
                } else {
                  // Fallback: return to home
                  widget.onBack();
                }
              },
              child: Text(
                'Continue',
                style: TextStyle(color: widget.currentTheme.accent),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Stop music and timers, then exit the app
                if (musicPlaying) {
                  try {
                    Sfx.stopMusic();
                  } catch (_) {}
                }
                _timer?.cancel();
                _countdownTimer?.cancel();
                Future.delayed(const Duration(milliseconds: 80), () {
                  SystemNavigator.pop();
                });
              },
              child: const Text(
                'Exit',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showLocalLevelCelebration(int levelNum) async {
    try {
      if (widget.soundEnabled) {
        Sfx.play('assets/sounds/music-for-puzzle-game-146738.mp3');
      }
    } catch (_) {}
    if (!mounted) return;
    final BuildContext dialogContext = context;
    final navigator = Navigator.of(dialogContext);
    await showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (dialogBuilderContext) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted && navigator.canPop()) navigator.pop();
        });
        return AlertDialog(
          backgroundColor: widget.currentTheme.background,
          content: SizedBox(
            height: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Level $levelNum Completed!',
                  style: TextStyle(
                    color: widget.currentTheme.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: List.generate(
                    12,
                    (i) => Text(
                      ['🎉', '✨', '🏆', '🎊', '🌟', '💥'][i % 6],
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLevelTimeOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.currentTheme.background,
        title: const Text(
          '⏱ Time\'s Up!',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Time: ${formatSeconds(elapsedSeconds)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Try again to complete the puzzle within the time limit!',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartLevel();
            },
            child: const Text(
              'Play Again',
              style: TextStyle(color: Colors.amberAccent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Stop music and timers, then exit the app
              if (musicPlaying) {
                try {
                  Sfx.stopMusic();
                } catch (_) {}
              }
              _timer?.cancel();
              _countdownTimer?.cancel();
              Future.delayed(const Duration(milliseconds: 80), () {
                SystemNavigator.pop();
              });
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeLevelGrid() async {
    if (widget.level == null) return;
    final level = widget.level!;
    final prefs = await SharedPreferences.getInstance();

    final gridSize = widget.cols;
    // Avoid double-awarding
    if (level.completedGrids[gridSize] == true) return;

    // Mark grid completed
    level.completedGrids[gridSize] = true;

    // Award points for this grid
    final gridPoints = level.gridScores[gridSize] ?? 0;
    final currentScore = prefs.getInt('total_score') ?? 0;
    await prefs.setInt('total_score', currentScore + gridPoints);

    developer.log(
      'Awarded $gridPoints points for ${gridSize}x$gridSize on level ${level.levelNumber}',
    );
  }

  void _restartLevel() {
    if (!mounted) return;
    setState(() {
      elapsedSeconds = 0;
      paused = false;
      _levelTimeRemaining = widget.timeLimit;
      score = 0;
      _pieceLastPlacedTime.clear();
    });
    _preparePuzzle();
  }

  void _restart() {
    if (widget.soundEnabled && musicPlaying) {
      try {
        Sfx.stopMusic();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => musicPlaying = false);
    _preparePuzzle();
  }

  void _handleCorrectPlacement(int pieceId) {
    // Track when the piece was placed
    _pieceLastPlacedTime[pieceId] = elapsedSeconds;

    // Award 1 point for correct placement within 5 seconds
    final timeSincePlaced =
        elapsedSeconds - (_pieceLastPlacedTime[pieceId] ?? 0);
    if (timeSincePlaced <= 5) {
      setState(() => score += 1);
    }

    // Show celebration sticker and message for ANY correct placement
    final messages = [
      '🎯 Great!',
      '⭐ Awesome!',
      '👏 Perfect!',
      '💯 Excellent!',
    ];
    final randomMsg = messages[Random().nextInt(messages.length)];
    final sticker = AnimatedSticker(
      left: 50 + Random().nextInt(200).toDouble(),
      top: 50 + Random().nextInt(200).toDouble(),
      emoji: randomMsg.split(' ')[0],
      message: randomMsg.split(' ')[1],
    );

    setState(() {
      _stickers.add(sticker);
      // Remove sticker after animation completes (1.5 seconds)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _stickers.removeWhere((s) => s == sticker));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Show exit confirmation when user presses back/system button
        if (!didPop) {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jigsaw Puzzle'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // When user taps the app back arrow, ask whether to select image again
              _showSelectImageAgainDialog();
            },
          ),
          actions: [
            IconButton(
              onPressed: () => paused ? _resume() : _pause(),
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            ),
            IconButton(onPressed: _restart, icon: const Icon(Icons.refresh)),
            IconButton(
              onPressed: () {
                if (musicPlaying) {
                  Sfx.stopMusic();
                  setState(() => musicPlaying = false);
                } else if (widget.soundEnabled) {
                  Sfx.playMusic(
                    'assets/sounds/music.mp3',
                  ).then((_) => setState(() => musicPlaying = true));
                }
              },
              icon: Icon(musicPlaying ? Icons.music_note : Icons.music_off),
            ),
          ],
          backgroundColor: widget.currentTheme.background,
        ),
        body: loading
            ? Center(
                child: CircularProgressIndicator(
                  color: widget.currentTheme.accent,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate the maximum board size so that all pieces fit perfectly for any grid size
                  // The board must be a square, and each cell must be at least 32px (for usability)
                  final double maxBoardWidth =
                      constraints.maxWidth - 32; // 16px margin each side
                  final double maxBoardHeight =
                      constraints.maxHeight -
                      320; // Reserve for timer, tray, etc
                  final double maxBoard = max(
                    120.0,
                    min(maxBoardWidth, maxBoardHeight),
                  );
                  // The board size should be the largest possible square that fits, but also ensures each cell is at least 32px
                  final double cellSize = max(
                    32.0,
                    (maxBoard / max(rows, cols)).floorToDouble(),
                  );
                  final double displayBoard = cellSize * max(rows, cols);
                  boardSize = displayBoard;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      // Timer and Score display
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: widget.currentTheme.primary.withAlpha(
                              (0.3 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_countdownSeconds == null)
                                Text(
                                  '⏱ $timerText',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.currentTheme.accent,
                                  ),
                                )
                              else
                                const SizedBox(width: 72),
                              if (widget.levelMode &&
                                  _levelTimeRemaining != null) ...[
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Limit',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                    Text(
                                      formatSeconds(_levelTimeRemaining!),
                                      style: TextStyle(
                                        color: _levelTimeRemaining! <= 10
                                            ? Colors.redAccent
                                            : Colors.yellowAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else
                                const SizedBox(width: 12),
                              if (!widget.levelMode)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Score',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                    Text(
                                      '$score',
                                      style: TextStyle(
                                        color: Colors.yellowAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(width: 12),
                              if (bestTimeSeconds != null && !widget.levelMode)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Best',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                    Text(
                                      formatSeconds(bestTimeSeconds!),
                                      style: const TextStyle(
                                        color: Colors.yellowAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox.shrink(),
                              if (paused) const SizedBox(width: 12),
                              if (paused)
                                const Text(
                                  '⏸ PAUSED',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Image preview
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: widget.imageBytes != null
                                      ? Image.memory(
                                          widget.imageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          widget.imageAsset,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Game board
                              Container(
                                width: boardSize,
                                height: boardSize,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: widget.currentTheme.primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.currentTheme.primary
                                          .withAlpha((0.5 * 255).round()),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Stack(
                                    children: [
                                      Container(
                                        color: Colors.black,
                                        child: IgnorePointer(
                                          ignoring:
                                              paused ||
                                              _countdownSeconds != null,
                                          child: _buildBoardWithSize(boardSize),
                                        ),
                                      ),
                                      // Animated stickers overlay
                                      ..._stickers.map(
                                        (sticker) => AnimatedStickerWidget(
                                          sticker: sticker,
                                          theme: widget.currentTheme,
                                        ),
                                      ),
                                      // Countdown overlay
                                      if (_countdownSeconds != null)
                                        Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(30),
                                            child: Text(
                                              '$_countdownSeconds',
                                              style: TextStyle(
                                                fontSize: 60,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    widget.currentTheme.accent,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Piece tray with jigsaw pieces
                      SizedBox(
                        height: (boardSize / cols) * 1.25,
                        child: IgnorePointer(
                          ignoring: paused || _countdownSeconds != null,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.currentTheme.primary.withAlpha(
                                  100,
                                ),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(100),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  _buildTrayWithSize(boardSize, trayScale: 1.0),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildBoardWithSize(double size) {
    final cellSize = size / cols;
    final tabOverflow = cellSize * 0.15; // Allow tabs to overflow
    
    return Stack(
      clipBehavior: Clip.none, // Allow pieces to overflow grid
      children: List.generate(rows * cols, (index) {
        final row = index ~/ cols;
        final col = index % cols;
        final piece = pieces.firstWhereOrNull((p) => p.placed == index);
        
        if (piece != null) {
          if (piece.isCorrect) {
            // Correctly placed: locked
            return Positioned(
              left: col * cellSize - tabOverflow,
              top: row * cellSize - tabOverflow,
              width: cellSize + tabOverflow * 2,
              height: cellSize + tabOverflow * 2,
              child: CustomPaint(
                painter: JigsawPiecePainter(
                  piece: piece,
                  image: fullImage,
                  isCorrect: piece.isCorrect,
                  highlightColor: widget.currentTheme.accent,
                  cellSize: cellSize,
                  thumbnail: false,
                ),
                size: Size(cellSize + tabOverflow * 2, cellSize + tabOverflow * 2),
              ),
            );
          } else {
            // Not correct: draggable and can be swapped
            return Positioned(
              left: col * cellSize - tabOverflow,
              top: row * cellSize - tabOverflow,
              width: cellSize + tabOverflow * 2,
              height: cellSize + tabOverflow * 2,
              child: Draggable<int>(
                data: piece.id,
                feedback: Material(
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: JigsawPiecePainter(
                      piece: piece,
                      image: fullImage,
                      isCorrect: piece.isCorrect,
                      highlightColor: widget.currentTheme.accent,
                      cellSize: cellSize,
                      thumbnail: false,
                    ),
                    size: Size(cellSize, cellSize),
                  ),
                ),
                childWhenDragging: Container(color: Colors.black26),
                child: DragTarget<int>(
                  builder: (context, candidateData, rejectedData) {
                    return CustomPaint(
                      painter: JigsawPiecePainter(
                        piece: piece,
                        image: fullImage,
                        isCorrect: piece.isCorrect,
                        highlightColor: widget.currentTheme.accent,
                        cellSize: cellSize,
                        thumbnail: false,
                      ),
                      size: Size(cellSize, cellSize),
                    );
                  },
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    final incomingId = details.data;
                    final incomingPiece = pieces.firstWhere(
                      (p) => p.id == incomingId,
                    );
                    setState(() {
                      final oldPlaced = piece.placed;
                      piece.placed = -1;
                      piece.isCorrect = false;
                      incomingPiece.placed = oldPlaced;
                      incomingPiece.isCorrect =
                          incomingPiece.row * cols + incomingPiece.col ==
                          oldPlaced;
                    });
                    if (incomingPiece.isCorrect && widget.soundEnabled) {
                      try {
                        Sfx.play('assets/sounds/correct-6033.mp3');
                      } catch (_) {}
                    }
                    if (incomingPiece.isCorrect) {
                      _handleCorrectPlacement(incomingPiece.id);
                    }
                  },
                ),
              ),
            );
          }
        } else {
          // Empty cell: accept a piece
          return Positioned(
            left: col * cellSize,
            top: row * cellSize,
            width: cellSize,
            height: cellSize,
            child: DragTarget<int>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: const BoxDecoration(color: Colors.black),
                );
              },
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                final incomingId = details.data;
                final incomingPiece = pieces.firstWhere(
                  (p) => p.id == incomingId,
                );
                setState(() {
                  incomingPiece.placed = index;
                  incomingPiece.isCorrect =
                      incomingPiece.row * cols + incomingPiece.col == index;
                });
                if (incomingPiece.isCorrect && widget.soundEnabled) {
                  try {
                    Sfx.play('assets/sounds/correct-6033.mp3');
                  } catch (_) {}
                }
                if (incomingPiece.isCorrect) {
                  _handleCorrectPlacement(incomingPiece.id);
                }
              },
            ),
          );
        }
      }),
    );
  }

  // Deprecated: Old board building kept for reference

  Widget _buildTrayWithSize(double boardSizeParam, {double trayScale = 1.0}) {
    final unplaced = pieces.where((p) => p.placed == -1).toList();
    final double pieceSize = boardSizeParam / cols;
    final double displaySize = pieceSize;
    final double gap = max(6.0, displaySize * 0.08);
    return Row(
      children: [
        for (final piece in unplaced)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gap / 2),
            child: SizedBox(
              width: displaySize,
              height: displaySize,
              child: Draggable<int>(
                data: piece.id,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: displaySize,
                    height: displaySize,
                    child: CustomPaint(
                      painter: JigsawPiecePainter(
                        piece: piece,
                        image: fullImage,
                        isCorrect: piece.isCorrect,
                        highlightColor: widget.currentTheme.accent,
                        cellSize: displaySize,
                        thumbnail: false,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.done, color: Colors.white54),
                  ),
                ),
                child: DragTarget<int>(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? widget.currentTheme.accent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(
                        painter: JigsawPiecePainter(
                          piece: piece,
                          image: fullImage,
                          isCorrect: piece.isCorrect,
                          highlightColor: widget.currentTheme.accent,
                          cellSize: displaySize,
                          thumbnail: false,
                        ),
                      ),
                    );
                  },
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    final incomingId = details.data;
                    final incomingPiece = pieces.firstWhere(
                      (p) => p.id == incomingId,
                    );
                    setState(() {
                      incomingPiece.placed = -1;
                      incomingPiece.isCorrect = false;
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------- Helpers ----------------------
extension FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E e) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

String formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// Animated sticker data class
class AnimatedSticker {
  final double left;
  final double top;
  final String emoji;
  final String message;

  AnimatedSticker({
    required this.left,
    required this.top,
    required this.emoji,
    required this.message,
  });
}

// Animated sticker widget with celebration animation
class AnimatedStickerWidget extends StatefulWidget {
  final AnimatedSticker sticker;
  final PuzzleTheme theme;

  const AnimatedStickerWidget({
    super.key,
    required this.sticker,
    required this.theme,
  });

  @override
  State<AnimatedStickerWidget> createState() => _AnimatedStickerWidgetState();
}

class _AnimatedStickerWidgetState extends State<AnimatedStickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -30.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.sticker.left - 50,
          top: widget.sticker.top + _slideAnimation.value - 50,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.theme.accent.withAlpha((0.9 * 255).round()),
                      widget.theme.primary.withAlpha((0.9 * 255).round()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.sticker.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.sticker.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class JigsawPiece {
  final int id;
  final int row;
  final int col;
  final ui.Image image;
  final Rect? srcRect; // Source rectangle in the full image
  int placed = -1;
  bool isCorrect = false;
  final bool hasTopTab;
  final bool hasRightTab;
  final bool hasBottomTab;
  final bool hasLeftTab;

  JigsawPiece(
    this.id,
    this.row,
    this.col,
    this.image, {
    this.srcRect,
    this.hasTopTab = false,
    this.hasRightTab = false,
    this.hasBottomTab = false,
    this.hasLeftTab = false,
  });
}

// Custom painter for realistic jigsaw pieces
class JigsawPiecePainter extends CustomPainter {
  final JigsawPiece piece;
  final ui.Image image;
  final bool isCorrect;
  final Color highlightColor;
  final double cellSize;
  final bool thumbnail;
  JigsawPiecePainter({
    required this.piece,
    required this.image,
    required this.isCorrect,
    required this.highlightColor,
    required this.cellSize,
    this.thumbnail = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If thumbnail mode is requested (tray preview), draw a simple rounded
    // rectangle thumbnail so pieces appear square and aligned in a grid.
    if (thumbnail) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      );
      canvas.save();
      canvas.clipRRect(rrect);
      try {
        final paint = Paint()..filterQuality = FilterQuality.high;
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
      } catch (e) {
        final paint = Paint()..color = Colors.grey;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      }
      canvas.restore();

      // subtle border for thumbnail
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black26
        ..strokeWidth = 1.0;
      canvas.drawRRect(rrect, borderPaint);
      return;
    }

    // Default: draw jigsaw-shaped piece
    final path = _createJigsawPath(Size(cellSize, cellSize));
    
    // If size is larger than cellSize, we have overflow space for tabs
    final tabOverflow = cellSize * 0.15;
    final isOverflowCanvas = (size.width - cellSize).abs() > 0.1;
    final Offset drawOffset = isOverflowCanvas ? Offset(tabOverflow, tabOverflow) : Offset.zero;

    // Draw shadow first
    final shadowPath = path.shift(drawOffset + const Offset(2, 2));
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(shadowPath, shadowPaint);

    // Clip to jigsaw shape
    canvas.save();
    canvas.clipPath(path.shift(drawOffset));

    // Draw the piece image
    try {
      final paint = Paint()..filterQuality = FilterQuality.high;
      // Draw ONLY the piece's portion of the full image
      if (piece.srcRect != null) {
        // Draw the cropped region from full image
        canvas.drawImageRect(
          image,
          piece.srcRect!,
          Rect.fromLTWH(drawOffset.dx, drawOffset.dy, cellSize, cellSize),
          paint,
        );
      } else {
        // Fallback: draw full image
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(drawOffset.dx, drawOffset.dy, cellSize, cellSize),
          paint,
        );
      }
    } catch (e) {
      // Fallback: draw solid color if image drawing fails
      final paint = Paint()..color = Colors.grey;
      canvas.drawRect(
        Rect.fromLTWH(drawOffset.dx, drawOffset.dy, cellSize, cellSize),
        paint,
      );
    }

    canvas.restore();

    // Draw jigsaw outline to show piece shape
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black87
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, outlinePaint);

    // Add white highlight for 3D effect
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withAlpha(100)
      ..strokeWidth = 0.8;
    canvas.drawPath(path, highlightPaint);
  }

  Path _createJigsawPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Tab/blank protrusion size
    final tabDepth = size.width * 0.12;
    final neckWidth = size.width * 0.08;
    
    // Start at top-left
    path.moveTo(0, 0);
    
    // TOP EDGE
    if (piece.hasTopTab) {
      // OUTWARD tab - protrudes upward out of the piece
      final midX = w / 2;
      path.lineTo(midX - neckWidth, 0);
      path.cubicTo(
        midX - neckWidth, -tabDepth * 0.3,
        midX - neckWidth * 0.5, -tabDepth,
        midX, -tabDepth * 0.9,
      );
      path.cubicTo(
        midX + neckWidth * 0.5, -tabDepth,
        midX + neckWidth, -tabDepth * 0.3,
        midX + neckWidth, 0,
      );
      path.lineTo(w, 0);
    } else {
      // INWARD blank - recesses downward into the piece
      final midX = w / 2;
      path.lineTo(midX - neckWidth, 0);
      path.cubicTo(
        midX - neckWidth, tabDepth * 0.3,
        midX - neckWidth * 0.5, tabDepth,
        midX, tabDepth * 0.9,
      );
      path.cubicTo(
        midX + neckWidth * 0.5, tabDepth,
        midX + neckWidth, tabDepth * 0.3,
        midX + neckWidth, 0,
      );
      path.lineTo(w, 0);
    }
    
    // RIGHT EDGE
    if (piece.hasRightTab) {
      // OUTWARD tab - protrudes rightward out of the piece
      final midY = h / 2;
      path.lineTo(w, midY - neckWidth);
      path.cubicTo(
        w + tabDepth * 0.3, midY - neckWidth,
        w + tabDepth, midY - neckWidth * 0.5,
        w + tabDepth * 0.9, midY,
      );
      path.cubicTo(
        w + tabDepth, midY + neckWidth * 0.5,
        w + tabDepth * 0.3, midY + neckWidth,
        w, midY + neckWidth,
      );
      path.lineTo(w, h);
    } else {
      // INWARD blank - recesses leftward into the piece
      final midY = h / 2;
      path.lineTo(w, midY - neckWidth);
      path.cubicTo(
        w - tabDepth * 0.3, midY - neckWidth,
        w - tabDepth, midY - neckWidth * 0.5,
        w - tabDepth * 0.9, midY,
      );
      path.cubicTo(
        w - tabDepth, midY + neckWidth * 0.5,
        w - tabDepth * 0.3, midY + neckWidth,
        w, midY + neckWidth,
      );
      path.lineTo(w, h);
    }
    
    // BOTTOM EDGE
    if (piece.hasBottomTab) {
      // OUTWARD tab - protrudes downward out of the piece
      final midX = w / 2;
      path.lineTo(midX + neckWidth, h);
      path.cubicTo(
        midX + neckWidth, h + tabDepth * 0.3,
        midX + neckWidth * 0.5, h + tabDepth,
        midX, h + tabDepth * 0.9,
      );
      path.cubicTo(
        midX - neckWidth * 0.5, h + tabDepth,
        midX - neckWidth, h + tabDepth * 0.3,
        midX - neckWidth, h,
      );
      path.lineTo(0, h);
    } else {
      // INWARD blank - recesses upward into the piece
      final midX = w / 2;
      path.lineTo(midX + neckWidth, h);
      path.cubicTo(
        midX + neckWidth, h - tabDepth * 0.3,
        midX + neckWidth * 0.5, h - tabDepth,
        midX, h - tabDepth * 0.9,
      );
      path.cubicTo(
        midX - neckWidth * 0.5, h - tabDepth,
        midX - neckWidth, h - tabDepth * 0.3,
        midX - neckWidth, h,
      );
      path.lineTo(0, h);
    }
    
    // LEFT EDGE
    if (piece.hasLeftTab) {
      // OUTWARD tab - protrudes leftward out of the piece
      final midY = h / 2;
      path.lineTo(0, midY + neckWidth);
      path.cubicTo(
        -tabDepth * 0.3, midY + neckWidth,
        -tabDepth, midY + neckWidth * 0.5,
        -tabDepth * 0.9, midY,
      );
      path.cubicTo(
        -tabDepth, midY - neckWidth * 0.5,
        -tabDepth * 0.3, midY - neckWidth,
        0, midY - neckWidth,
      );
      path.lineTo(0, 0);
    } else {
      // INWARD blank - recesses rightward into the piece
      final midY = h / 2;
      path.lineTo(0, midY + neckWidth);
      path.cubicTo(
        tabDepth * 0.3, midY + neckWidth,
        tabDepth, midY + neckWidth * 0.5,
        tabDepth * 0.9, midY,
      );
      path.cubicTo(
        tabDepth, midY - neckWidth * 0.5,
        tabDepth * 0.3, midY - neckWidth,
        0, midY - neckWidth,
      );
      path.lineTo(0, 0);
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant JigsawPiecePainter oldDelegate) {
    return oldDelegate.piece.id != piece.id ||
        oldDelegate.isCorrect != isCorrect ||
        oldDelegate.cellSize != cellSize;
  }
}

// ---------------------- DEMO WIDGET ----------------------
class JigsawDemo extends StatelessWidget {
  const JigsawDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jigsaw Puzzle Demo')),
      body: Center(
        child: PuzzlePage(
          imageAsset: 'assets/puzzle1.png',
          imageBytes: null,
          rows: 4,
          cols: 4,
          soundEnabled: true,
          currentTheme: themes[0],
          onBack: () {},
          onComplete: (score, timeSeconds) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Puzzle Solved in ${formatSeconds(timeSeconds)}! Score: $score',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// You can use JigsawDemo() as a page or replace your home widget with it.

// ---------------------- CAMERA CAPTURE PAGE (Windows) ----------------------
class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      developer.log('Camera init error: $e');
    }
    if (mounted) setState(() => _initializing = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      developer.log('Camera capture failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Center(
        child: _initializing
            ? const CircularProgressIndicator()
            : (_controller == null || !_controller!.value.isInitialized)
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No camera available'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              )
            : Stack(
                children: [
                  CameraPreview(_controller!),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          onPressed: _capture,
                          child: const Icon(Icons.camera_alt),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
