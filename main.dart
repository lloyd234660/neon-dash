import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _background = Color(0xFF080B1B);
const _cyan = Color(0xFF51F6FF);
const _pink = Color(0xFFFF4DA6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = await PlayerProgress.load();
  runApp(NeonDashApp(progress: progress));
}

class NeonDashApp extends StatelessWidget {
  final PlayerProgress progress;

  const NeonDashApp({super.key, required this.progress});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Neon Dash',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _cyan,
            brightness: Brightness.dark,
            surface: const Color(0xFF11162B),
          ),
          useMaterial3: true,
        ),
        home: HomeScreen(progress: progress),
      );
}

class PlayerProgress extends ChangeNotifier {
  int coins = 0;
  int best = 0;
  String selectedRunner = 'pulse';
  final Set<String> runners = {'pulse'};
  final Set<String> upgrades = {};
  late SharedPreferences _prefs;

  static const runnerPrices = <String, int>{
    'pulse': 0,
    'nova': 180,
    'volt': 350,
    'orbit': 600,
  };
  static const runnerColors = <String, Color>{
    'pulse': _cyan,
    'nova': _pink,
    'volt': Color(0xFFFFD54F),
    'orbit': Color(0xFFB88CFF),
  };
  static const upgradePrices = <String, int>{
    'magnet': 250,
    'shield': 400,
    'multiplier': 500,
  };

  static Future<PlayerProgress> load() async {
    final progress = PlayerProgress();
    progress._prefs = await SharedPreferences.getInstance();
    progress.coins = progress._prefs.getInt('coins') ?? 0;
    progress.best = progress._prefs.getInt('best') ?? 0;
    progress.selectedRunner = progress._prefs.getString('runner') ?? 'pulse';
    progress.runners.addAll(progress._prefs.getStringList('runners') ?? []);
    progress.upgrades.addAll(progress._prefs.getStringList('upgrades') ?? []);
    if (!progress.runners.contains(progress.selectedRunner)) {
      progress.selectedRunner = 'pulse';
    }
    return progress;
  }

  Future<void> save() async {
    await _prefs.setInt('coins', coins);
    await _prefs.setInt('best', best);
    await _prefs.setString('runner', selectedRunner);
    await _prefs.setStringList('runners', runners.toList());
    await _prefs.setStringList('upgrades', upgrades.toList());
    notifyListeners();
  }

  Future<bool> buyRunner(String id) async {
    final price = runnerPrices[id];
    if (price == null || runners.contains(id) || coins < price) return false;
    coins -= price;
    runners.add(id);
    await save();
    return true;
  }

  Future<bool> buyUpgrade(String id) async {
    final price = upgradePrices[id];
    if (price == null || upgrades.contains(id) || coins < price) return false;
    coins -= price;
    upgrades.add(id);
    await save();
    return true;
  }
}

class HomeScreen extends StatefulWidget {
  final PlayerProgress progress;

  const HomeScreen({super.key, required this.progress});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool playing = false;
  int runCoins = 0;
  int score = 0;

  Future<void> finishRun(int earned, int finalScore) async {
    runCoins = earned;
    score = finalScore;
    widget.progress.coins += earned;
    if (finalScore > widget.progress.best) widget.progress.best = finalScore;
    await widget.progress.save();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.progress,
            builder: (context, _) => playing
                ? RunnerScreen(
                    progress: widget.progress,
                    onExit: () => setState(() => playing = false),
                    onGameOver: finishRun,
                  )
                : _menu(context),
          ),
        ),
      );

  Widget _menu(BuildContext context) => Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: CityPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: _cyan, size: 28),
                    const SizedBox(width: 8),
                    const Text('NEON DASH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const Spacer(),
                    _coinBadge(widget.progress.coins),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.directions_run, color: _cyan, size: 86),
                const SizedBox(height: 8),
                const Text('RUN THE NIGHT', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 10),
                Text('Best score  ${widget.progress.best}', style: const TextStyle(color: Colors.white70)),
                if (score > 0) ...[
                  const SizedBox(height: 12),
                  Text('Last run: $score  ·  +$runCoins coins', style: const TextStyle(color: _cyan)),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: 240,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => playing = true),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('PLAY'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 240,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopScreen(progress: widget.progress),
                      ),
                    ),
                    icon: const Icon(Icons.storefront),
                    label: const Text('RUNNER SHOP'),
                  ),
                ),
                const SizedBox(height: 22),
                const Text('TAP TO JUMP  ·  SWIPE DOWN TO SLIDE', style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1)),
                const Spacer(),
              ],
            ),
          ),
        ],
      );
}

class ShopScreen extends StatelessWidget {
  final PlayerProgress progress;

  const ShopScreen({super.key, required this.progress});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Runner Shop'),
          actions: [Padding(padding: const EdgeInsets.all(16), child: _coinBadge(progress.coins))],
        ),
        body: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('RUNNERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              for (final entry in PlayerProgress.runnerPrices.entries)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.directions_run, color: PlayerProgress.runnerColors[entry.key], size: 32),
                    title: Text(_runnerName(entry.key)),
                    subtitle: Text(progress.runners.contains(entry.key) ? 'Ready to run' : '${entry.value} coins'),
                    trailing: _shopAction(
                      owned: progress.runners.contains(entry.key),
                      selected: progress.selectedRunner == entry.key,
                      enough: progress.coins >= entry.value,
                      onBuy: () async {
                        final success = await progress.buyRunner(entry.key);
                        if (!success && context.mounted) _showInsufficient(context);
                      },
                      onSelect: () async {
                        progress.selectedRunner = entry.key;
                        await progress.save();
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text('UPGRADES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              for (final entry in PlayerProgress.upgradePrices.entries)
                Card(
                  child: ListTile(
                    leading: Icon(_upgradeIcon(entry.key), color: _cyan),
                    title: Text(_upgradeName(entry.key)),
                    subtitle: Text(progress.upgrades.contains(entry.key) ? 'Unlocked permanently' : '${entry.value} coins · permanent upgrade'),
                    trailing: progress.upgrades.contains(entry.key)
                        ? const Icon(Icons.check_circle, color: _cyan)
                        : FilledButton(
                            onPressed: progress.coins < entry.value
                                ? null
                                : () async {
                                    final success = await progress.buyUpgrade(entry.key);
                                    if (!success && context.mounted) _showInsufficient(context);
                                  },
                            child: const Text('BUY'),
                          ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Upgrades: magnet attracts nearby coins, shield blocks one crash per run, and multiplier boosts score.', style: TextStyle(color: Colors.white60)),
              ),
            ],
          ),
        ),
      );
}

Widget _shopAction({
  required bool owned,
  required bool selected,
  required bool enough,
  required VoidCallback onBuy,
  required VoidCallback onSelect,
}) {
  if (owned) {
    return selected
        ? const Chip(label: Text('SELECTED'))
        : TextButton(onPressed: onSelect, child: const Text('SELECT'));
  }
  return FilledButton(onPressed: enough ? onBuy : null, child: const Text('BUY'));
}

void _showInsufficient(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins yet. Keep running!')));
}

String _runnerName(String id) => switch (id) {
      'nova' => 'Nova',
      'volt' => 'Volt',
      'orbit' => 'Orbit',
      _ => 'Pulse',
    };

String _upgradeName(String id) => switch (id) {
      'magnet' => 'Coin Magnet',
      'shield' => 'One-hit Shield',
      'multiplier' => 'Score Multiplier',
      _ => id,
    };

IconData _upgradeIcon(String id) => switch (id) {
      'magnet' => Icons.auto_awesome,
      'shield' => Icons.shield,
      'multiplier' => Icons.trending_up,
      _ => Icons.star,
    };

Widget _coinBadge(int coins) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF191E35), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.circle, color: Color(0xFFFFD54F), size: 14),
        const SizedBox(width: 6),
        Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );

enum EntityKind { barrier, coins, drone }

class GameEntity {
  double x;
  final EntityKind kind;
  bool collected = false;

  GameEntity(this.x, this.kind);
}

class RunnerGame extends ChangeNotifier {
  final PlayerProgress progress;
  final math.Random _random = math.Random();
  final List<GameEntity> entities = [];
  double speed = 0.48;
  double spawnDistance = 0.4;
  double jumpY = 0;
  double jumpVelocity = 0;
  double slideTime = 0;
  double elapsed = 0;
  double distance = 0;
  int coins = 0;
  int score = 0;
  bool running = false;
  bool gameOver = false;
  bool shieldUsed = false;

  RunnerGame(this.progress);

  bool get sliding => slideTime > 0;

  void start() {
    entities.clear();
    speed = 0.48;
    spawnDistance = 0.45;
    jumpY = 0;
    jumpVelocity = 0;
    slideTime = 0;
    elapsed = 0;
    distance = 0;
    coins = 0;
    score = 0;
    shieldUsed = false;
    running = true;
    gameOver = false;
    notifyListeners();
  }

  void jump() {
    if (running && jumpY == 0 && !sliding) jumpVelocity = 1.55;
  }

  void slide() {
    if (running && jumpY == 0) slideTime = 0.7;
  }

  void update(double dt) {
    if (!running || dt <= 0) return;
    dt = dt.clamp(0, 0.05).toDouble();
    elapsed += dt;
    distance += speed * dt;
    speed = math.min(0.9, 0.48 + elapsed * 0.008).toDouble();
    score = (distance * 100 * (progress.upgrades.contains('multiplier') ? 1.5 : 1)).floor();

    if (jumpY > 0 || jumpVelocity > 0) {
      jumpY += jumpVelocity * dt;
      jumpVelocity -= 3.8 * dt;
      if (jumpY <= 0) {
        jumpY = 0;
        jumpVelocity = 0;
      }
    }
    if (slideTime > 0) slideTime = math.max(0, slideTime - dt).toDouble();

    spawnDistance -= speed * dt;
    if (spawnDistance <= 0) _spawnPattern();

    final magnet = progress.upgrades.contains('magnet');
    final iterator = entities.iterator;
    while (iterator.moveNext()) {
      final entity = iterator.current;
      entity.x -= speed * dt;
      if (entity.collected) continue;
      final nearPlayer = entity.x < 0.34 && entity.x > 0.12;
      if (entity.kind == EntityKind.coins &&
          (entity.x < 0.25 || (magnet && nearPlayer))) {
        entity.collected = true;
        coins++;
        continue;
      }
      if ((entity.kind == EntityKind.barrier || entity.kind == EntityKind.drone) &&
          entity.x < 0.28 &&
          entity.x > 0.14 &&
          !_avoids(entity.kind)) {
        if (progress.upgrades.contains('shield') && !shieldUsed) {
          shieldUsed = true;
          entity.collected = true;
        } else {
          running = false;
          gameOver = true;
        }
      }
    }
    entities.removeWhere((entity) => entity.x < -0.15 || entity.collected);
    notifyListeners();
  }

  bool _avoids(EntityKind kind) {
    if (kind == EntityKind.drone) return jumpY > 0.11;
    if (sliding) return true;
    return jumpY > 0.17;
  }

  void _spawnPattern() {
    final pick = _random.nextInt(5);
    if (pick == 0) {
      entities.add(GameEntity(1.12, EntityKind.drone));
    } else {
      entities.add(GameEntity(1.12, EntityKind.barrier));
    }
    final coinCount = 3 + _random.nextInt(3);
    for (var i = 0; i < coinCount; i++) {
      entities.add(GameEntity(1.34 + i * 0.075, EntityKind.coins));
    }
    spawnDistance = 0.55 + _random.nextDouble() * 0.42;
  }
}

class RunnerScreen extends StatefulWidget {
  final PlayerProgress progress;
  final VoidCallback onExit;
  final Future<void> Function(int coins, int score) onGameOver;

  const RunnerScreen({
    super.key,
    required this.progress,
    required this.onExit,
    required this.onGameOver,
  });

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> with SingleTickerProviderStateMixin {
  late final RunnerGame game = RunnerGame(widget.progress);
  late final Ticker ticker;
  Duration? previous;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    game.addListener(_changed);
    game.start();
    ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final old = previous;
    previous = elapsed;
    if (old != null) game.update((elapsed - old).inMicroseconds / 1000000);
    if (game.gameOver && !reported) {
      reported = true;
      widget.onGameOver(game.coins, game.score);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ticker.dispose();
    game.removeListener(_changed);
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: game.running ? game.jump : null,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 0) game.slide();
        },
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: GamePainter(game))),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: widget.onExit,
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  _coinBadge(game.coins),
                  const SizedBox(width: 12),
                  Text('${game.score}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (game.gameOver)
              Center(
                child: Card(
                  color: const Color(0xEE11162B),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('RUN OVER', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Text('Score  ${game.score}   ·   Coins  ${game.coins}'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            reported = false;
                            previous = null;
                            game.start();
                          },
                          icon: const Icon(Icons.replay),
                          label: const Text('RUN AGAIN'),
                        ),
                        TextButton(onPressed: widget.onExit, child: const Text('MAIN MENU')),
                      ],
                    ),
                  ),
                ),
              )
            else
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    game.elapsed < 5 ? 'TAP TO JUMP  ·  SWIPE DOWN TO SLIDE' : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, letterSpacing: 1),
                  ),
                ),
              ),
          ],
        ),
      );
}

class GamePainter extends CustomPainter {
  final RunnerGame game;

  GamePainter(this.game) : super(repaint: game);

  @override
  void paint(Canvas canvas, Size size) {
    const cityPainter = CityPainter();
    cityPainter.paint(canvas, size);
    final ground = size.height * 0.82;
    final scale = size.width;
    final glowPaint = Paint()
      ..color = _cyan.withValues(alpha: 0.35)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, ground), Offset(size.width, ground), glowPaint);
    final runnerColor = PlayerProgress.runnerColors[game.progress.selectedRunner] ?? _cyan;

    for (final entity in game.entities) {
      final x = entity.x * size.width;
      if (entity.kind == EntityKind.coins) {
        final y = ground - size.height * 0.13;
        final coinPaint = Paint()..color = const Color(0xFFFFD54F);
        canvas.drawCircle(Offset(x, y), scale * 0.018, coinPaint);
        canvas.drawCircle(Offset(x, y), scale * 0.025, Paint()..color = const Color(0x55FFD54F)..style = PaintingStyle.stroke..strokeWidth = 2);
      } else if (entity.kind == EntityKind.barrier) {
        final rect = Rect.fromLTWH(x, ground - size.height * 0.13, scale * 0.08, size.height * 0.13);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = _pink);
        canvas.drawRect(Rect.fromLTWH(x + rect.width * 0.18, rect.top + 6, rect.width * 0.18, rect.height - 12), Paint()..color = Colors.white.withValues(alpha: 0.55));
      } else {
        final center = Offset(x, ground - size.height * 0.22);
        canvas.drawCircle(center, scale * 0.045, Paint()..color = const Color(0xFFB88CFF));
        canvas.drawLine(center.translate(-scale * 0.06, 0), center.translate(scale * 0.06, 0), Paint()..color = _cyan..strokeWidth = 3);
      }
    }

    final playerX = size.width * 0.2;
    final playerHeight = game.sliding ? size.height * 0.065 : size.height * 0.14;
    final playerWidth = scale * 0.075;
    final bottom = ground - game.jumpY * size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(playerX, bottom - playerHeight, playerWidth, playerHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, Paint()..color = runnerColor);
    canvas.drawCircle(Offset(playerX + playerWidth * 0.68, bottom - playerHeight * 0.78), playerWidth * 0.11, Paint()..color = _background);
    canvas.drawLine(Offset(playerX + playerWidth * 0.15, bottom - playerHeight * 0.15), Offset(playerX - scale * 0.025, bottom), Paint()..color = runnerColor..strokeWidth = 4);
    if (game.progress.upgrades.contains('shield') && !game.shieldUsed) {
      canvas.drawCircle(
        Offset(playerX + playerWidth / 2, bottom - playerHeight / 2),
        playerHeight * 0.72,
        Paint()..color = _cyan.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => oldDelegate.game != game;
}

class CityPainter extends CustomPainter {
  const CityPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF101A3A), Color(0xFF080B1B), Color(0xFF180C2D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    final random = math.Random(7);
    final stars = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 36; i++) {
      canvas.drawCircle(Offset(random.nextDouble() * size.width, random.nextDouble() * size.height * 0.58), 1.3, stars);
    }
    final buildingPaint = Paint()..color = const Color(0xFF171D3C);
    final windowPaint = Paint()..color = _cyan.withValues(alpha: 0.4);
    var x = 0.0;
    var index = 0;
    while (x < size.width) {
      final width = size.width * (0.09 + (index % 3) * 0.035);
      final height = size.height * (0.2 + ((index * 17) % 4) * 0.055);
      final top = size.height * 0.82 - height;
      canvas.drawRect(Rect.fromLTWH(x, top, width, height), buildingPaint);
      for (double wx = x + 7; wx < x + width - 5; wx += 13) {
        for (double wy = top + 10; wy < size.height * 0.8; wy += 17) {
          canvas.drawRect(Rect.fromLTWH(wx, wy, 4, 6), windowPaint);
        }
      }
      x += width + 3;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CityPainter oldDelegate) => false;
}
