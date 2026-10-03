import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Обитель скорости — single-file MVP.
/// Зависимости: только Flutter SDK.
/// Камера, AI-распознавание и Bluetooth намеренно изолированы интерфейсами
/// и имеют локальные mock-реализации, чтобы файл собирался без внешних пакетов.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeedSanctuaryApp());
}

// ============================================================
// DOMAIN
// ============================================================

enum BodyType {
  sedan, hatchback, coupe, convertible, wagon, suv, crossover,
  pickup, van, supercar, hypercar, motorcycle,
}

enum Rarity { common, uncommon, rare, epic, legendary }

enum CarStatus { garaged, outside, stolen, inChase, recovered }

enum UpgradeType { engine, handling, body }

extension RarityX on Rarity {
  String get title => switch (this) {
    Rarity.common => 'Обычная',
    Rarity.uncommon => 'Необычная',
    Rarity.rare => 'Редкая',
    Rarity.epic => 'Эпическая',
    Rarity.legendary => 'Легендарная',
  };

  int get index => switch (this) {
    Rarity.common => 0,
    Rarity.uncommon => 1,
    Rarity.rare => 2,
    Rarity.epic => 3,
    Rarity.legendary => 4,
  };
}

extension BodyTypeX on BodyType {
  String get title => switch (this) {
    BodyType.sedan => 'Седан',
    BodyType.hatchback => 'Хэтчбек',
    BodyType.coupe => 'Купе',
    BodyType.convertible => 'Кабриолет',
    BodyType.wagon => 'Универсал',
    BodyType.suv => 'SUV',
    BodyType.crossover => 'Кроссовер',
    BodyType.pickup => 'Пикап',
    BodyType.van => 'Фургон',
    BodyType.supercar => 'Суперкар',
    BodyType.hypercar => 'Гиперкар',
    BodyType.motorcycle => 'Мотоцикл',
  };
}

class CarCard {
  CarCard({
    required this.id,
    required this.brand,
    required this.model,
    required this.generation,
    required this.bodyType,
    required this.color,
    required this.rarity,
    required this.baseValue,
    required this.currentValue,
    required this.speed,
    required this.handling,
    required this.durability,
    required this.maxSpeed,
    required this.maxHandling,
    required this.maxDurability,
    this.level = 1,
    this.experience = 0,
    this.damage = 0,
    this.photoPath,
    DateTime? discoveredAt,
    this.status = CarStatus.outside,
    this.garageSlot,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  final String id;
  String brand;
  String model;
  String generation;
  BodyType bodyType;
  String color;
  Rarity rarity;
  double baseValue;
  double currentValue;
  int speed;
  int handling;
  int durability;
  int maxSpeed;
  int maxHandling;
  int maxDurability;
  int level;
  int experience;
  double damage;
  String? photoPath;
  DateTime discoveredAt;
  CarStatus status;
  int? garageSlot;

  int get power => ((speed + handling + durability) / 3).round();

  int get xpToNext => 100 + ((level - 1) * (level - 1) * 60);

  double get repairCost {
    // Требование: ремонт — 25% стоимости восстановления повреждений.
    return currentValue * (damage / 100) * 0.25;
  }

  bool get fullyUpgraded =>
      speed >= maxSpeed &&
      handling >= maxHandling &&
      durability >= maxDurability;

  String get displayName => '$brand $model';

  CarCard copy() => CarCard(
    id: id,
    brand: brand,
    model: model,
    generation: generation,
    bodyType: bodyType,
    color: color,
    rarity: rarity,
    baseValue: baseValue,
    currentValue: currentValue,
    speed: speed,
    handling: handling,
    durability: durability,
    maxSpeed: maxSpeed,
    maxHandling: maxHandling,
    maxDurability: maxDurability,
    level: level,
    experience: experience,
    damage: damage,
    photoPath: photoPath,
    discoveredAt: discoveredAt,
    status: status,
    garageSlot: garageSlot,
  );
}

class PlayerState {
  double money = 2500;
  int xp = 0;
  int level = 1;
  int garageCapacity = 5;
  final List<CarCard> collection = [];
  final List<String> notifications = [];

  int get xpToNextLevel => 250 + (level - 1) * 150;

  int get freeGarageSlots =>
      garageCapacity - collection.where((c) => c.garageSlot != null).length;
}

// ============================================================
// SERVICES
// ============================================================

abstract interface class EconomyService {
  double get balance;
  bool canAfford(double amount);
  bool spend(double amount);
  void earn(double amount);
}

class LocalEconomyService implements EconomyService {
  LocalEconomyService(this.player);
  final PlayerState player;

  @override
  double get balance => player.money;

  @override
  bool canAfford(double amount) => amount >= 0 && player.money >= amount;

  @override
  bool spend(double amount) {
    if (!canAfford(amount)) return false;
    player.money -= amount;
    return true;
  }

  @override
  void earn(double amount) {
    if (amount > 0) player.money += amount;
  }
}

abstract interface class ExperienceService {
  int addXp(int amount);
  int xpForLevel(int level);
}

class LocalExperienceService implements ExperienceService {
  LocalExperienceService(this.player);
  final PlayerState player;

  @override
  int xpForLevel(int level) => 250 + (level - 1) * 150;

  @override
  int addXp(int amount) {
    if (amount <= 0) return 0;
    player.xp += amount;
    while (player.xp >= player.xpToNextLevel) {
      player.xp -= player.xpToNextLevel;
      player.level++;
    }
    return amount;
  }
}

class RarityScoreInput {
  const RarityScoreInput({
    required this.modelRarity,
    required this.brandPrestige,
    required this.value,
    required this.commonness,
    required this.colorUnusualness,
    required this.sportiness,
    required this.collectibility,
  });

  final double modelRarity;
  final double brandPrestige;
  final double value;
  final double commonness;
  final double colorUnusualness;
  final double sportiness;
  final double collectibility;
}

abstract interface class RarityService {
  Rarity calculate(RarityScoreInput input);
}

class DefaultRarityService implements RarityService {
  @override
  Rarity calculate(RarityScoreInput i) {
    // Все коэффициенты нормированы 0..100.
    // Распространённость инвертирована: чем меньше распространённость,
    // тем больше вклад в редкость.
    final score =
        i.modelRarity * .24 +
        i.brandPrestige * .16 +
        i.value * .16 +
        (100 - i.commonness) * .12 +
        i.colorUnusualness * .10 +
        i.sportiness * .10 +
        i.collectibility * .12;

    if (score >= 85) return Rarity.legendary;
    if (score >= 68) return Rarity.epic;
    if (score >= 50) return Rarity.rare;
    if (score >= 30) return Rarity.uncommon;
    return Rarity.common;
  }
}

abstract interface class VehicleRecognitionService {
  Future<RecognitionResult> recognize(String? imagePath);
}

class RecognitionResult {
  const RecognitionResult({
    required this.brand,
    required this.model,
    required this.generation,
    required this.bodyType,
    required this.color,
    required this.confidence,
  });

  final String brand;
  final String model;
  final String generation;
  final BodyType bodyType;
  final String color;
  final double confidence;
}

class MockVehicleRecognitionService implements VehicleRecognitionService {
  @override
  Future<RecognitionResult> recognize(String? imagePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const RecognitionResult(
      brand: 'BMW',
      model: 'M3',
      generation: 'G80',
      bodyType: BodyType.sedan,
      color: 'Frozen Grey',
      confidence: .91,
    );
  }
}

abstract interface class LicensePlateDetectionService {
  Future<bool> detect(String? imagePath);
}

class MockLicensePlateDetectionService implements LicensePlateDetectionService {
  @override
  Future<bool> detect(String? imagePath) async => true;
}

abstract interface class ImagePrivacyService {
  Future<String?> maskLicensePlate(String? imagePath);
}

class MockImagePrivacyService implements ImagePrivacyService {
  @override
  Future<String?> maskLicensePlate(String? imagePath) async {
    // Production implementation должна вернуть только обработанный файл.
    // Распознанный номер нигде не сохраняется.
    return imagePath;
  }
}

abstract interface class CameraService {
  Future<String?> takePhoto();
}

class MockCameraService implements CameraService {
  @override
  Future<String?> takePhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'mock://vehicle-photo';
  }
}

abstract interface class RaceNetworkService {
  Future<bool> discoverNearby();
  Future<bool> requestConnection(String peerId);
  Future<bool> confirmConnection(String peerId);
  Future<bool> send(String transactionId, Map<String, dynamic> payload);
}

class MockRaceNetworkService implements RaceNetworkService {
  @override
  Future<bool> discoverNearby() async => true;
  @override
  Future<bool> requestConnection(String peerId) async => true;
  @override
  Future<bool> confirmConnection(String peerId) async => true;
  @override
  Future<bool> send(String transactionId, Map<String, dynamic> payload) async =>
      true;
}

class MarketService {
  double sellPrice(CarCard car) => car.currentValue * .5;

  bool buy(PlayerState player, EconomyService economy, CarCard car) {
    if (!economy.spend(car.currentValue)) return false;
    player.collection.add(car);
    return true;
  }

  bool sell(PlayerState player, EconomyService economy, CarCard car) {
    if (!player.collection.contains(car)) return false;
    player.collection.remove(car);
    economy.earn(sellPrice(car));
    return true;
  }
}

class GarageService {
  bool park(PlayerState player, CarCard car) {
    if (!player.collection.contains(car)) return false;
    if (car.garageSlot != null) return true;
    if (player.freeGarageSlots <= 0) return false;
    final used = player.collection
        .where((c) => c.garageSlot != null)
        .map((c) => c.garageSlot!)
        .toSet();
    for (var i = 0; i < player.garageCapacity; i++) {
      if (!used.contains(i)) {
        car.garageSlot = i;
        car.status = CarStatus.garaged;
        return true;
      }
    }
    return false;
  }

  void remove(PlayerState player, CarCard car) {
    car.garageSlot = null;
    car.status = CarStatus.outside;
  }

  bool buySlot(PlayerState player, EconomyService economy) {
    final price = 1000 + (player.garageCapacity - 5) * 750;
    if (!economy.spend(price)) return false;
    player.garageCapacity++;
    return true;
  }
}

class UpgradeService {
  bool upgrade(CarCard car, UpgradeType type, EconomyService economy) {
    final current = switch (type) {
      UpgradeType.engine => car.speed,
      UpgradeType.handling => car.handling,
      UpgradeType.body => car.durability,
    };
    final max = switch (type) {
      UpgradeType.engine => car.maxSpeed,
      UpgradeType.handling => car.maxHandling,
      UpgradeType.body => car.maxDurability,
    };
    if (current >= max) return false;
    final cost = car.currentValue * .08 * car.level;
    if (!economy.spend(cost)) return false;

    switch (type) {
      case UpgradeType.engine:
        car.speed++;
      case UpgradeType.handling:
        car.handling++;
      case UpgradeType.body:
        car.durability++;
    }
    car.currentValue += cost * .15;
    return true;
  }
}

class RepairService {
  bool repair(CarCard car, EconomyService economy) {
    if (car.damage <= 0) return false;
    final cost = car.repairCost;
    if (!economy.spend(cost)) return false;
    car.damage = 0;
    return true;
  }
}

class ChaseService {
  bool canStart(CarCard car) =>
      car.status == CarStatus.stolen || car.status == CarStatus.inChase;

  void steal(CarCard car) {
    if (car.garageSlot == null) {
      car.status = CarStatus.stolen;
    }
  }

  void start(CarCard car) {
    if (car.status == CarStatus.stolen) car.status = CarStatus.inChase;
  }

  void recover(CarCard car) {
    car.status = CarStatus.recovered;
  }
}

class RaceService {
  final math.Random _random = math.Random();

  RaceResult race(CarCard player, {CarCard? opponent, bool stake = false}) {
    final p = _score(player);
    final o = _score(opponent ?? _botCar());
    final winner = p >= o ? player : oponentOrBot(o, opponent);
    return RaceResult(
      playerWon: identical(winner, player),
      playerScore: p,
      opponentScore: o,
      stake: stake,
      opponentCar: opponent,
    );
  }

  double _score(CarCard c) =>
      c.speed * .48 +
      c.handling * .34 +
      c.durability * .18 +
      _random.nextDouble() * 10;

  CarCard _botCar() => CarCard(
    id: 'bot',
    brand: 'Rival',
    model: 'Street',
    generation: 'AI',
    bodyType: BodyType.coupe,
    color: 'Red',
    rarity: Rarity.rare,
    baseValue: 3000,
    currentValue: 3000,
    speed: 65,
    handling: 62,
    durability: 58,
    maxSpeed: 80,
    maxHandling: 80,
    maxDurability: 80,
  );

  CarCard oponentOrBot(double score, CarCard? opponent) {
    if (opponent != null) return opponent;
    return _botCar()..speed = score.round();
  }
}

class RaceResult {
  const RaceResult({
    required this.playerWon,
    required this.playerScore,
    required this.opponentScore,
    required this.stake,
    this.opponentCar,
  });

  final bool playerWon;
  final double playerScore;
  final double opponentScore;
  final bool stake;
  final CarCard? opponentCar;
}

class TradeService {
  final Set<String> _lockedCards = {};

  bool lock(String cardId) => _lockedCards.add(cardId);
  void unlock(String cardId) => _lockedCards.remove(cardId);
  bool isLocked(String cardId) => _lockedCards.contains(cardId);

  bool atomicTrade({
    required PlayerState a,
    required PlayerState b,
    required CarCard cardA,
    required CarCard cardB,
    required bool confirmA,
    required bool confirmB,
  }) {
    if (!confirmA || !confirmB) return false;
    if (cardA.id == cardB.id) return false;
    if (!_lockedCards.add(cardA.id)) return false;
    if (!_lockedCards.add(cardB.id)) {
      _lockedCards.remove(cardA.id);
      return false;
    }

    try {
      if (!a.collection.contains(cardA) || !b.collection.contains(cardB)) {
        return false;
      }
      a.collection.remove(cardA);
      b.collection.remove(cardB);
      a.collection.add(cardB);
      b.collection.add(cardA);
      return true;
    } finally {
      _lockedCards.remove(cardA.id);
      _lockedCards.remove(cardB.id);
    }
  }
}

// ============================================================
// APP STATE
// ============================================================

class GameController extends ChangeNotifier {
  GameController() {
    _seed();
  }

  final PlayerState player = PlayerState();
  late final EconomyService economy = LocalEconomyService(player);
  final ExperienceService xp = LocalExperienceService;
  final RarityService rarity = DefaultRarityService();
  final VehicleRecognitionService recognition =
      MockVehicleRecognitionService();
  final LicensePlateDetectionService plate =
      MockLicensePlateDetectionService();
  final ImagePrivacyService privacy = MockImagePrivacyService();
  final CameraService camera = MockCameraService();
  final GarageService garage = GarageService();
  final MarketService market = MarketService();
  final UpgradeService upgrades = UpgradeService();
  final RepairService repairs = RepairService();
  final ChaseService chase = ChaseService();
  final RaceService races = RaceService();
  final RaceNetworkService network = MockRaceNetworkService();
  final TradeService trades = TradeService();

  RecognitionResult? pendingRecognition;
  String? pendingPhoto;
  bool recognizing = false;
  bool cameraBusy = false;

  void _seed() {
    final starter = _createCar(
      brand: 'Toyota',
      model: 'GR86',
      generation: 'ZN8',
      bodyType: BodyType.coupe,
      color: 'White',
      value: 32000,
      modelRarity: 45,
      brandPrestige: 45,
      commonness: 50,
      colorUnusualness: 15,
      sportiness: 75,
      collectibility: 60,
    );
    player.collection.add(starter);
    garage.park(player, starter);
    player.collection.add(_createCar(
      brand: 'Porsche',
      model: '911',
      generation: '992',
      bodyType: BodyType.coupe,
      color: 'Python Green',
      value: 125000,
      modelRarity: 82,
      brandPrestige: 92,
      commonness: 35,
      colorUnusualness: 80,
      sportiness: 92,
      collectibility: 88,
    ));
    player.collection.add(_createCar(
      brand: 'Nissan',
      model: 'GT-R',
      generation: 'R35',
      bodyType: BodyType.coupe,
      color: 'Midnight Blue',
      value: 95000,
      modelRarity: 72,
      brandPrestige: 76,
      commonness: 42,
      colorUnusualness: 50,
      sportiness: 94,
      collectibility: 90,
    ));
    notifyListeners();
  }

  CarCard _createCar({
    required String brand,
    required String model,
    required String generation,
    required BodyType bodyType,
    required String color,
    required double value,
    required double modelRarity,
    required double brandPrestige,
    required double commonness,
    required double colorUnusualness,
    required double sportiness,
    required double collectibility,
  }) {
    final r = rarity.calculate(RarityScoreInput(
      modelRarity: modelRarity,
      brandPrestige: brandPrestige,
      value: (value / 150000 * 100).clamp(0, 100),
      commonness: commonness,
      colorUnusualness: colorUnusualness,
      sportiness: sportiness,
      collectibility: collectibility,
    ));
    final base = (45 + sportiness * .35 + modelRarity * .2).round();
    return CarCard(
      id: '${DateTime.now().microsecondsSinceEpoch}-${player.collection.length}',
      brand: brand,
      model: model,
      generation: generation,
      bodyType: bodyType,
      color: color,
      rarity: r,
      baseValue: value,
      currentValue: value,
      speed: base.clamp(20, 90),
      handling: (45 + sportiness * .3 + collectibility * .15).round().clamp(20, 90),
      durability: (55 + brandPrestige * .15).round().clamp(20, 90),
      maxSpeed: 100,
      maxHandling: 100,
      maxDurability: 100,
    );
  }

  Future<void> takePhotoAndRecognize() async {
    if (cameraBusy) return;
    cameraBusy = true;
    notifyListeners();
    pendingPhoto = await camera.takePhoto();
    final hasPlate = await plate.detect(pendingPhoto);
    if (hasPlate) pendingPhoto = await privacy.maskLicensePlate(pendingPhoto);
    recognizing = true;
    notifyListeners();
    pendingRecognition = await recognition.recognize(pendingPhoto);
    recognizing = false;
    cameraBusy = false;
    notifyListeners();
  }

  void confirmRecognition() {
    final r = pendingRecognition;
    if (r == null) return;
    final value = switch (r.model) {
      'M3' => 70000.0,
      '911' => 125000.0,
      'GT-R' => 95000.0,
      _ => 22000.0,
    };
    final car = _createCar(
      brand: r.brand,
      model: r.model,
      generation: r.generation,
      bodyType: r.bodyType,
      color: r.color,
      value: value,
      modelRarity: 75,
      brandPrestige: 85,
      commonness: 35,
      colorUnusualness: 65,
      sportiness: 90,
      collectibility: 80,
    );
    player.collection.add(car);
    final reward = 100 + car.rarity.index * 150;
    economy.earn(250 + car.rarity.index * 250);
    xp.addXp(reward);
    player.notifications.insert(
      0,
      'Обнаружен ${car.displayName}: ${car.rarity.title}. +$reward XP',
    );
    pendingRecognition = null;
    pendingPhoto = null;
    notifyListeners();
  }

  bool park(CarCard car) {
    final ok = garage.park(player, car);
    notifyListeners();
    return ok;
  }

  void removeFromGarage(CarCard car) {
    garage.remove(player, car);
    notifyListeners();
  }

  bool buyGarageSlot() {
    final ok = garage.buySlot(player, economy);
    notifyListeners();
    return ok;
  }

  bool upgrade(CarCard car, UpgradeType type) {
    final ok = upgrades.upgrade(car, type, economy);
    notifyListeners();
    return ok;
  }

  bool repair(CarCard car) {
    final ok = repairs.repair(car, economy);
    notifyListeners();
    return ok;
  }

  RaceResult raceBot(CarCard car, {bool stake = false}) {
    final result = races.race(car, stake: stake);
    if (result.playerWon) {
      economy.earn(400 + car.rarity.index * 150);
      xp.addXp(100 + car.rarity.index * 80);
    } else {
      car.damage = (car.damage + 8).clamp(0, 100);
    }
    notifyListeners();
    return result;
  }

  void simulateTheft() {
    final candidates = player.collection
        .where((c) => c.garageSlot == null && c.status == CarStatus.outside)
        .toList();
    if (candidates.isEmpty) return;
    final car = candidates[math.Random().nextInt(candidates.length)];
    // Легендарная машина получает защитный шанс.
    if (car.rarity == Rarity.legendary && math.Random().nextDouble() < .75) {
      player.notifications.insert(0, 'Охрана спасла ${car.displayName} от угона.');
    } else {
      chase.steal(car);
      player.notifications.insert(
        0,
        'Угнали ${car.displayName}! Окно погони: 10 минут.',
      );
    }
    notifyListeners();
  }

  void startChase(CarCard car) {
    if (!chase.canStart(car)) return;
    chase.start(car);
    notifyListeners();
  }

  void winChase(CarCard car) {
    chase.recover(car);
    economy.earn(500);
    xp.addXp(250);
    car.damage = (car.damage + 5).clamp(0, 100);
    player.notifications.insert(0, '${car.displayName} возвращён. +250 XP');
    notifyListeners();
  }

  bool sell(CarCard car) {
    if (car.garageSlot != null) return false;
    if (trades.isLocked(car.id)) return false;
    final ok = market.sell(player, economy, car);
    notifyListeners();
    return ok;
  }
}

// ============================================================
// UI
// ============================================================

class SpeedSanctuaryApp extends StatefulWidget {
  const SpeedSanctuaryApp({super.key});

  @override
  State<SpeedSanctuaryApp> createState() => _SpeedSanctuaryAppState();
}

class _SpeedSanctuaryAppState extends State<SpeedSanctuaryApp> {
  late final GameController game;

  @override
  void initState() {
    super.initState();
    game = GameController();
  }

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Обитель скорости',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF090B10),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF4D00),
            brightness: Brightness.dark,
          ),
        ),
        home: HomeScreen(game: game),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.game});
  final GameController game;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(game: widget.game),
      CollectionScreen(game: widget.game),
      GarageScreen(game: widget.game),
      MarketScreen(game: widget.game),
      ProfileScreen(game: widget.game),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.speed), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Коллекция'),
          NavigationDestination(icon: Icon(Icons.garage), label: 'Гараж'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Рынок'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ОБИТЕЛЬ СКОРОСТИ',
                          style: Theme.of(context).textTheme.labelMedium),
                      Text('Твоя коллекция',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                Chip(label: Text('\$${game.player.money.toStringAsFixed(0)}')),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _HeroCard(game: game),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt,
                    title: 'Найти авто',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraScreen(game: game),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.sports_score,
                    title: 'Гонка',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RaceScreen(game: game),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _ActionButton(
              icon: Icons.directions_car_filled,
              title: 'Тест угона и погоня',
              onTap: () {
                game.simulateTheft();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChaseScreen(game: game)),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Text(
              'Недавние события',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        SliverList.builder(
          itemCount: math.min(game.player.notifications.length, 5),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.notifications_none),
            title: Text(game.player.notifications[i]),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final level = game.player.level;
    final xp = game.player.xp;
    final next = game.player.xpToNextLevel;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D222C), Color(0xFF10131A)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('УРОВЕНЬ $level',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: xp / next),
          ),
          const SizedBox(height: 8),
          Text('$xp / $next XP'),
          const SizedBox(height: 20),
          Text(
            '${game.player.collection.length}',
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900),
          ),
          const Text('автомобилей в коллекции'),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.game});
  final GameController game;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  Rarity? filter;

  @override
  Widget build(BuildContext context) {
    var cars = [...widget.game.player.collection];
    if (filter != null) {
      cars = cars.where((c) => c.rarity == filter).toList();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Коллекция')),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: filter == null,
                  onSelected: (_) => setState(() => filter = null),
                ),
                ...Rarity.values.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(r.title),
                      selected: filter == r,
                      onSelected: (_) => setState(() => filter = r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .78,
              ),
              itemCount: cars.length,
              itemBuilder: (_, i) => CarTile(
                car: cars[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarDetailsScreen(
                      game: widget.game,
                      car: cars[i],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CarTile extends StatelessWidget {
  const CarTile({super.key, required this.car, this.onTap});
  final CarCard car;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151922),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: CarShape(color: _colorFor(car.color)),
              ),
            ),
            Text(car.rarity.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
            Text(car.displayName,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${car.color} • ${car.power} power',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class CarShape extends StatelessWidget {
  const CarShape({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(160, 80),
      painter: _CarPainter(color),
    );
  }
}

class _CarPainter extends CustomPainter {
  _CarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final dark = Paint()..color = Colors.black87;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 28, size.width - 24, 35),
      const Radius.circular(14),
    );
    canvas.drawRRect(body, p);
    canvas.drawPath(
      Path()
        ..moveTo(42, 28)
        ..lineTo(60, 10)
        ..lineTo(105, 10)
        ..lineTo(125, 28)
        ..close(),
      p,
    );
    canvas.drawCircle(const Offset(45, 65), 11, dark);
    canvas.drawCircle(Offset(size.width - 45, 65), 11, dark);
    canvas.drawRect(const Rect.fromLTWH(66, 15, 34, 11), dark);
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) =>
      oldDelegate.color != color;
}

Color _colorFor(String name) {
  final s = name.toLowerCase();
  if (s.contains('red')) return Colors.red;
  if (s.contains('blue')) return Colors.blue;
  if (s.contains('green')) return Colors.greenAccent;
  if (s.contains('grey') || s.contains('gray')) return Colors.grey;
  if (s.contains('black')) return Colors.black;
  if (s.contains('white')) return Colors.white;
  return Colors.orange;
}

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final parked = game.player.collection.where((c) => c.garageSlot != null).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Гараж ${parked.length}/${game.player.garageCapacity}'),
        actions: [
          IconButton(
            tooltip: 'Купить место',
            onPressed: () {
              final ok = game.buyGarageSlot();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Место куплено' : 'Недостаточно денег')),
              );
            },
            icon: const Icon(Icons.add_business),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: .9,
        ),
        itemCount: game.player.garageCapacity,
        itemBuilder: (_, index) {
          final car = parked.where((c) => c.garageSlot == index).firstOrNull;
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131720),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: car == null
                ? const Center(child: Icon(Icons.add, size: 36))
                : InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarDetailsScreen(game: game, car: car),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CarShape(color: _colorFor(car.color)),
                          const SizedBox(height: 12),
                          Text(car.displayName),
                          Text(car.status.name),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class CarDetailsScreen extends StatelessWidget {
  const CarDetailsScreen({super.key, required this.game, required this.car});
  final GameController game;
  final CarCard car;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(car.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                CarShape(color: _colorFor(car.color)),
                const SizedBox(height: 18),
                Text(car.rarity.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${car.bodyType.title} • ${car.generation}'),
                Text(car.color),
                const SizedBox(height: 20),
                _Stat(label: 'Скорость', value: car.speed, max: car.maxSpeed),
                _Stat(label: 'Манёвренность', value: car.handling, max: car.maxHandling),
                _Stat(label: 'Прочность', value: car.durability, max: car.maxDurability),
                _Stat(label: 'Повреждения', value: car.damage.round(), max: 100),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (car.garageSlot == null)
            FilledButton.icon(
              onPressed: () {
                final ok = game.park(car);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Автомобиль в гараже' : 'Нет свободного места')),
                );
              },
              icon: const Icon(Icons.garage),
              label: const Text('Поставить в гараж'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => game.removeFromGarage(car),
              icon: const Icon(Icons.output),
              label: const Text('Выпустить из гаража'),
            ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: car.damage > 0
                ? () {
                    final ok = game.repair(car);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Автомобиль отремонтирован'
                            : 'Недостаточно денег'),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.build),
            label: Text('Ремонт • \$${car.repairCost.toStringAsFixed(0)}'),
          ),
          const SizedBox(height: 10),
          Text('Прокачка', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final type in UpgradeType.values)
            ListTile(
              leading: Icon(switch (type) {
                UpgradeType.engine => Icons.bolt,
                UpgradeType.handling => Icons.turn_right,
                UpgradeType.body => Icons.shield,
              }),
              title: Text(switch (type) {
                UpgradeType.engine => 'Двигатель',
                UpgradeType.handling => 'Манёвренность',
                UpgradeType.body => 'Кузов',
              }),
              trailing: IconButton(
                onPressed: car.fullyUpgraded
                    ? null
                    : () => game.upgrade(car, type),
                icon: const Icon(Icons.add_circle),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: car.garageSlot == null
                ? () {
                    final ok = game.sell(car);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Продано за \$${(car.currentValue * .5).toStringAsFixed(0)}'
                            : 'Продажа недоступна'),
                      ),
                    );
                    if (ok) Navigator.pop(context);
                  }
                : null,
            icon: const Icon(Icons.sell),
            label: Text(
              'Продать за \$${(car.currentValue * .5).toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text('$value/$max')],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: (value / max).clamp(0, 1)),
        ],
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.game});
  final GameController game;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    final r = widget.game.pendingRecognition;
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск автомобиля')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: widget.game.recognizing
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt, size: 70),
                            const SizedBox(height: 16),
                            Text(
                              widget.game.pendingPhoto == null
                                  ? 'Наведите камеру на автомобиль'
                                  : 'Фото обработано: номер замаскирован',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (r != null) ...[
              Card(
                child: ListTile(
                  title: Text('${r.brand} ${r.model}'),
                  subtitle: Text(
                    '${r.generation} • ${r.color} • ${(r.confidence * 100).round()}%',
                  ),
                  trailing: const Icon(Icons.verified),
                ),
              ),
              FilledButton(
                onPressed: () {
                  widget.game.confirmRecognition();
                  Navigator.pop(context);
                },
                child: const Text('Подтвердить и добавить'),
              ),
            ] else
              FilledButton.icon(
                onPressed: widget.game.cameraBusy
                    ? null
                    : widget.game.takePhotoAndRecognize,
                icon: const Icon(Icons.camera),
                label: const Text('Сделать фото и распознать'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key, required this.game});
  final GameController game;

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  CarCard? selected;
  RaceResult? result;

  @override
  Widget build(BuildContext context) {
    final cars = widget.game.player.collection;
    return Scaffold(
      appBar: AppBar(title: const Text('Гонка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Выберите автомобиль'),
          const SizedBox(height: 10),
          ...cars.map(
            (car) => RadioListTile<CarCard>(
              value: car,
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              title: Text(car.displayName),
              subtitle: Text('${car.rarity.title} • power ${car.power}'),
            ),
          ),
          FilledButton.icon(
            onPressed: selected == null
                ? null
                : () => setState(() => result = widget.game.raceBot(selected!)),
            icon: const Icon(Icons.flag),
            label: const Text('Старт гонки с ботом'),
          ),
          const SizedBox(height: 16),
          if (result != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      result!.playerWon ? Icons.emoji_events : Icons.close,
                      size: 60,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result!.playerWon ? 'ПОБЕДА!' : 'ПОРАЖЕНИЕ',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${result!.playerScore.toStringAsFixed(1)} : '
                      '${result!.opponentScore.toStringAsFixed(1)}',
                    ),
                    if (result!.playerWon)
                      const Text('Награда: деньги + XP'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChaseScreen extends StatelessWidget {
  const ChaseScreen({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final stolen = game.player.collection
        .where((c) => c.status == CarStatus.stolen || c.status == CarStatus.inChase)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Погоня')),
      body: stolen.isEmpty
          ? const Center(child: Text('Сейчас угнанных автомобилей нет.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151922),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Icon(Icons.route, size: 100),
                  ),
                ),
                const SizedBox(height: 16),
                ...stolen.map(
                  (car) => Card(
                    child: ListTile(
                      leading: CarShape(color: _colorFor(car.color)),
                      title: Text(car.displayName),
                      subtitle: Text(
                        car.status == CarStatus.stolen
                            ? 'Окно погони: 10 минут'
                            : 'Погоня начата',
                      ),
                      trailing: FilledButton(
                        onPressed: () {
                          game.startChase(car);
                          game.winChase(car);
                        },
                        child: const Text('Догнать'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final sellable = game.player.collection
        .where((c) => c.garageSlot == null)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Б/У рынок')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Цена продажи'),
              subtitle: Text('50% текущей стоимости автомобиля'),
            ),
          ),
          ...sellable.map(
            (car) => Card(
              child: ListTile(
                title: Text(car.displayName),
                subtitle: Text(
                  '${car.rarity.title} • \$${car.currentValue.toStringAsFixed(0)}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    final price = car.currentValue * .5;
                    final ok = game.sell(car);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Продано за \$${price.toStringAsFixed(0)}' : 'Не удалось продать',
                        ),
                      ),
                    );
                  },
                  child: Text('\$${(car.currentValue * .5).toStringAsFixed(0)}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text('${game.player.level}',
                style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text('Уровень ${game.player.level}',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Баланс'),
                  trailing: Text('\$${game.player.money.toStringAsFixed(0)}'),
                ),
                ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: const Text('Коллекция'),
                  trailing: Text('${game.player.collection.length}'),
                ),
                ListTile(
                  leading: const Icon(Icons.garage),
                  title: const Text('Мест в гараже'),
                  trailing: Text('${game.player.garageCapacity}'),
                ),
                ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: const Text('Bluetooth'),
                  trailing: const Text('Mock / P2P-ready'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OPTIONAL TESTABLE DOMAIN HELPERS
// ============================================================

double repairPrice(CarCard car) => car.currentValue * (car.damage / 100) * .25;

int xpForLevel(int level) => 250 + (level - 1) * 150;

double usedMarketPrice(CarCard car) => car.currentValue * .5;

bool canEnterGarage(PlayerState player, CarCard car) =>
    car.garageSlot != null || player.freeGarageSlots > 0;

/// Простейшая deterministic-проверка критической бизнес-логики.
/// Может быть вызвана из unit tests без Flutter UI.
void runDomainSelfChecks() {
  final player = PlayerState();
  final economy = LocalEconomyService(player);
  final car = CarCard(
    id: 'test',
    brand: 'Test',
    model: 'One',
    generation: '1',
    bodyType: BodyType.sedan,
    color: 'Black',
    rarity: Rarity.common,
    baseValue: 10000,
    currentValue: 10000,
    speed: 50,
    handling: 50,
    durability: 50,
    maxSpeed: 100,
    maxHandling: 100,
    maxDurability: 100,
    damage: 40,
  );

  assert(repairPrice(car) == 1000);
  assert(usedMarketPrice(car) == 5000);
  assert(xpForLevel(1) == 250);
  assert(economy.spend(500));
  assert(economy.balance == 2000);
  assert(!economy.spend(999999));
}
