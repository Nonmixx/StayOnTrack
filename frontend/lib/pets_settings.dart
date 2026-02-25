import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Animal Model
// ─────────────────────────────────────────────────────────────────────────────
class Animal {
  final String id;
  final String name;
  final String imagePath;
  final String favouriteFood;
  final String favouriteDrink;
  final int fruitCost;
  bool isUnlocked;

  Animal({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.favouriteFood,
    required this.favouriteDrink,
    required this.fruitCost,
    this.isUnlocked = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-user Persistence Helper
//
//  All keys are namespaced by the user's email so that every registered
//  account keeps its own independent fruit count and unlocked-pet list.
//
//  SharedPreferences keys (where <email> = user email, lowercased):
//    pets_fruits_<email>    →  int   fruit count
//    pets_unlocked_<email>  →  String  comma-separated unlocked IDs
// ─────────────────────────────────────────────────────────────────────────────
class _PetsStore {
  /// The default animal that is unlocked for every new account.
  static const String _defaultUnlocked = 'callduck';

  static String _keyFruits(String email) =>
      'pets_fruits_${email.trim().toLowerCase()}';

  static String _keyUnlocked(String email) =>
      'pets_unlocked_${email.trim().toLowerCase()}';

  /// Load saved state for [email].
  /// Returns (fruitCount, Set<unlockedId>).
  static Future<(int, Set<String>)> load(String email) async {
    final prefs   = await SharedPreferences.getInstance();
    final fruits  = prefs.getInt(_keyFruits(email)) ?? 10000;
    final rawIds  = prefs.getString(_keyUnlocked(email));

    // First-ever load for this account → seed the default unlocked pet.
    final Set<String> ids;
    if (rawIds == null) {
      ids = {_defaultUnlocked};
      // Persist the seed so subsequent loads recognise this isn't "new".
      await prefs.setString(_keyUnlocked(email), _defaultUnlocked);
    } else {
      ids = rawIds
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    return (fruits, ids);
  }

  /// Save current state for [email].
  static Future<void> save(
      String email, int fruits, Set<String> unlockedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFruits(email), fruits);
    await prefs.setString(_keyUnlocked(email), unlockedIds.join(','));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Pets Page
// ─────────────────────────────────────────────────────────────────────────────
class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  // ── Runtime state ──────────────────────────────────────────────────────────
  int  _userFruits = 10000;
  bool _isLoading  = true;

  // Resolved once in initState from AuthStore
  late final String _userEmail;

  // ── Master animal list ─────────────────────────────────────────────────────
  final List<Animal> _animals = [
    Animal(
      id: 'callduck',
      name: 'Call Call',
      imagePath: 'assets/images/callduck.png',
      favouriteFood: 'Hamburger',
      favouriteDrink: 'Coca-Cola',
      fruitCost: 500,
    ),
    Animal(
      id: 'sheep',
      name: 'Sheep',
      imagePath: 'assets/images/sheep.png',
      favouriteFood: 'Grass',
      favouriteDrink: 'Water',
      fruitCost: 1000,
    ),
    Animal(
      id: 'bunny',
      name: 'Bunny',
      imagePath: 'assets/images/bunny.png',
      favouriteFood: 'Carrot',
      favouriteDrink: 'Water',
      fruitCost: 1500,
    ),
    Animal(
      id: 'baiyou',
      name: 'Bai You',
      imagePath: 'assets/images/baiyou.png',
      favouriteFood: 'Bamboo',
      favouriteDrink: 'Green Tea',
      fruitCost: 2000,
    ),
    Animal(
      id: 'calf',
      name: 'Calf',
      imagePath: 'assets/images/calf.png',
      favouriteFood: 'Hay',
      favouriteDrink: 'Milk',
      fruitCost: 3000,
    ),
    Animal(
      id: 'otter',
      name: 'Otter',
      imagePath: 'assets/images/otter.png',
      favouriteFood: 'Clam',
      favouriteDrink: 'River Water',
      fruitCost: 4000,
    ),
    Animal(
      id: 'seal',
      name: 'Seal',
      imagePath: 'assets/images/seal.png',
      favouriteFood: 'Salmon',
      favouriteDrink: 'Sea Water',
      fruitCost: 5000,
    ),
    Animal(
      id: 'elephant',
      name: 'Elephant',
      imagePath: 'assets/images/elephant.png',
      favouriteFood: 'Peanuts',
      favouriteDrink: 'Water',
      fruitCost: 6000,
    ),
    Animal(
      id: 'stingray',
      name: 'Stingray',
      imagePath: 'assets/images/stingray.png',
      favouriteFood: 'Fish',
      favouriteDrink: 'Sea Water',
      fruitCost: 8000,
    ),
    Animal(
      id: 'tiger',
      name: 'Tiger',
      imagePath: 'assets/images/tiger.png',
      favouriteFood: 'Meat',
      favouriteDrink: 'Water',
      fruitCost: 10000,
    ),
    Animal(
      id: 'lion',
      name: 'Lion',
      imagePath: 'assets/images/lion.png',
      favouriteFood: 'Steak',
      favouriteDrink: 'Juice',
      fruitCost: 15000,
    ),
    Animal(
      id: 'crocodile',
      name: 'Crocodile',
      imagePath: 'assets/images/crocodile.png',
      favouriteFood: 'Chicken',
      favouriteDrink: 'Swamp Water',
      fruitCost: 20000,
    ),
    Animal(
      id: 'koala',
      name: 'koala',
      imagePath: 'assets/images/koala.png',
      favouriteFood: 'Bamboo Shoots',
      favouriteDrink: 'Spring Water',
      fruitCost: 25000,
    ),
    Animal(
      id: 'cat',
      name: 'Cat',
      imagePath: 'assets/images/cat.png',
      favouriteFood: 'Tuna',
      favouriteDrink: 'Milk',
      fruitCost: 30000,
    ),
    Animal(
      id: 'dog',
      name: 'Dog',
      imagePath: 'assets/images/dog.png',
      favouriteFood: 'Bone',
      favouriteDrink: 'Water',
      fruitCost: 35000,
    ),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Grab the current user's email once; AuthStore guarantees a logged-in
    // user exists when this page is reachable.
    _userEmail = UserSession.email ?? 'guest';
    _loadState();
  }

  Future<void> _loadState() async {
    final (fruits, unlockedIds) = await _PetsStore.load(_userEmail);
    setState(() {
      _userFruits = fruits;
      for (final animal in _animals) {
        animal.isUnlocked = unlockedIds.contains(animal.id);
      }
      _isLoading = false;
    });
  }

  Future<void> _saveState() async {
    final unlockedIds =
    _animals.where((a) => a.isUnlocked).map((a) => a.id).toSet();
    await _PetsStore.save(_userEmail, _userFruits, unlockedIds);
  }

  // ── Style helper ───────────────────────────────────────────────────────────
  TextStyle _arimo(double size,
      {Color color = Colors.black,
        FontWeight weight = FontWeight.normal}) =>
      GoogleFonts.arimo(fontSize: size, color: color, fontWeight: weight);

  // ── Image helper — visible placeholder on broken path ─────────────────────
  // Renders the image filling its parent completely.
  // Uses FittedBox + SizedBox.expand so it works regardless of
  // image resolution — no LayoutBuilder needed.
  Widget _animalImage(String path) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Image.asset(
          path,
          errorBuilder: (context, error, _) => const Icon(
            Icons.image_not_supported,
            size: 32,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // Fruit icon with emoji fallback so it is always visible
  Widget _fruitIcon({double size = 20}) {
    return Image.asset(
      'assets/images/fruit.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        '🍒',
        style: TextStyle(fontSize: size * 0.85),
      ),
    );
  }

  // ── Detail dialog ──────────────────────────────────────────────────────────
  void _showAnimalDetail(Animal animal) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      // Use StatefulBuilder so the button reacts immediately when
      // userFruits changes (e.g. just unlocked another pet).
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final bool canAfford = _userFruits >= animal.fruitCost;

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Animal info ──────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image box
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            animal.imagePath,
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name : ${animal.name}',
                                style: _arimo(14,
                                    weight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text(
                                'Favourtie Food: ${animal.favouriteFood}',
                                style: _arimo(13)),
                            const SizedBox(height: 8),
                            Text(
                                'Favourtie Drink: ${animal.favouriteDrink}',
                                style: _arimo(13)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Action button ────────────────────────────────────
                  if (animal.isUnlocked)
                  // Already unlocked state
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'Already Unlocked 🎉',
                          style: _arimo(14,
                              color: Colors.green,
                              weight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                  // Unlock button — red cost when can't afford, normal when can
                    GestureDetector(
                      onTap: canAfford
                          ? () {
                        // 1. Update state
                        setState(() {
                          _userFruits -= animal.fruitCost;
                          animal.isUnlocked = true;
                        });
                        // 2. Persist immediately under this user's key
                        _saveState();
                        // 3. Close dialog
                        Navigator.pop(context);
                      }
                          : null, // disabled tap when insufficient fruits
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: canAfford
                                ? Colors.grey.shade400
                                : Colors.red.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _fruitIcon(size: 22),
                            const SizedBox(width: 6),
                            Text(
                              '${animal.fruitCost}',
                              style: _arimo(
                                16,
                                color: canAfford
                                    ? Colors.black87
                                    : Colors.red,
                                weight: FontWeight.w600,
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
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const cream    = Color(0xFFF5F0EB);
    const lavender = Color(0xFFE6CFE6);

    return Scaffold(
      backgroundColor: cream,

      // ── AppBar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
              Text('Back', style: _arimo(16)),
            ],
          ),
        ),
        leadingWidth: 90,
        title: Text('My Pets', style: _arimo(16)),
        centerTitle: true,
      ),

      // ── Body ────────────────────────────────────────────────────────────
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fruit counter ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fruitIcon(size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$_userFruits',
                    style: _arimo(14, weight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.add,
                      size: 16, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Pet grid ─────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: lavender.withOpacity(0.85),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _animals.length,
                itemBuilder: (context, index) {
                  final animal = _animals[index];
                  return GestureDetector(
                    onTap: () => _showAnimalDetail(animal),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        // White background when unlocked, grey when locked
                        color: animal.isUnlocked
                            ? Colors.white
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: animal.isUnlocked
                            ? [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Always show the animal image
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: _animalImage(animal.imagePath),
                          ),
                          // Overlay dark tint + lock icon when locked
                          if (!animal.isUnlocked) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            const Center(
                              child: Icon(
                                Icons.lock,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}