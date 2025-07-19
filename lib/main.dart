// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_service.dart';
import 'firebase_options.dart';
import 'ios_keyboard_fix.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SAFE iOS keyboard fix for web - NO RECURSION
  if (kIsWeb) {
    try {
      IOSKeyboardFix.initialize();
      print('✅ iOS keyboard fix initialized safely');
    } catch (e) {
      print('❌ iOS keyboard fix failed: $e');
      // Continue anyway - don't crash the app
    }
  }

  // SAFE Firebase initialization
  if (kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🔥 Firebase initialized successfully');
    } catch (e) {
      print('🔥 Firebase init failed: $e');
      // Continue anyway - app will work locally
    }
  }

  // iOS Status Bar Configuration
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
    );
  } catch (e) {
    print('Status bar config failed: $e');
  }

  runApp(const SypshytApp());
}

class SypshytApp extends StatelessWidget {
  const SypshytApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWYPSHYT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SFProDisplay',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
        ),
      ),
      home: const SypshytHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum MoneyType { spent, received }

// Add this to your main.dart - Custom Category System

// 1. FIRST - Add this to your Category enum (find the existing one and replace it)
enum Category {
  food,
  shopping,
  groceries,
  clothes,
  orders,
  girlfriend,
  mom,
  gigs,
  misc,
  // Custom categories will be handled separately
}

// 2. NEW - Custom Category Class
class CustomCategory {
  final String id;
  final String name;
  final List<String> keywords;
  final Color color;
  final IconData icon;
  final DateTime createdAt;

  CustomCategory({
    required this.id,
    required this.name,
    required this.keywords,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keywords': keywords,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      id: json['id'],
      name: json['name'],
      keywords: List<String>.from(json['keywords']),
      color: Color(json['color']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// 3. NEW - Custom Category Manager
class CustomCategoryManager {
  static List<CustomCategory> _customCategories = [];

  static List<CustomCategory> get customCategories => _customCategories;

  // Available colors for new categories
  static const List<Color> availableColors = [
    Color(0xFF8E44AD), // Purple
    Color(0xFFE67E22), // Orange
    Color(0xFF1ABC9C), // Turquoise
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFFF39C12), // Yellow
    Color(0xFF9B59B6), // Violet
    Color(0xFF16A085), // Dark Turquoise
    Color(0xFFD35400), // Dark Orange
  ];

  // Available icons
  static const List<IconData> availableIcons = [
    Icons.person,
    Icons.family_restroom,
    Icons.local_bar,
    Icons.sports_soccer,
    Icons.pets,
    Icons.car_rental,
    Icons.school,
    Icons.medical_services,
    Icons.fitness_center,
    Icons.videogame_asset,
    Icons.travel_explore,
    Icons.home_repair_service,
    Icons.spa,
    Icons.theater_comedy,
  ];

  static Future<void> loadCustomCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? categoriesData = prefs.getString('custom_categories');

    if (categoriesData != null) {
      List<dynamic> categoriesJson = json.decode(categoriesData);
      _customCategories =
          categoriesJson.map((e) => CustomCategory.fromJson(e)).toList();
    }
  }

  static Future<void> saveCustomCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String categoriesJson =
        json.encode(_customCategories.map((e) => e.toJson()).toList());
    await prefs.setString('custom_categories', categoriesJson);
  }

  static void addCategory(CustomCategory category) {
    _customCategories.add(category);
    saveCustomCategories();
  }

  static void removeCategory(String id) {
    _customCategories.removeWhere((cat) => cat.id == id);
    saveCustomCategories();
  }

  // Enhanced classification that includes custom categories
  static String classifyTransaction(String description, MoneyType type) {
    String lower = description.toLowerCase();

    // First check custom categories
    for (final customCat in _customCategories) {
      for (final keyword in customCat.keywords) {
        if (lower.contains(keyword.toLowerCase())) {
          return customCat.id; // Return custom category ID
        }
      }
    }

    // Fall back to original classification
    Category originalCategory =
        TransactionClassifier.classify(description: description, type: type);
    return originalCategory.toString().split('.').last;
  }

  static Color getCategoryColor(String categoryId) {
    // Check if it's a custom category
    for (final customCat in _customCategories) {
      if (customCat.id == categoryId) {
        return customCat.color;
      }
    }

    // Fall back to original category colors
    try {
      Category category = Category.values
          .firstWhere((e) => e.toString().split('.').last == categoryId);
      return TransactionClassifier.getCategoryColor(category);
    } catch (e) {
      return const Color(0xFF8E8E93); // Default gray
    }
  }

  static IconData getCategoryIcon(String categoryId) {
    // Check if it's a custom category
    for (final customCat in _customCategories) {
      if (customCat.id == categoryId) {
        return customCat.icon;
      }
    }

    // Fall back to original category icons
    try {
      Category category = Category.values
          .firstWhere((e) => e.toString().split('.').last == categoryId);

      switch (category) {
        case Category.food:
          return Icons.restaurant;
        case Category.shopping:
          return Icons.shopping_bag;
        case Category.groceries:
          return Icons.local_grocery_store;
        case Category.clothes:
          return Icons.checkroom;
        case Category.orders:
          return Icons.local_shipping;
        case Category.girlfriend:
          return Icons.favorite;
        case Category.mom:
          return Icons.family_restroom;
        case Category.gigs:
          return Icons.music_note;
        case Category.misc:
          return Icons.category;
      }
    } catch (e) {
      return Icons.category; // Default icon
    }
  }

  static String getCategoryName(String categoryId) {
    // Check if it's a custom category
    for (final customCat in _customCategories) {
      if (customCat.id == categoryId) {
        return customCat.name;
      }
    }

    // Fall back to original category names
    try {
      Category category = Category.values
          .firstWhere((e) => e.toString().split('.').last == categoryId);
      return TransactionClassifier.getCategoryName(category);
    } catch (e) {
      return 'Unknown';
    }
  }
}

// 4. NEW - Add Category Dialog Widget
class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({Key? key}) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController keywordController = TextEditingController();
  List<String> keywords = [];
  Color selectedColor = CustomCategoryManager.availableColors[0];
  IconData selectedIcon = CustomCategoryManager.availableIcons[0];

  void _addKeyword() {
    String keyword = keywordController.text.trim();
    if (keyword.isNotEmpty && keywords.length < 10) {
      // Limit words to 3
      List<String> words = keyword.split(' ');
      if (words.length <= 3) {
        setState(() {
          keywords.add(keyword.toLowerCase());
          keywordController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Keywords limited to 3 words max')));
      }
    }
  }

  void _removeKeyword(int index) {
    setState(() {
      keywords.removeAt(index);
    });
  }

  void _createCategory() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a category name')));
      return;
    }

    if (keywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one keyword')));
      return;
    }

    CustomCategory newCategory = CustomCategory(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      keywords: keywords,
      color: selectedColor,
      icon: selectedIcon,
      createdAt: DateTime.now(),
    );

    CustomCategoryManager.addCategory(newCategory);
    Navigator.pop(context, true); // Return success
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Add Custom Category',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Name
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                hintText: 'e.g., Dad, Alcohol, Gaming',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Keywords Section
            TextField(
              controller: keywordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Add Keywords',
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                hintText: 'dad, father, pop (3 words max)',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  onPressed: _addKeyword,
                  icon: const Icon(Icons.add, color: Color(0xFF007AFF)),
                ),
              ),
              onSubmitted: (_) => _addKeyword(),
            ),
            const SizedBox(height: 8),

            // Keywords Display
            if (keywords.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: keywords.asMap().entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selectedColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value,
                            style:
                                TextStyle(color: selectedColor, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeKeyword(entry.key),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: selectedColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),

            // Color Selection
            const Text('Choose Color:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: CustomCategoryManager.availableColors.length,
                itemBuilder: (context, index) {
                  Color color = CustomCategoryManager.availableColors[index];
                  bool isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Icon Selection
            const Text('Choose Icon:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: CustomCategoryManager.availableIcons.length,
                itemBuilder: (context, index) {
                  IconData icon = CustomCategoryManager.availableIcons[index];
                  bool isSelected = icon == selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: selectedColor, width: 2)
                            : Border.all(color: const Color(0xFF8E8E93)),
                      ),
                      child: Icon(
                        icon,
                        color:
                            isSelected ? Colors.white : const Color(0xFF8E8E93),
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
        ElevatedButton(
          onPressed: _createCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class BudgetManager {
  static final Map<Category, double> _budgetLimits = {
    Category.food: 5000.0,
    Category.shopping: 3000.0,
    Category.groceries: 2000.0,
    Category.clothes: 2500.0,
    Category.orders: 1500.0,
    Category.girlfriend: 4000.0,
    Category.mom: 3000.0,
    Category.misc: 1000.0,
  };

  static double getBudgetLimit(Category category) {
    return _budgetLimits[category] ?? 1000.0;
  }

  static bool isOverBudget(Category category, double totalSpent) {
    return totalSpent > getBudgetLimit(category);
  }

  static double getBudgetProgress(Category category, double totalSpent) {
    double limit = getBudgetLimit(category);
    return (totalSpent / limit).clamp(0.0, 1.0);
  }
}

class TransactionClassifier {
  static final Map<Category, List<String>> categoryKeywords = {
    Category.girlfriend: ['girlfriend', 'gf', 'for gf', 'for girlfriend'],
    Category.mom: ['mom', 'mother', 'for mom', 'for mother'],
    Category.food: [
      'swiggy',
      'zomato',
      'instamart',
      'blinkit',
      'restaurant',
      'chips',
      'chocolate',
      'snacks',
      'junk food',
      'food',
      'eat',
      'meal'
    ],
    Category.clothes: [
      'shirt',
      'pant',
      'tshirt',
      't-shirt',
      'hoodie',
      'jeans',
      'sweater',
      'jacket',
      'clothes',
      'underwear',
      'shoes'
    ],
    Category.groceries: [
      'fish',
      'chicken',
      'vegetables',
      'groceries',
      'grocery',
      'items',
      'basic shopping',
      'essentials',
      'milk',
      'bread'
    ],
    Category.orders: [
      'amazon',
      'flipkart',
      'online order',
      'online delivery',
      'delivery',
      'ordered online',
      'parcel',
      'myntra'
    ],
    Category.shopping: [
      'shopping',
      'bought',
      'purchase',
      'spent on shopping',
      'online shopping'
    ],
    Category.gigs: [
      'gig',
      'dj show',
      'event payment',
      'show',
      'freelance',
      'paid for gig'
    ],
  };

  static Category classify(
      {required String description, required MoneyType type}) {
    String lower = description.toLowerCase();

    List<Category> priority = [
      Category.girlfriend,
      Category.mom,
      Category.food,
      Category.clothes,
      Category.groceries,
      Category.orders,
      Category.shopping,
      Category.gigs
    ];

    for (final category in priority) {
      for (final keyword in categoryKeywords[category]!) {
        if (lower.contains(keyword)) {
          if (category == Category.gigs && type == MoneyType.received) {
            return Category.gigs;
          }
          if (category == Category.mom) return Category.mom;
          if (category == Category.girlfriend) return Category.girlfriend;
          if (type == MoneyType.spent) return category;
        }
      }
    }
    return Category.misc;
  }

  static Color getCategoryColor(Category category) {
    switch (category) {
      case Category.food:
        return const Color(0xFFFF9500);
      case Category.shopping:
        return const Color(0xFF5856D6);
      case Category.groceries:
        return const Color(0xFF34C759);
      case Category.clothes:
        return const Color(0xFFAF52DE);
      case Category.orders:
        return const Color(0xFF007AFF);
      case Category.girlfriend:
        return const Color(0xFFFF2D92);
      case Category.mom:
        return const Color(0xFFFF3B30);
      case Category.gigs:
        return const Color(0xFF32D74B);
      case Category.misc:
        return const Color(0xFF8E8E93);
    }
  }

  static String getCategoryName(Category category) {
    switch (category) {
      case Category.food:
        return 'Food';
      case Category.shopping:
        return 'Shopping';
      case Category.groceries:
        return 'Groceries';
      case Category.clothes:
        return 'Clothes';
      case Category.orders:
        return 'Orders';
      case Category.girlfriend:
        return 'Girlfriend';
      case Category.mom:
        return 'Mom';
      case Category.gigs:
        return 'Gigs';
      case Category.misc:
        return 'Misc';
    }
  }
}

class ExpenseEntry {
  final String id;
  final double amount;
  final String name;
  final bool recoverable;
  final DateTime timestamp;
  final String category; // CHANGED: Now String instead of Category enum

  ExpenseEntry({
    required this.id,
    required this.amount,
    required this.name,
    required this.recoverable,
    required this.timestamp,
    String? category,
  }) : category = category ??
            CustomCategoryManager.classifyTransaction(name, MoneyType.spent);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'name': name,
      'recoverable': recoverable,
      'timestamp': timestamp.toIso8601String(),
      'category': category, // Now directly stores the category ID/name
    };
  }

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'],
      amount: json['amount'].toDouble(),
      name: json['name'],
      recoverable: json['recoverable'],
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'] ?? 'misc', // Fallback to 'misc' if null
    );
  }
}

class IncomeEntry {
  final String id;
  final double amount;
  final String name;
  final bool allMine;
  final DateTime timestamp;
  final String category; // CHANGED: Now String instead of Category enum

  IncomeEntry({
    required this.id,
    required this.amount,
    required this.name,
    required this.allMine,
    required this.timestamp,
    String? category,
  }) : category = category ??
            CustomCategoryManager.classifyTransaction(name, MoneyType.received);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'name': name,
      'allMine': allMine,
      'timestamp': timestamp.toIso8601String(),
      'category': category, // Now directly stores the category ID/name
    };
  }

  factory IncomeEntry.fromJson(Map<String, dynamic> json) {
    return IncomeEntry(
      id: json['id'],
      amount: json['amount'].toDouble(),
      name: json['name'],
      allMine: json['allMine'],
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'] ?? 'misc', // Fallback to 'misc' if null
    );
  }
}

class PayTrackEntry {
  final String id;
  final double amount;
  final String name;
  final String eventTitle;
  final DateTime eventDate;
  final DateTime dateAdded;
  final bool isPaid;
  final DateTime? paidDate;

  PayTrackEntry({
    required this.id,
    required this.amount,
    required this.name,
    required this.eventTitle,
    required this.eventDate,
    required this.dateAdded,
    this.isPaid = false,
    this.paidDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'name': name,
      'eventTitle': eventTitle,
      'eventDate': eventDate.toIso8601String(),
      'dateAdded': dateAdded.toIso8601String(),
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
    };
  }

  factory PayTrackEntry.fromJson(Map<String, dynamic> json) {
    return PayTrackEntry(
      id: json['id'],
      amount: json['amount'].toDouble(),
      name: json['name'],
      eventTitle: json['eventTitle'] ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'])
          : DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded'])
          : DateTime.now(),
      isPaid: json['isPaid'] ?? false,
      paidDate:
          json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
    );
  }

  PayTrackEntry copyWith({bool? isPaid, DateTime? paidDate}) {
    return PayTrackEntry(
      id: id,
      amount: amount,
      name: name,
      eventTitle: eventTitle,
      eventDate: eventDate,
      dateAdded: dateAdded,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
    );
  }
}

class SypshytHomePage extends StatefulWidget {
  const SypshytHomePage({super.key});

  @override
  _SypshytHomePageState createState() => _SypshytHomePageState();
}

class _SypshytHomePageState extends State<SypshytHomePage>
    with TickerProviderStateMixin {
  List<ExpenseEntry> spentEntries = [];
  List<IncomeEntry> gotEntries = [];
  List<PayTrackEntry> payTrackEntries = [];
  int currentSavingStreak = 0;
  int longestSavingStreak = 0;
  int daysUnderBudget = 0;
  DateTime lastStreakUpdate = DateTime.now();
  final TextEditingController spentAmountController = TextEditingController();
  final TextEditingController spentNameController = TextEditingController();
  final TextEditingController gotAmountController = TextEditingController();
  final TextEditingController gotNameController = TextEditingController();
  final TextEditingController payTrackAmountController =
      TextEditingController();
  final TextEditingController payTrackNameController = TextEditingController();
  final TextEditingController payTrackEventTitleController =
      TextEditingController();
  DateTime selectedEventDate = DateTime.now();
  bool spentRecoverable = false;
  bool gotAllMine = true;
  bool showSpentForm = false;
  bool showGotForm = false;
  bool isLoading = false;
  bool isDarkMode = false;
  bool showControlPanel = false;
  DateTime selectedPayDate = DateTime.now();
  String selectedLogPeriod = 'This Month';
  String userName = '';
  String userNickname = '';
  double dailyBudget = 1000.0;
  Map<String, String> familyMembers = {
    'mom': '',
    'dad': '',
    'girlfriend': '',
    'sister': '',
    'brother': '',
    'friend': '',
  };
  bool showProfilePanel = false;
  String selectedCategoryPeriod = 'Monthly';
  String searchQuery = '';
  String selectedCategoryFilter = 'All';
  List<Map<String, dynamic>> notifications = [];
  bool showNotificationPanel = false;
  bool hasUnseenNotifications = true;
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;
  PageController categoryPageController = PageController();
  DateTime selectedLogDate = DateTime.now();

  // Animations
  late AnimationController _spentFormController;
  late AnimationController _gotFormController;
  late AnimationController _balanceController;
  late AnimationController _listItemController;
  late AnimationController _controlPanelController;
  late Animation<double> _controlPanelAnimation;
  late Animation<double> _spentFormAnimation;
  late Animation<double> _gotFormAnimation;
  late Animation<double> _balanceScaleAnimation;
  late Animation<Offset> _spentSlideAnimation;
  late Animation<Offset> _gotSlideAnimation;

  // iOS-specific colors with dynamic support
  Color get backgroundColor {
    if (isDarkMode) {
      return const Color(0xFF000000);
    } else {
      return const Color(0xFFF2F2F7); // iOS Light Gray
    }
  }

  Color get cardColor {
    if (isDarkMode) {
      return const Color(0xFF1C1C1E).withOpacity(0.8);
    } else {
      return Colors.white.withOpacity(0.9);
    }
  }

  Color get surfaceColor {
    if (isDarkMode) {
      return const Color(0xFF2C2C2E).withOpacity(0.7);
    } else {
      return const Color(0xFFF2F2F7).withOpacity(0.8);
    }
  }

  Color get textColor => isDarkMode ? Colors.white : const Color(0xFF000000);
  Color get subtitleColor => const Color(0xFF8E8E93);
  Color get inputFieldColor => isDarkMode
      ? const Color(0xFF3A3A3C).withOpacity(0.8)
      : Colors.white.withOpacity(0.9);
  Color get borderColor => isDarkMode
      ? const Color(0xFF38383A).withOpacity(0.6)
      : const Color(0xFFC7C7CC).withOpacity(0.8);
  Color get modalBackgroundColor => isDarkMode
      ? const Color(0xFF1C1C1E).withOpacity(0.95)
      : Colors.white.withOpacity(0.95);
  Color get modalSurfaceColor => isDarkMode
      ? const Color(0xFF2C2C2E).withOpacity(0.9)
      : const Color(0xFFF2F2F7).withOpacity(0.9);
  Color get hintTextColor =>
      isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF3C3C43);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProfileData();
    _loadStreakData();
    _loadThemePreference().then((_) => _loadData());
    _startAuroraAnimation();
  }

  late Timer _auroraTimer;

  void _startAuroraAnimation() {
    _auroraTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  void _initializeAnimations() {
    _spentFormController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _gotFormController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _balanceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listItemController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controlPanelController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controlPanelAnimation = CurvedAnimation(
      parent: _controlPanelController,
      curve: Curves.easeInOut,
    );

    _spentFormAnimation = CurvedAnimation(
      parent: _spentFormController,
      curve: Curves.easeOutBack,
    );

    _gotFormAnimation = CurvedAnimation(
      parent: _gotFormController,
      curve: Curves.easeOutBack,
    );

    _balanceScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _balanceController,
      curve: Curves.elasticOut,
    ));

    _spentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(_spentFormAnimation);

    _gotSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(_gotFormAnimation);

    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _notificationAnimation = CurvedAnimation(
      parent: _notificationController,
      curve: Curves.easeInOut,
    );
  }

  List<dynamic> _getFilteredLogData() {
    List<dynamic> allEntries = [];
    DateTime now = DateTime.now();

    allEntries.addAll(spentEntries.map((e) => {'type': 'spent', 'entry': e}));
    allEntries.addAll(gotEntries.map((e) => {'type': 'got', 'entry': e}));

    if (searchQuery.isNotEmpty) {
      allEntries = allEntries.where((entry) {
        return entry['entry']
            .name
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (selectedCategoryFilter != 'All') {
      Category? filterCategory = _getCategoryFromString(selectedCategoryFilter);
      if (filterCategory != null) {
        allEntries = allEntries.where((entry) {
          return entry['entry'].category == filterCategory;
        }).toList();
      }
    }

    allEntries.sort((a, b) {
      DateTime timeA = a['entry'].timestamp;
      DateTime timeB = b['entry'].timestamp;
      return timeB.compareTo(timeA);
    });

    if (allEntries.length > 100) {
      allEntries = allEntries.take(100).toList();
    }

    return allEntries;
  }

  Category? _getCategoryFromString(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Category.food;
      case 'shopping':
        return Category.shopping;
      case 'mom':
        return Category.mom;
      case 'girlfriend':
        return Category.girlfriend;
      case 'gigs':
        return Category.gigs;
      case 'misc':
        return Category.misc;
      default:
        return null;
    }
  }

  void _updateEntry(
      dynamic entry, bool isIncome, double newAmount, String newName) {
    setState(() {
      if (isIncome) {
        int index = gotEntries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          gotEntries[index] = IncomeEntry(
            id: entry.id,
            amount: newAmount,
            name: newName,
            allMine: entry.allMine,
            timestamp: entry.timestamp,
            category: entry.category,
          );
        }
      } else {
        int index = spentEntries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          spentEntries[index] = ExpenseEntry(
            id: entry.id,
            amount: newAmount,
            name: newName,
            recoverable: entry.recoverable,
            timestamp: entry.timestamp,
            category: entry.category,
          );
        }
      }
      _cachedCategoryData = null;
    });

    _animateBalanceChange();
    _saveData();
    HapticFeedback.mediumImpact();
    _showSnackBar('Entry updated successfully!');
  }

  void _showEditEntryDialog(dynamic entry, bool isIncome) {
    TextEditingController editAmountController =
        TextEditingController(text: entry.amount.toString());
    TextEditingController editNameController =
        TextEditingController(text: entry.name);

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Edit ${isIncome ? 'Income' : 'Expense'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: editAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor, fontFamily: 'SFProDisplay'),
                placeholder: 'Amount',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('₹ '),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: editNameController,
                style: TextStyle(color: textColor, fontFamily: 'SFProDisplay'),
                placeholder: 'Description',
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                if (isIncome) {
                  _deleteGotEntry(entry.id);
                } else {
                  _deleteSpentEntry(entry.id);
                }
              },
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                if (_validateAmount(editAmountController.text) &&
                    _validateName(editNameController.text)) {
                  _updateEntry(
                      entry,
                      isIncome,
                      double.parse(editAmountController.text),
                      editNameController.text);
                  Navigator.pop(context);
                } else {
                  _showSnackBar('Please enter valid amount and description',
                      isError: true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _notificationController.dispose();
    _auroraTimer.cancel();
    _spentFormController.dispose();
    _gotFormController.dispose();
    _balanceController.dispose();
    _listItemController.dispose();
    _controlPanelController.dispose();
    categoryPageController.dispose();
    spentAmountController.dispose();
    spentNameController.dispose();
    gotAmountController.dispose();
    gotNameController.dispose();
    payTrackAmountController.dispose();
    payTrackNameController.dispose();
    payTrackEventTitleController.dispose();
    super.dispose();
  }

  // Cache for category data
  Map<String, dynamic>? _cachedCategoryData;
  DateTime? _lastCacheTime;
  String? _lastCachedPeriod;

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // LOAD CUSTOM CATEGORIES FIRST - THIS IS THE KEY ADDITION!
      await CustomCategoryManager.loadCustomCategories();

      // Try Firebase first
      try {
        await FirebaseService.initialize();
        final firebaseData = await FirebaseService.loadFinanceData();

        if (firebaseData['expenses']!.isNotEmpty ||
            firebaseData['income']!.isNotEmpty ||
            firebaseData['paytrack']!.isNotEmpty) {
          setState(() {
            spentEntries = (firebaseData['expenses'] as List)
                .map((e) => ExpenseEntry.fromJson(e))
                .toList();
            gotEntries = (firebaseData['income'] as List)
                .map((e) => IncomeEntry.fromJson(e))
                .toList();
            payTrackEntries = (firebaseData['paytrack'] as List)
                .map((e) => PayTrackEntry.fromJson(e))
                .toList();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📱 Loaded from cloud'),
                backgroundColor: Color(0xFF007AFF),
                duration: Duration(seconds: 1),
              ),
            );
          }
          await _checkAndResetData();
          return;
        }
      } catch (e) {
        print('Firebase load failed: $e');
      }

      // Fallback to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? spentData = prefs.getString('sypshyt_spent');
      String? gotData = prefs.getString('sypshyt_got');
      String? payTrackData = prefs.getString('sypshyt_paytrack');

      if (spentData != null) {
        List<dynamic> spentJson = json.decode(spentData);
        spentEntries = spentJson.map((e) => ExpenseEntry.fromJson(e)).toList();
      }

      if (gotData != null) {
        List<dynamic> gotJson = json.decode(gotData);
        gotEntries = gotJson.map((e) => IncomeEntry.fromJson(e)).toList();
      }

      if (payTrackData != null) {
        List<dynamic> payTrackJson = json.decode(payTrackData);
        payTrackEntries =
            payTrackJson.map((e) => PayTrackEntry.fromJson(e)).toList();
      }

      await _checkAndResetData();
    } catch (e) {
      _showSnackBar('Error loading data: ${e.toString()}', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveData() async {
    try {
      // Always save to SharedPreferences first (local backup)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String spentJson =
          json.encode(spentEntries.map((e) => e.toJson()).toList());
      String gotJson = json.encode(gotEntries.map((e) => e.toJson()).toList());
      String payTrackJson =
          json.encode(payTrackEntries.map((e) => e.toJson()).toList());

      await Future.wait([
        prefs.setString('sypshyt_spent', spentJson),
        prefs.setString('sypshyt_got', gotJson),
        prefs.setString('sypshyt_paytrack', payTrackJson),
      ]);

      // Save to Firebase Cloud
      final success = await FirebaseService.saveFinanceData(
        expenses: spentEntries.map((e) => e.toJson()).toList(),
        income: gotEntries.map((e) => e.toJson()).toList(),
        paytrack: payTrackEntries.map((e) => e.toJson()).toList(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Saved to cloud'),
            backgroundColor: Color(0xFF34C759),
            duration: Duration(seconds: 1),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Saved locally'),
            backgroundColor: Color(0xFF007AFF),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error saving data: ${e.toString()}', isError: true);
    }
  }

  void _playEntrySound() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/entry.mp3'));
    } catch (e) {
      // Silently fail if sound can't play
    }
  }

  Future<void> _checkAndResetData() async {
    // DO NOTHING - Keep all data forever
    // Users can filter by date in LogBook if needed
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('last_reset_date', today);
  }

  bool _validateAmount(String amountText) {
    if (amountText.trim().isEmpty) return false;

    double? amount;
    try {
      amount = double.parse(amountText);
    } catch (e) {
      return false;
    }

    if (amount <= 0 || amount > 10000000) return false;

    if (amountText.contains('.')) {
      List<String> parts = amountText.split('.');
      if (parts.length > 2 || parts[1].length > 2) return false;
    }

    return true;
  }

  bool _validateName(String name) {
    String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length < 2 || trimmed.length > 50) {
      return false;
    }
    if (RegExp(r'^[^a-zA-Z0-9\s]+$').hasMatch(trimmed)) {
      return false;
    }
    return true;
  }

  void _addSpentEntry() {
    if (!_validateAmount(spentAmountController.text)) {
      _showSnackBar('Please enter a valid amount (₹1 - ₹1,00,00,000)',
          isError: true);
      return;
    }

    if (!_validateName(spentNameController.text)) {
      _showSnackBar('Please enter a valid description (2-50 characters)',
          isError: true);
      return;
    }

    try {
      double amount = double.parse(spentAmountController.text);

      ExpenseEntry newEntry = ExpenseEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        name: spentNameController.text.trim(),
        recoverable: spentRecoverable,
        timestamp: DateTime.now(),
      );

      setState(() {
        spentEntries.insert(0, newEntry);
        _cachedCategoryData = null;
        spentAmountController.clear();
        spentNameController.clear();
        spentRecoverable = false;
        showSpentForm = false;
      });

      _spentFormController.reverse();
      _animateBalanceChange();
      _saveData();
      HapticFeedback.lightImpact();
      _playEntrySound();
      _showSnackBar('Expense added successfully!');
    } catch (e) {
      _showSnackBar('Error adding expense: ${e.toString()}', isError: true);
    }
  }

  void _addGotEntry() {
    if (!_validateAmount(gotAmountController.text)) {
      _showSnackBar('Please enter a valid amount (₹1 - ₹1,00,00,000)',
          isError: true);
      return;
    }

    if (!_validateName(gotNameController.text)) {
      _showSnackBar('Please enter a valid income source (2-50 characters)',
          isError: true);
      return;
    }

    try {
      double amount = double.parse(gotAmountController.text);

      IncomeEntry newEntry = IncomeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        name: gotNameController.text.trim(),
        allMine: gotAllMine,
        timestamp: DateTime.now(),
      );

      setState(() {
        gotEntries.insert(0, newEntry);
        _cachedCategoryData = null;
        gotAmountController.clear();
        gotNameController.clear();
        gotAllMine = true;
        showGotForm = false;
      });

      _gotFormController.reverse();
      _animateBalanceChange();
      _saveData();
      HapticFeedback.lightImpact();
      _playEntrySound();
      _showSnackBar('Income added successfully!');
    } catch (e) {
      _showSnackBar('Error adding income: ${e.toString()}', isError: true);
    }
  }

  void _deleteSpentEntry(String id) {
    setState(() {
      spentEntries.removeWhere((entry) => entry.id == id);
    });
    _animateBalanceChange();
    _saveData();
    HapticFeedback.selectionClick();
    _showSnackBar('Expense deleted');
  }

  void _deleteGotEntry(String id) {
    setState(() {
      gotEntries.removeWhere((entry) => entry.id == id);
    });
    _animateBalanceChange();
    _saveData();
    HapticFeedback.selectionClick();
    _showSnackBar('Income deleted');
  }

  void _animateBalanceChange() {
    _balanceController.forward().then((_) => _balanceController.reverse());
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFamily: 'SFProDisplay',
          ),
        ),
        duration: Duration(seconds: isError ? 4 : 2),
        backgroundColor:
            isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    ).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  double get totalSpent =>
      spentEntries.fold(0.0, (sum, entry) => sum + entry.amount);
  double get totalGot =>
      gotEntries.fold(0.0, (sum, entry) => sum + entry.amount);
  double get netBalance => totalGot - totalSpent;
  double get pendingPayments => payTrackEntries
      .where((e) => !e.isPaid)
      .fold(0.0, (sum, entry) => sum + entry.amount);

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      selectedCategoryPeriod =
          prefs.getString('selectedCategoryPeriod') ?? 'Daily';
    });
  }

  Future<void> _saveThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setString('selectedCategoryPeriod', selectedCategoryPeriod);
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _saveThemePreference();
    HapticFeedback.mediumImpact();
  }

  void _exportData() {
    Map<String, dynamic> exportData = {
      'expenses': spentEntries.map((e) => e.toJson()).toList(),
      'income': gotEntries.map((e) => e.toJson()).toList(),
      'paytrack': payTrackEntries.map((e) => e.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
    };

    String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your data has been prepared for export:'),
            const SizedBox(height: 10),
            Text('${spentEntries.length} expenses'),
            Text('${gotEntries.length} income entries'),
            Text('${payTrackEntries.length} gig entries'),
            const SizedBox(height: 15),
            const Text(
              'Copy the data below and save it to a file:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(context);
              _showSnackBar('Data copied to clipboard!');
            },
            child: const Text('Copy to Clipboard'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<MeshGradientPoint> _getMeshPointsForBalance() {
    double balance = netBalance;

    if (balance == 0) {
      return isDarkMode
          ? [
              MeshGradientPoint(
                  position: const Offset(0.2, 0.3),
                  color: const Color(0xFF000000)),
              MeshGradientPoint(
                  position: const Offset(0.8, 0.2),
                  color: const Color(0xFF1C1C1E)),
              MeshGradientPoint(
                  position: const Offset(0.3, 0.8),
                  color: const Color(0xFF2C2C2E)),
              MeshGradientPoint(
                  position: const Offset(0.7, 0.7),
                  color: const Color(0xFF000000)),
            ]
          : [
              MeshGradientPoint(
                  position: const Offset(0.2, 0.3),
                  color: const Color(0xFFFFFFFF)),
              MeshGradientPoint(
                  position: const Offset(0.8, 0.2),
                  color: const Color(0xFFF2F2F7)),
              MeshGradientPoint(
                  position: const Offset(0.3, 0.8),
                  color: const Color(0xFFE5E5EA)),
              MeshGradientPoint(
                  position: const Offset(0.7, 0.7),
                  color: const Color(0xFFFFFFFF)),
            ];
    }

    if (balance < 0) {
      if (balance >= -999) {
        return isDarkMode
            ? [
                MeshGradientPoint(
                    position: const Offset(0.1, 0.2),
                    color: const Color(0xFF000000)),
                MeshGradientPoint(
                    position: const Offset(0.9, 0.1),
                    color: const Color(0xFF4A0F0F)),
                MeshGradientPoint(
                    position: const Offset(0.2, 0.9),
                    color: const Color(0xFF2C0000)),
                MeshGradientPoint(
                    position: const Offset(0.8, 0.8),
                    color: const Color(0xFF1C1C1E)),
              ]
            : [
                MeshGradientPoint(
                    position: const Offset(0.1, 0.2),
                    color: const Color(0xFFFFFFFF)),
                MeshGradientPoint(
                    position: const Offset(0.9, 0.1),
                    color: const Color(0xFFFFE8E8)),
                MeshGradientPoint(
                    position: const Offset(0.2, 0.9),
                    color: const Color(0xFFFFF0F0)),
                MeshGradientPoint(
                    position: const Offset(0.8, 0.8),
                    color: const Color(0xFFF2F2F7)),
              ];
      } else {
        return isDarkMode
            ? [
                MeshGradientPoint(
                    position: const Offset(0.0, 0.3),
                    color: const Color(0xFF660000)),
                MeshGradientPoint(
                    position: const Offset(1.0, 0.2),
                    color: const Color(0xFF000000)),
                MeshGradientPoint(
                    position: const Offset(0.3, 1.0),
                    color: const Color(0xFF4A0000)),
                MeshGradientPoint(
                    position: const Offset(0.7, 0.0),
                    color: const Color(0xFF2C0000)),
              ]
            : [
                MeshGradientPoint(
                    position: const Offset(0.0, 0.3),
                    color: const Color(0xFFFFB0B0)),
                MeshGradientPoint(
                    position: const Offset(1.0, 0.2),
                    color: const Color(0xFFFFFFFF)),
                MeshGradientPoint(
                    position: const Offset(0.3, 1.0),
                    color: const Color(0xFFFFD8D8)),
                MeshGradientPoint(
                    position: const Offset(0.7, 0.0),
                    color: const Color(0xFFFFE0E0)),
              ];
      }
    } else {
      if (balance < 100000) {
        if (balance < 10000) {
          return isDarkMode
              ? [
                  MeshGradientPoint(
                      position: const Offset(0.2, 0.1),
                      color: const Color(0xFF000000)),
                  MeshGradientPoint(
                      position: const Offset(0.8, 0.3),
                      color: const Color(0xFF0F4A0F)),
                  MeshGradientPoint(
                      position: const Offset(0.1, 0.8),
                      color: const Color(0xFF004000)),
                  MeshGradientPoint(
                      position: const Offset(0.9, 0.9),
                      color: const Color(0xFF1C1C1E)),
                ]
              : [
                  MeshGradientPoint(
                      position: const Offset(0.2, 0.1),
                      color: const Color(0xFFFFFFFF)),
                  MeshGradientPoint(
                      position: const Offset(0.8, 0.3),
                      color: const Color(0xFFE8F5E8)),
                  MeshGradientPoint(
                      position: const Offset(0.1, 0.8),
                      color: const Color(0xFFF0F8F0)),
                  MeshGradientPoint(
                      position: const Offset(0.9, 0.9),
                      color: const Color(0xFFF2F2F7)),
                ];
        } else {
          return isDarkMode
              ? [
                  MeshGradientPoint(
                      position: const Offset(0.0, 0.2),
                      color: const Color(0xFF006600)),
                  MeshGradientPoint(
                      position: const Offset(1.0, 0.0),
                      color: const Color(0xFF000000)),
                  MeshGradientPoint(
                      position: const Offset(0.2, 1.0),
                      color: const Color(0xFF004000)),
                  MeshGradientPoint(
                      position: const Offset(0.8, 0.8),
                      color: const Color(0xFF0F4A0F)),
                ]
              : [
                  MeshGradientPoint(
                      position: const Offset(0.0, 0.2),
                      color: const Color(0xFFD4F4D4)),
                  MeshGradientPoint(
                      position: const Offset(1.0, 0.0),
                      color: const Color(0xFFFFFFFF)),
                  MeshGradientPoint(
                      position: const Offset(0.2, 1.0),
                      color: const Color(0xFFE0F7E0)),
                  MeshGradientPoint(
                      position: const Offset(0.8, 0.8),
                      color: const Color(0xFFC8F0C8)),
                ];
        }
      } else {
        return isDarkMode
            ? [
                MeshGradientPoint(
                    position: const Offset(0.1, 0.1),
                    color: const Color(0xFFFFD700)),
                MeshGradientPoint(
                    position: const Offset(0.9, 0.2),
                    color: const Color(0xFF4169E1)),
                MeshGradientPoint(
                    position: const Offset(0.2, 0.9),
                    color: const Color(0xFF8A2BE2)),
                MeshGradientPoint(
                    position: const Offset(0.8, 0.8),
                    color: const Color(0xFF000000)),
                MeshGradientPoint(
                    position: const Offset(0.5, 0.5),
                    color: const Color(0xFF9370DB)),
              ]
            : [
                MeshGradientPoint(
                    position: const Offset(0.1, 0.1),
                    color: const Color(0xFFFFD700)),
                MeshGradientPoint(
                    position: const Offset(0.9, 0.2),
                    color: const Color(0xFF87CEEB)),
                MeshGradientPoint(
                    position: const Offset(0.2, 0.9),
                    color: const Color(0xFFDDA0DD)),
                MeshGradientPoint(
                    position: const Offset(0.8, 0.8),
                    color: const Color(0xFFFFFFFF)),
                MeshGradientPoint(
                    position: const Offset(0.5, 0.5),
                    color: const Color(0xFFE6E6FA)),
              ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            MeshGradient(
              points: _getMeshPointsForBalance(),
              options: MeshGradientOptions(
                blend: 2.5,
                noiseIntensity: 0.15,
              ),
            ),
            const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic Mesh Gradient Background
          MeshGradient(
            points: _getMeshPointsForBalance(),
            options: MeshGradientOptions(
              blend: 2.5,
              noiseIntensity: 0.15,
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: backgroundColor.withOpacity(0.1),
          ),
          // Safe Area wrapper for iOS
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF007AFF),
              child: Column(
                children: [
                  _buildHeader(),
                  if (showNotificationPanel) _buildNotificationPanel(),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildExpenseSection(),
                              const SizedBox(height: 12),
                              _buildIncomeSection(),
                              const SizedBox(height: 12),
                              _buildNetBalanceSection(),
                              const SizedBox(height: 12),
                              _buildCategoryProgressSection(),
                              const SizedBox(height: 12),
                              _buildSmartSuggestionsPanel(),
                              const SizedBox(height: 12),
                              _buildSpendingStreaksPanel(),
                              const SizedBox(height: 12),
                              _buildTodaysLogSection(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildPayTrackCard()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildLogBookCard()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildProfileCard()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildSettingsCard()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (showControlPanel) _buildControlPanel(),
                              const SizedBox(height: 34),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseStatusIndicator() {
    return FutureBuilder<String>(
      future: FirebaseService.getFirebaseStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final status = snapshot.data!;
          final isConnected = status.contains('✅');

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isConnected
                  ? const Color(0xFF34C759).withOpacity(0.2)
                  : const Color(0xFFFF3B30).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isConnected
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF3B30),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'Cloud' : 'Local',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 15, top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
            animation: _balanceController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  double time = DateTime.now().millisecondsSinceEpoch / 5000.0;
                  return LinearGradient(
                    colors: [
                      Color.lerp(Colors.black, const Color(0xFF2C3E50),
                          0.5 + 0.5 * math.sin(time))!,
                      Color.lerp(
                          const Color.fromARGB(255, 0, 255, 0),
                          const Color.fromARGB(255, 30, 63, 0),
                          0.5 + 0.5 * math.sin(time + 1))!,
                      Color.lerp(
                          const Color.fromARGB(211, 58, 35, 0),
                          const Color(0xFFFFA500),
                          0.5 + 0.5 * math.sin(time + 2))!,
                    ],
                    begin: Alignment(
                      0.3 * math.sin(time * 0.2),
                      0.3 * math.cos(time * 0.3),
                    ),
                    end: Alignment(
                      -0.3 * math.sin(time * 0.25),
                      -0.3 * math.cos(time * 0.35),
                    ),
                  ).createShader(bounds);
                },
                child: const Text(
                  'SWYPSHYT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              _buildFirebaseStatusIndicator(),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    showNotificationPanel = !showNotificationPanel;
                  });
                  if (showNotificationPanel) {
                    _generateNotifications();
                    _notificationController.forward();
                    Future.delayed(const Duration(milliseconds: 500), () {
                      setState(() {
                        hasUnseenNotifications = false;
                      });
                    });
                  } else {
                    _notificationController.reverse();
                  }
                },
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    if (hasUnseenNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34C759),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _generateNotifications() {
    notifications.clear();

    var foodSpent = spentEntries
        .where((e) => e.category == 'food')
        .fold(0.0, (sum, entry) => sum + entry.amount);
    if (foodSpent > 4000) {
      notifications.add({
        'title': 'Budget Alert',
        'message': 'Food budget 80% used (₹${foodSpent.toInt()}/₹5000)',
        'type': 'warning',
        'isRead': false,
        'time': DateTime.now(),
      });
    }

    if (netBalance > 0) {
      notifications.add({
        'title': 'Achievement Unlocked!',
        'message': 'Positive balance maintained 🎉',
        'type': 'success',
        'isRead': false,
        'time': DateTime.now(),
      });
    }

    if (pendingPayments > 0) {
      notifications.add({
        'title': 'Payment Reminder',
        'message': '₹${pendingPayments.toInt()} pending from gigs',
        'type': 'info',
        'isRead': false,
        'time': DateTime.now(),
      });
    }

    if (notifications.isEmpty) {
      notifications.add({
        'title': 'All Good!',
        'message': 'Your finances are looking healthy 💚',
        'type': 'success',
        'isRead': false,
        'time': DateTime.now(),
      });
    }
  }

  Widget _buildNotificationPanel() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_notificationAnimation),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications,
                        color: Color(0xFF007AFF), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      for (var notification in notifications) {
                        notification['isRead'] = true;
                      }
                    });
                  },
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 12,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  var notification = notifications[index];
                  bool isRead = notification['isRead'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color:
                          isRead ? surfaceColor.withOpacity(0.5) : surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRead
                                ? subtitleColor.withOpacity(0.5)
                                : const Color(0xFF007AFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['title'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isRead ? subtitleColor : textColor,
                                  fontFamily: 'SFProDisplay',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['message'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isRead
                                      ? subtitleColor.withOpacity(0.7)
                                      : subtitleColor,
                                  fontFamily: 'SFProDisplay',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(notification['time']),
                          style: TextStyle(
                            fontSize: 10,
                            color: subtitleColor.withOpacity(0.7),
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFF3B30),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Expenses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(totalSpent),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      showSpentForm = !showSpentForm;
                    });
                    if (showSpentForm) {
                      _spentFormController.forward();
                    } else {
                      _spentFormController.reverse();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B30).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 300),
                          turns: showSpentForm ? 0.125 : 0,
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Expense',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showSpentForm) _buildExpenseForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm() {
    return SlideTransition(
      position: _spentSlideAnimation,
      child: FadeTransition(
        opacity: _spentFormAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFFF3B30).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAmountField(
                controller: spentAmountController,
                onSubmitted: _addSpentEntry,
              ),
              const SizedBox(height: 12),
              _buildNameField(
                controller: spentNameController,
                hintText: 'What did you spend on?',
                onSubmitted: _addSpentEntry,
              ),
              const SizedBox(height: 12),
              _buildToggleSwitch(
                leftLabel: 'Non-Recoverable',
                rightLabel: 'Recoverable',
                value: spentRecoverable,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    spentRecoverable = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _buildActionButton(
                onTap: _addSpentEntry,
                label: 'Add Expense',
                color: const Color(0xFFFF3B30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF34C759),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(totalGot),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      showGotForm = !showGotForm;
                    });
                    if (showGotForm) {
                      _gotFormController.forward();
                    } else {
                      _gotFormController.reverse();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34C759).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 300),
                          turns: showGotForm ? 0.125 : 0,
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Income',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showGotForm) _buildIncomeForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeForm() {
    return SlideTransition(
      position: _gotSlideAnimation,
      child: FadeTransition(
        opacity: _gotFormAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF34C759).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAmountField(
                controller: gotAmountController,
                onSubmitted: _addGotEntry,
              ),
              const SizedBox(height: 12),
              _buildNameField(
                controller: gotNameController,
                hintText: 'Source of income',
                onSubmitted: _addGotEntry,
              ),
              const SizedBox(height: 12),
              _buildToggleSwitch(
                leftLabel: 'To Return',
                rightLabel: 'All Mine',
                value: gotAllMine,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    gotAllMine = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _buildActionButton(
                onTap: _addGotEntry,
                label: 'Add Income',
                color: const Color(0xFF34C759),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required VoidCallback onSubmitted,
  }) {
    return NumbersOnlyInput(
      controller: controller,
      placeholder: 'Amount (₹)',
      textColor: textColor,
      inputFieldColor: inputFieldColor,
      borderColor: borderColor,
      hintTextColor: hintTextColor,
      onSubmitted: onSubmitted,
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onSubmitted,
  }) {
    return CupertinoTextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: (_) => onSubmitted(),
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'SFProDisplay',
      ),
      decoration: BoxDecoration(
        color: inputFieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      placeholder: hintText,
      placeholderStyle: TextStyle(
        color: hintTextColor.withOpacity(0.5),
        fontSize: 16,
        fontFamily: 'SFProDisplay',
      ),
    );
  }

  Widget _buildToggleSwitch({
    required String leftLabel,
    required String rightLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            leftLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF34C759),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            rightLabel,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
    );
  }

  Widget _buildNetBalanceSection() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));

    double todaySpent = spentEntries
        .where(
            (e) => e.timestamp.isAfter(today) && e.timestamp.isBefore(tomorrow))
        .fold(0.0, (sum, entry) => sum + entry.amount);

    double todayEarned = gotEntries
        .where(
            (e) => e.timestamp.isAfter(today) && e.timestamp.isBefore(tomorrow))
        .fold(0.0, (sum, entry) => sum + entry.amount);

    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    double monthlySpent = spentEntries
        .where((e) =>
            e.timestamp.isAfter(startOfMonth) &&
            e.timestamp.isBefore(endOfMonth))
        .fold(0.0, (sum, entry) => sum + entry.amount);

    double monthlyEarned = gotEntries
        .where((e) =>
            e.timestamp.isAfter(startOfMonth) &&
            e.timestamp.isBefore(endOfMonth))
        .fold(0.0, (sum, entry) => sum + entry.amount);

    String balanceText = _formatCurrency(netBalance);
    double fontSize = 32.0;
    if (balanceText.length >= 8) {
      fontSize = 24.0;
    } else if (balanceText.length >= 6) {
      fontSize = 28.0;
    } else if (balanceText.length <= 4) {
      fontSize = 40.0;
    }

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Color(0xFF007AFF), size: 24),
              const SizedBox(width: 10),
              Text(
                'NET BALANCE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 1.2,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ScaleTransition(
            scale: _balanceScaleAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(netBalance),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: netBalance >= 0
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30),
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildStatsRow('Today', todaySpent, todayEarned),
          const SizedBox(height: 15),
          _buildStatsRow('Monthly', monthlySpent, monthlyEarned),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String label, double spent, double earned) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '$label Spent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatCurrency(spent),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B30),
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: borderColor,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$label Earned',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatCurrency(earned),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF34C759),
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.pie_chart, color: Color(0xFF007AFF), size: 24),
                const SizedBox(width: 10),
                Text(
                  'Category Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryPeriod = 'Daily';
                          _cachedCategoryData = null;
                        });
                        _saveThemePreference();
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedCategoryPeriod == 'Daily'
                              ? const Color(0xFF007AFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          DateFormat('dd').format(DateTime.now()),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedCategoryPeriod == 'Daily'
                                ? Colors.white
                                : textColor,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryPeriod = 'Monthly';
                          _cachedCategoryData = null;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedCategoryPeriod == 'Monthly'
                              ? const Color(0xFF007AFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          DateFormat('MMM').format(DateTime.now()),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedCategoryPeriod == 'Monthly'
                                ? Colors.white
                                : textColor,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryPeriod = 'Yearly';
                          _cachedCategoryData = null;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedCategoryPeriod == 'Yearly'
                              ? const Color(0xFF007AFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${DateTime.now().year}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedCategoryPeriod == 'Yearly'
                                ? Colors.white
                                : textColor,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCategoryPeriodView(selectedCategoryPeriod),
        ],
      ),
    );
  }

// REPLACE your _buildCategoryPeriodView method with this:

  Widget _buildCategoryPeriodView(String period) {
    var data = _getCategoryDataForPeriod(period);
    Map<String, double> expenseCategories =
        data['expenses']; // FIXED: String keys
    Map<String, double> incomeCategories = data['income']; // FIXED: String keys
    double totalSpentAmount = data['totalSpent'];
    double totalIncomeAmount = data['totalIncome'];

    if (totalSpentAmount == 0 && totalIncomeAmount == 0) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 40,
              color: subtitleColor.withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'No transactions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
                fontFamily: 'SFProDisplay',
              ),
            ),
          ],
        ),
      );
    }

    List<MapEntry<String, double>> sortedExpenses = expenseCategories.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, double>> sortedIncome = incomeCategories.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalSpentAmount > 0) ...[
            Row(
              children: [
                const Icon(Icons.trending_down,
                    color: Color(0xFFFF3B30), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Spent: ${_formatCurrency(totalSpentAmount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: surfaceColor,
              ),
              child: Row(
                children: sortedExpenses.take(5).map((entry) {
                  double percentage = entry.value / totalSpentAmount;
                  return Expanded(
                    flex: (percentage * 100).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CustomCategoryManager.getCategoryColor(
                            entry.key), // FIXED: Use CustomCategoryManager
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            ...sortedExpenses.take(4).map((entry) {
              double percentage = (entry.value / totalSpentAmount) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CustomCategoryManager.getCategoryColor(
                            entry.key), // FIXED: Use CustomCategoryManager
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        CustomCategoryManager.getCategoryName(
                            entry.key), // FIXED: Use CustomCategoryManager
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(entry.value),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF3B30),
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          if (totalIncomeAmount > 0) ...[
            if (totalSpentAmount > 0) const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.trending_up,
                    color: Color(0xFF34C759), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Earned: ${_formatCurrency(totalIncomeAmount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: surfaceColor,
              ),
              child: Row(
                children: sortedIncome.take(5).map((entry) {
                  double percentage = entry.value / totalIncomeAmount;
                  return Expanded(
                    flex: (percentage * 100).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CustomCategoryManager.getCategoryColor(
                            entry.key), // FIXED: Use CustomCategoryManager
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            ...sortedIncome.take(4).map((entry) {
              double percentage = (entry.value / totalIncomeAmount) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CustomCategoryManager.getCategoryColor(
                            entry.key), // FIXED: Use CustomCategoryManager
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        CustomCategoryManager.getCategoryName(
                            entry.key), // FIXED: Use CustomCategoryManager
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatCurrency(entry.value),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF34C759),
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryDataForPeriod(String period) {
    DateTime now = DateTime.now();
    if (_cachedCategoryData != null &&
        _lastCacheTime != null &&
        _lastCachedPeriod == period &&
        now.difference(_lastCacheTime!).inMinutes < 5) {
      return _cachedCategoryData!;
    }

    Map<String, double> expenseCategories = {}; // FIXED: String keys
    Map<String, double> incomeCategories = {}; // FIXED: String keys
    double totalSpentAmount = 0;
    double totalIncomeAmount = 0;

    // FIXED: Define startDate and endDate properly
    DateTime startDate, endDate;

    switch (period) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
    }

    List<ExpenseEntry> periodExpenses = spentEntries
        .where((e) =>
            e.timestamp.isAfter(startDate) && e.timestamp.isBefore(endDate))
        .toList();

    for (ExpenseEntry entry in periodExpenses) {
      // FIXED: entry.category is now a String
      expenseCategories[entry.category] =
          (expenseCategories[entry.category] ?? 0) + entry.amount;
      totalSpentAmount += entry.amount;
    }

    List<IncomeEntry> periodIncome = gotEntries
        .where((e) =>
            e.timestamp.isAfter(startDate) && e.timestamp.isBefore(endDate))
        .toList();

    for (IncomeEntry entry in periodIncome) {
      // FIXED: entry.category is now a String
      incomeCategories[entry.category] =
          (incomeCategories[entry.category] ?? 0) + entry.amount;
      totalIncomeAmount += entry.amount;
    }

    _cachedCategoryData = {
      'expenses': expenseCategories,
      'income': incomeCategories,
      'totalSpent': totalSpentAmount,
      'totalIncome': totalIncomeAmount,
    };
    _lastCacheTime = now;
    _lastCachedPeriod = period;
    return _cachedCategoryData!;
  }

  Widget _buildSmartSuggestionsPanel() {
    List<String> suggestions = _getSmartSuggestions();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Color(0xFFFF9500), size: 24),
              const SizedBox(width: 10),
              Text(
                'Smart Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: PageController(viewportFraction: 1.0),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9500).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    suggestions[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.4,
                      fontFamily: 'SFProDisplay',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSmartSuggestions() {
    List<String> suggestions = [];
    double balance = netBalance;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));

    double todaySpent = spentEntries
        .where(
            (e) => e.timestamp.isAfter(today) && e.timestamp.isBefore(tomorrow))
        .fold(0.0, (sum, entry) => sum + entry.amount);

    if (balance == 0) {
      suggestions.add(
          "Perfect balance! You're living paycheck to paycheck like a pro 💯");
    } else if (balance < -1000) {
      suggestions.add(
          "Wallet's crying harder than a Bollywood movie. Time to hustle! 😭");
    } else if (balance < 0) {
      suggestions.add("Red alert! Your account needs CPR 🚨");
    } else if (balance > 100000) {
      suggestions
          .add("Rich vibes! Your money's making money while you sleep 🤑");
    } else if (balance > 10000) {
      suggestions.add(
          "Looking good! Your wallet's doing yoga - balanced and flexible 🧘");
    }

    if (todaySpent > 1000) {
      suggestions.add(
          "₹${todaySpent.toInt()} spent today. Your wallet needs a break 💸");
    }

    var foodSpent = spentEntries
        .where((e) => e.category == 'food') // ✅ FIXED
        .fold(0.0, (sum, entry) => sum + entry.amount);
    if (foodSpent > 5000) {
      suggestions.add(
          "₹${foodSpent.toInt()} on food this month. Swiggy's new best friend 🍕");
    }

    var gfSpent = spentEntries
        .where((e) => e.category == 'girlfriend') // ✅ FIXED
        .fold(0.0, (sum, entry) => sum + entry.amount);
    var gfEarned = gotEntries
        .where((e) => e.category == 'girlfriend') // ✅ FIXED
        .fold(0.0, (sum, entry) => sum + entry.amount);
    if (gfSpent > gfEarned && gfSpent > 2000) {
      suggestions.add(
          "Love costs ₹${(gfSpent - gfEarned).toInt()} more than it pays. Romance ain't cheap 💝");
    }

    var momSpent = spentEntries
        .where((e) => e.category == 'mom') // ✅ FIXED
        .fold(0.0, (sum, entry) => sum + entry.amount);
    var momEarned = gotEntries
        .where((e) => e.category == 'mom') // ✅ FIXED
        .fold(0.0, (sum, entry) => sum + entry.amount);
    if (momEarned > momSpent && momEarned > 1000) {
      suggestions.add(
          "Mom gave ₹${momEarned.toInt()}, you spent ₹${momSpent.toInt()} on her. Good son points! 👩");
    }

    if (pendingPayments > 0) {
      suggestions.add(
          "₹${pendingPayments.toInt()} pending from gigs. Time to chase those payments! 🎵");
    }

    if (suggestions.isEmpty) {
      suggestions.addAll([
        "Track your money like a hawk. Every rupee counts! 🦅",
        "Small expenses add up faster than you think 🤔",
        "Your future self will thank you for saving today 🙏",
      ]);
    }

    return suggestions.take(5).toList();
  }

  Widget _buildSpendingStreaksPanel() {
    _calculateStreaks();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Color(0xFFFF9500), size: 24),
              const SizedBox(width: 10),
              Text(
                'Spending Streaks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildStreakCard(
                'Current Streak',
                '$currentSavingStreak days',
                'Under budget',
                const Color(0xFF34C759),
                Icons.trending_up,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStreakCard(
                'Best Streak',
                '$longestSavingStreak days',
                'Personal record',
                const Color(0xFFFF9500),
                Icons.emoji_events,
              )),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _buildStreakCard(
                'Budget Days',
                '$daysUnderBudget days',
                'This month',
                const Color(0xFF007AFF),
                Icons.account_balance_wallet,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStreakCard(
                'Net Balance',
                netBalance >= 0 ? 'Positive' : 'Negative',
                _formatCurrency(netBalance.abs()),
                netBalance >= 0
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
                netBalance >= 0 ? Icons.check_circle : Icons.warning,
              )),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF9500).withOpacity(0.2),
              ),
            ),
            child: Text(
              _getStreakMotivation(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
                fontStyle: FontStyle.italic,
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
      String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'SFProDisplay',
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: subtitleColor,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  void _calculateStreaks() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    int budgetDays = 0;

    for (int i = 1; i <= now.day; i++) {
      DateTime checkDate = DateTime(now.year, now.month, i);
      DateTime nextDay = checkDate.add(const Duration(days: 1));

      double daySpent = spentEntries
          .where((e) =>
              e.timestamp.isAfter(checkDate) && e.timestamp.isBefore(nextDay))
          .fold(0.0, (sum, entry) => sum + entry.amount);

      if (daySpent <= dailyBudget) {
        budgetDays++;
      }
    }

    setState(() {
      daysUnderBudget = budgetDays;
    });

    double todaySpent = spentEntries
        .where((e) =>
            e.timestamp.isAfter(today) &&
            e.timestamp.isBefore(today.add(const Duration(days: 1))))
        .fold(0.0, (sum, entry) => sum + entry.amount);

    if (todaySpent <= dailyBudget) {
      if (lastStreakUpdate.day != now.day) {
        currentSavingStreak++;
        lastStreakUpdate = now;
      }
    } else {
      currentSavingStreak = 0;
    }

    if (currentSavingStreak > longestSavingStreak) {
      longestSavingStreak = currentSavingStreak;
      _saveStreakData();
    }
  }

  String _getStreakMotivation() {
    if (currentSavingStreak >= 7) {
      return "🔥 Week-long streak! You're on fire! Keep it going!";
    } else if (currentSavingStreak >= 3) {
      return "💪 Great momentum! ${7 - currentSavingStreak} more days for a week streak!";
    } else if (currentSavingStreak >= 1) {
      return "⭐ Good start! Every journey begins with a single step.";
    } else if (netBalance > 0) {
      return "💚 Positive balance! You're doing great with your finances.";
    } else {
      return "🎯 New day, new opportunities! You've got this!";
    }
  }

  Widget _buildTodaysLogSection() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));

    List<dynamic> todaysEntries = [];
    todaysEntries.addAll(spentEntries
        .where(
            (e) => e.timestamp.isAfter(today) && e.timestamp.isBefore(tomorrow))
        .map((e) => {'type': 'spent', 'entry': e}));
    todaysEntries.addAll(gotEntries
        .where(
            (e) => e.timestamp.isAfter(today) && e.timestamp.isBefore(tomorrow))
        .map((e) => {'type': 'got', 'entry': e}));
    todaysEntries.sort((a, b) {
      DateTime timeA = a['entry'].timestamp;
      DateTime timeB = b['entry'].timestamp;
      return timeB.compareTo(timeA);
    });

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.today, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Today\'s Log',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
                Text(
                  '${todaysEntries.length} entries',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: todaysEntries.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(15),
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: todaysEntries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildLogEntry(todaysEntries[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: subtitleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 15),
          Text(
            'No transactions today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: subtitleColor.withOpacity(0.7),
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an expense or income to get started',
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor.withOpacity(0.6),
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> logEntry, int index) {
    bool isIncome = logEntry['type'] == 'got';
    dynamic entry = logEntry['entry'];

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeleteDialog(
          context,
          'Delete Entry',
          'Remove this entry?',
          () {
            if (isIncome) {
              _deleteGotEntry(entry.id);
            } else {
              _deleteSpentEntry(entry.id);
            }
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isIncome
                ? const Color(0xFF34C759).withOpacity(0.2)
                : const Color(0xFFFF3B30).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: isIncome
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            getCategoryIcon(entry.category, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(entry.timestamp),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${_formatCurrency(entry.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isIncome
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      fontFamily: 'SFProDisplay',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getCategoryIcon(String categoryId, {double size = 16, Color? color}) {
    // Use the CustomCategoryManager to get the icon
    IconData iconData = CustomCategoryManager.getCategoryIcon(categoryId);
    Color iconColor =
        color ?? CustomCategoryManager.getCategoryColor(categoryId);

    return Icon(iconData, size: size, color: iconColor);
  }

  Widget _buildPayTrackCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showPayTrackDialog();
      },
      child: Container(
        height: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'PayTrack',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${payTrackEntries.where((e) => !e.isPaid).length} pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogBookCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showLogBookDialog();
      },
      child: Container(
        height: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'LogBook',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'View Log',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showProfileDialog();
      },
      child: Container(
        height: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                userName.isEmpty ? 'Profile' : userName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Budget: ₹${dailyBudget.toInt()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          showControlPanel = !showControlPanel;
        });
        if (showControlPanel) {
          _controlPanelController.forward();
        } else {
          _controlPanelController.reverse();
        }
      },
      child: Container(
        height: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                showControlPanel ? 'Close panel' : 'Open panel',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return FadeTransition(
      opacity: _controlPanelAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_controlPanelAnimation),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: textColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Control Panel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.download,
                      onTap: _exportData,
                      label: 'Export',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildControlButton(
                      icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      onTap: _toggleDarkMode,
                      label: isDarkMode ? 'Light' : 'Dark',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.refresh,
                      onTap: _showResetDataDialog,
                      isDestructive: true,
                      label: 'Reset',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFF3B30).withOpacity(0.1)
              : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: isDestructive
              ? Border.all(color: const Color(0xFFFF3B30).withOpacity(0.3))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDestructive ? const Color(0xFFFF3B30) : textColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDestructive ? const Color(0xFFFF3B30) : textColor,
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDataDialog() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Reset Data'),
        message: const Text('Choose what data to reset'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _resetTodayData();
            },
            child: const Text('Reset Today\'s Data'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _resetAllData();
            },
            isDestructiveAction: true,
            child: const Text('Reset All Data'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _resetTodayData() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));

    setState(() {
      spentEntries.removeWhere(
          (e) => e.timestamp.isAfter(today) && e.timestamp.isBefore(tomorrow));
      gotEntries.removeWhere(
          (e) => e.timestamp.isAfter(today) && e.timestamp.isBefore(tomorrow));
      _cachedCategoryData = null;
    });

    _saveData();
    _showSnackBar('Today\'s data reset successfully');
    HapticFeedback.mediumImpact();
  }

  void _resetAllData() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
            'This will permanently delete all your data. This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                spentEntries.clear();
                gotEntries.clear();
                payTrackEntries.clear();
                _cachedCategoryData = null;
              });
              _saveData();
              _showSnackBar('All data reset successfully');
              HapticFeedback.heavyImpact();
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Simplified modal dialogs for iOS
  void _addPayTrackEntry() {
    if (!_validateAmount(payTrackAmountController.text)) {
      _showSnackBar('Please enter a valid amount', isError: true);
      return;
    }

    if (!_validateName(payTrackNameController.text)) {
      _showSnackBar('Please enter a valid gig name', isError: true);
      return;
    }

    if (!_validateName(payTrackEventTitleController.text)) {
      _showSnackBar('Please enter a valid event title', isError: true);
      return;
    }

    try {
      double amount = double.parse(payTrackAmountController.text);

      PayTrackEntry newEntry = PayTrackEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        name: payTrackNameController.text.trim(),
        eventTitle: payTrackEventTitleController.text.trim(),
        eventDate: selectedEventDate,
        dateAdded: DateTime.now(),
      );

      setState(() {
        payTrackEntries.insert(0, newEntry);
        payTrackAmountController.clear();
        payTrackNameController.clear();
        payTrackEventTitleController.clear();
        selectedEventDate = DateTime.now();
      });

      _saveData();
      HapticFeedback.mediumImpact();
      _showSnackBar('Gig added to PayTrack!');
    } catch (e) {
      _showSnackBar('Error adding gig: ${e.toString()}', isError: true);
    }
  }

  void _markAsPaid(PayTrackEntry entry) {
    setState(() {
      int index = payTrackEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        payTrackEntries[index] =
            entry.copyWith(isPaid: true, paidDate: DateTime.now());

        IncomeEntry incomeEntry = IncomeEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: entry.amount,
          name: '${entry.name} - ${entry.eventTitle}',
          allMine: true,
          timestamp: DateTime.now(),
          category: 'gigs',
        );
        gotEntries.insert(0, incomeEntry);
      }
    });

    _animateBalanceChange();
    _saveData();
    HapticFeedback.heavyImpact();
    _showSnackBar('Payment received! Added to Gigs income.');
  }

  void _showPayTrackDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: modalBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF32D74B), Color(0xFF30D158)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PayTrack',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'SFProDisplay',
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${pendingPayments.toInt()}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    Text(
                                      '${payTrackEntries.where((e) => !e.isPaid).length} gigs',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${payTrackEntries.where((e) => e.isPaid).fold(0.0, (sum, e) => sum + e.amount).toInt()}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    Text(
                                      '${payTrackEntries.where((e) => e.isPaid).length} gigs',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Gig',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 15),
                          CupertinoTextField(
                            controller: payTrackAmountController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                                color: textColor, fontFamily: 'SFProDisplay'),
                            decoration: BoxDecoration(
                              color: inputFieldColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            padding: const EdgeInsets.all(16),
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(Icons.currency_rupee,
                                  color: Color(0xFF32D74B)),
                            ),
                            placeholder: 'Payment Amount (₹)',
                            placeholderStyle: TextStyle(
                                color: hintTextColor.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 15),
                          CupertinoTextField(
                            controller: payTrackNameController,
                            style: TextStyle(
                                color: textColor, fontFamily: 'SFProDisplay'),
                            decoration: BoxDecoration(
                              color: inputFieldColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            padding: const EdgeInsets.all(16),
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(Icons.music_note,
                                  color: Color(0xFF32D74B)),
                            ),
                            placeholder: 'Gig Name (e.g., "DJ Set")',
                            placeholderStyle: TextStyle(
                                color: hintTextColor.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 15),
                          CupertinoTextField(
                            controller: payTrackEventTitleController,
                            style: TextStyle(
                                color: textColor, fontFamily: 'SFProDisplay'),
                            decoration: BoxDecoration(
                              color: inputFieldColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            padding: const EdgeInsets.all(16),
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child:
                                  Icon(Icons.event, color: Color(0xFF32D74B)),
                            ),
                            placeholder: 'Event/Venue',
                            placeholderStyle: TextStyle(
                                color: hintTextColor.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Color(0xFF32D74B), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Event Date: ${_formatDate(selectedEventDate)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedEventDate,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 30)),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        selectedEventDate = picked;
                                      });
                                    }
                                  },
                                  child: const Text('Change',
                                      style:
                                          TextStyle(color: Color(0xFF32D74B))),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              _addPayTrackEntry();
                              setDialogState(() {});
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF32D74B),
                                    Color(0xFF30D158)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Add Gig to PayTrack',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SFProDisplay',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Your Gigs (${payTrackEntries.length} total)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (payTrackEntries.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.music_off,
                                      size: 48,
                                      color: subtitleColor.withOpacity(0.5)),
                                  const SizedBox(height: 15),
                                  Text(
                                    'No gigs tracked yet',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: subtitleColor),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...payTrackEntries
                                .map((entry) => Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: modalSurfaceColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: entry.isPaid
                                              ? const Color(0xFF32D74B)
                                                  .withOpacity(0.3)
                                              : const Color(0xFF007AFF)
                                                  .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                entry.isPaid
                                                    ? Icons.check_circle
                                                    : Icons.schedule,
                                                color: entry.isPaid
                                                    ? const Color(0xFF32D74B)
                                                    : const Color(0xFF007AFF),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '${entry.name} - ${entry.eventTitle}',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                      color: textColor),
                                                ),
                                              ),
                                              Text(
                                                _formatCurrency(entry.amount),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                  color: entry.isPaid
                                                      ? const Color(0xFF32D74B)
                                                      : textColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Event: ${_formatDate(entry.eventDate)}',
                                              style: TextStyle(
                                                  color: subtitleColor)),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  entry.isPaid
                                                      ? 'Paid on ${_formatDate(entry.paidDate!)}'
                                                      : 'Pending payment',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: entry.isPaid
                                                        ? const Color(
                                                            0xFF32D74B)
                                                        : subtitleColor,
                                                  ),
                                                ),
                                              ),
                                              if (!entry.isPaid)
                                                GestureDetector(
                                                  onTap: () {
                                                    _markAsPaid(entry);
                                                    setDialogState(() {});
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF32D74B),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Text(
                                                      'Mark Paid',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// REPLACE your _showLogBookDialog method with this enhanced version

  void _showLogBookDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<dynamic> filteredEntries = _getFilteredLogData();

            // Get all available categories (original + custom)
            List<String> allCategories = ['All'];
            allCategories.addAll(Category.values
                .map((e) => TransactionClassifier.getCategoryName(e)));
            allCategories.addAll(
                CustomCategoryManager.customCategories.map((e) => e.name));

            return Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: modalBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LogBook',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                        Row(
                          children: [
                            // NEW: Manage Categories Button
                            IconButton(
                              onPressed: () =>
                                  _showManageCategoriesDialog(setDialogState),
                              icon: const Icon(Icons.settings,
                                  color: Colors.white, size: 20),
                              tooltip: 'Manage Categories',
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          style: TextStyle(
                              color: textColor, fontFamily: 'SFProDisplay'),
                          decoration: BoxDecoration(
                            color: inputFieldColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          padding: const EdgeInsets.all(16),
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Icon(Icons.search, color: subtitleColor),
                          ),
                          placeholder: 'Search transactions...',
                          placeholderStyle: TextStyle(
                              color: subtitleColor, fontFamily: 'SFProDisplay'),
                          onChanged: (value) {
                            setDialogState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: inputFieldColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedLogPeriod,
                                    dropdownColor: modalSurfaceColor,
                                    style: TextStyle(
                                        color: textColor,
                                        fontFamily: 'SFProDisplay'),
                                    items: ['This Month', 'Selected Date']
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value,
                                            style: TextStyle(
                                                color: textColor,
                                                fontFamily: 'SFProDisplay')),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setDialogState(() {
                                        selectedLogPeriod = newValue!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: inputFieldColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedCategoryFilter,
                                          dropdownColor: modalSurfaceColor,
                                          style: TextStyle(
                                              color: textColor,
                                              fontFamily: 'SFProDisplay'),
                                          items:
                                              allCategories.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value,
                                                  style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 14)),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setDialogState(() {
                                              selectedCategoryFilter =
                                                  newValue!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    // NEW: + Button for adding categories
                                    GestureDetector(
                                      onTap: () async {
                                        final result = await showDialog<bool>(
                                          context: context,
                                          builder: (context) =>
                                              const AddCategoryDialog(),
                                        );

                                        if (result == true) {
                                          setDialogState(() {
                                            // Refresh the categories list
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  '✅ Category added successfully!'),
                                              backgroundColor:
                                                  Color(0xFF34C759),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF007AFF),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                      height: 1,
                      color: borderColor,
                      margin: const EdgeInsets.symmetric(horizontal: 20)),
                  Expanded(
                    child: filteredEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.book_outlined,
                                    size: 48,
                                    color: subtitleColor.withOpacity(0.5)),
                                const SizedBox(height: 15),
                                Text(
                                  'No entries found',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: subtitleColor,
                                      fontFamily: 'SFProDisplay'),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            color: backgroundColor,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filteredEntries.length,
                              itemBuilder: (context, index) {
                                var logEntry = filteredEntries[index];
                                bool isIncome = logEntry['type'] == 'got';
                                dynamic entry = logEntry['entry'];

                                return GestureDetector(
                                  onTap: () =>
                                      _showEditEntryDialog(entry, isIncome),
                                  onLongPress: () {
                                    _showDeleteDialog(
                                      context,
                                      'Delete Entry',
                                      'Remove this entry?',
                                      () {
                                        if (isIncome) {
                                          _deleteGotEntry(entry.id);
                                        } else {
                                          _deleteSpentEntry(entry.id);
                                        }
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: modalSurfaceColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isIncome
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            color: isIncome
                                                ? Colors.green
                                                : Colors.red,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 8),
                                          // Use enhanced category system
                                          Icon(
                                            CustomCategoryManager
                                                .getCategoryIcon(entry.category
                                                    .toString()
                                                    .split('.')
                                                    .last),
                                            size: 18,
                                            color: CustomCategoryManager
                                                .getCategoryColor(entry.category
                                                    .toString()
                                                    .split('.')
                                                    .last),
                                          ),
                                        ],
                                      ),
                                      title: Text(
                                        entry.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                            fontFamily: 'SFProDisplay'),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            _formatDate(entry.timestamp),
                                            style: TextStyle(
                                                color: subtitleColor,
                                                fontFamily: 'SFProDisplay'),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: CustomCategoryManager
                                                      .getCategoryColor(entry
                                                          .category
                                                          .toString()
                                                          .split('.')
                                                          .last)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              CustomCategoryManager
                                                  .getCategoryName(entry
                                                      .category
                                                      .toString()
                                                      .split('.')
                                                      .last),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: CustomCategoryManager
                                                    .getCategoryColor(entry
                                                        .category
                                                        .toString()
                                                        .split('.')
                                                        .last),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isIncome ? '+' : '-'}${_formatCurrency(entry.amount)}',
                                            style: TextStyle(
                                              color: isIncome
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              fontFamily: 'SFProDisplay',
                                            ),
                                          ),
                                          Text(
                                            _formatTime(entry.timestamp),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: subtitleColor,
                                                fontFamily: 'SFProDisplay'),
                                          ),
                                        ],
                                      ),
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
          },
        );
      },
    );
  }

// NEW: Manage Categories Dialog
  void _showManageCategoriesDialog(StateSetter parentSetState) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Manage Categories',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                // Add Category Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const AddCategoryDialog(),
                    );

                    if (result == true) {
                      setDialogState(() {});
                      parentSetState(() {});
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add New Category',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                // Custom Categories List
                const Text('Custom Categories:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomCategoryManager.customCategories.isEmpty
                      ? const Center(
                          child: Text(
                            'No custom categories yet.\nTap + to add one!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF8E8E93)),
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              CustomCategoryManager.customCategories.length,
                          itemBuilder: (context, index) {
                            final category =
                                CustomCategoryManager.customCategories[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: category.color.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: category.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(category.icon,
                                        color: category.color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Keywords: ${category.keywords.join(", ")}',
                                          style: const TextStyle(
                                            color: Color(0xFF8E8E93),
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              const Color(0xFF1C1C1E),
                                          title: const Text('Delete Category',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          content: Text(
                                            'Delete "${category.name}" category? Existing transactions will become "Misc".',
                                            style: const TextStyle(
                                                color: Color(0xFF8E8E93)),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF8E8E93))),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                CustomCategoryManager
                                                    .removeCategory(
                                                        category.id);
                                                Navigator.pop(context);
                                                setDialogState(() {});
                                                parentSetState(() {});
                                              },
                                              child: const Text('Delete',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFFFF3B30))),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete,
                                        color: Color(0xFFFF3B30), size: 20),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(color: Color.fromARGB(255, 160, 138, 255))),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog() {
    TextEditingController nameController =
        TextEditingController(text: userName);
    TextEditingController nicknameController =
        TextEditingController(text: userNickname);
    TextEditingController budgetController =
        TextEditingController(text: dailyBudget.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: modalBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile Setup',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      const SizedBox(height: 15),
                      CupertinoTextField(
                        controller: nameController,
                        style: TextStyle(
                            color: textColor, fontFamily: 'SFProDisplay'),
                        decoration: BoxDecoration(
                          color: inputFieldColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(16),
                        placeholder: 'Your Name',
                        placeholderStyle:
                            TextStyle(color: hintTextColor.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: nicknameController,
                        style: TextStyle(
                            color: textColor, fontFamily: 'SFProDisplay'),
                        decoration: BoxDecoration(
                          color: inputFieldColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(16),
                        placeholder: 'Nickname',
                        placeholderStyle:
                            TextStyle(color: hintTextColor.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: budgetController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: textColor, fontFamily: 'SFProDisplay'),
                        decoration: BoxDecoration(
                          color: inputFieldColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(16),
                        placeholder: 'Daily Budget (₹)',
                        placeholderStyle:
                            TextStyle(color: hintTextColor.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          _saveProfileData(
                              nameController.text,
                              nicknameController.text,
                              budgetController.text, {});
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Save Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfileData(String name, String nickname, String budget,
      Map<String, TextEditingController> familyControllers) async {
    setState(() {
      userName = name.trim();
      userNickname = nickname.trim();
      if (budget.isNotEmpty && double.tryParse(budget) != null) {
        dailyBudget = double.parse(budget);
      }
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('userNickname', userNickname);
    await prefs.setDouble('dailyBudget', dailyBudget);

    _showSnackBar('Profile saved successfully!');
    HapticFeedback.mediumImpact();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '';
      userNickname = prefs.getString('userNickname') ?? '';
      dailyBudget = prefs.getDouble('dailyBudget') ?? 1000.0;

      String? familyData = prefs.getString('familyMembers');
      if (familyData != null) {
        Map<String, dynamic> decoded = json.decode(familyData);
        familyMembers = decoded.cast<String, String>();
      }
    });
  }

  Future<void> _saveStreakData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentSavingStreak', currentSavingStreak);
    await prefs.setInt('longestSavingStreak', longestSavingStreak);
    await prefs.setInt('daysUnderBudget', daysUnderBudget);
    await prefs.setString(
        'lastStreakUpdate', lastStreakUpdate.toIso8601String());
  }

  Future<void> _loadStreakData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentSavingStreak = prefs.getInt('currentSavingStreak') ?? 0;
      longestSavingStreak = prefs.getInt('longestSavingStreak') ?? 0;
      daysUnderBudget = prefs.getInt('daysUnderBudget') ?? 0;
      String? lastUpdate = prefs.getString('lastStreakUpdate');
      if (lastUpdate != null) {
        lastStreakUpdate = DateTime.parse(lastUpdate);
      }
    });
  }
}
// Add this at the very bottom of your main.dart file

class NumbersOnlyInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final Color textColor;
  final Color inputFieldColor;
  final Color borderColor;
  final Color hintTextColor;
  final VoidCallback? onSubmitted;
  final bool allowDecimals;

  const NumbersOnlyInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.textColor,
    required this.inputFieldColor,
    required this.borderColor,
    required this.hintTextColor,
    this.onSubmitted,
    this.allowDecimals = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        _SingleDecimalFormatter(),
        LengthLimitingTextInputFormatter(10),
      ],
      onSubmitted: (_) => onSubmitted?.call(),
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'SFProDisplay',
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: inputFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 8),
          child: Text(
            '₹',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 85, 85, 85),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: placeholder,
        hintStyle: TextStyle(
          color: hintTextColor.withOpacity(0.5),
          fontSize: 16,
          fontFamily: 'SFProDisplay',
        ),
      ),
    );
  }
}

class _SingleDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    final decimalCount = '.'.allMatches(newText).length;

    if (decimalCount > 1) {
      return oldValue;
    }

    if (newText.startsWith('.')) {
      return TextEditingValue(
        text: '0$newText',
        selection: TextSelection.collapsed(offset: newText.length + 1),
      );
    }

    return newValue;
  }
}
