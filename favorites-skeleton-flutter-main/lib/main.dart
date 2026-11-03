
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/sample_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FavoritesApp());
}

class FavoritesApp extends StatefulWidget {
  const FavoritesApp({super.key});

  @override
  State<FavoritesApp> createState() => _FavoritesAppState();
}

class _FavoritesAppState extends State<FavoritesApp> {
  final Set<String> favorites = {};
  ThemeMode themeMode = ThemeMode.system;
  int selectedTab = 0;
  String category = 'Cities';
  String search = '';
  bool loaded = false;

  final categories = ['Cities', 'Hobbies', 'Books'];

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      favorites.addAll(prefs.getStringList('favorites') ?? []);
      final savedTheme = prefs.getString('theme') ?? 'system';
      themeMode = savedTheme == 'dark'
          ? ThemeMode.dark
          : savedTheme == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
      loaded = true;
    });
  }

  Future<void> toggleFavorite(String key) async {
    setState(() {
      if (!favorites.add(key)) {
        favorites.remove(key);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  Future<void> changeTheme(ThemeMode mode) async {
    setState(() => themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode.name);
  }

  Future<void> clearFavorites(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all favorites?'),
        content: const Text(
          'This will remove every saved city, hobby, and book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear Favorites'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => favorites.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', []);
  }

  List<FavoriteItem> get allItems => [
        ...sampleCities.map(
          (city) => FavoriteItem(
            keyId: 'city_${city.id}',
            title: city.cityName,
            subtitle: 'City',
            category: 'Cities',
            image: city.cityImage,
            icon: '🌍',
          ),
        ),
        ...sampleHobbies.map(
          (hobby) => FavoriteItem(
            keyId: 'hobby_${hobby.id}',
            title: hobby.hobbyName,
            subtitle: 'Hobby',
            category: 'Hobbies',
            icon: hobby.hobbyIcon,
          ),
        ),
        ...sampleBooks.map(
          (book) => FavoriteItem(
            keyId: 'book_${book.id}',
            title: book.bookTitle,
            subtitle: book.bookAuthor,
            category: 'Books',
            icon: '📚',
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Favorites',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: makeTheme(Brightness.light),
      darkTheme: makeTheme(Brightness.dark),
      home: Builder(
        builder: (context) {
          if (!loaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'My Favorites',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${favorites.length} saved',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            body: IndexedStack(
              index: selectedTab,
              children: [
                buildExplore(context),
                buildFavorites(context),
                buildSettings(context),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedTab,
              onDestinationSelected: (index) {
                setState(() => selectedTab = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Favorites',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ThemeData makeTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9B477D),
        brightness: brightness,
      ),
      scaffoldBackgroundColor:
          dark ? const Color(0xFF17131A) : const Color(0xFFFFF8FC),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget buildExplore(BuildContext context) {
    final items = allItems.where((item) {
      final matchesCategory = item.category == category;
      final query = search.toLowerCase().trim();
      final matchesSearch =
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover your favorites',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              const Text('Explore what you love and save it here.'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: categories.map((name) {
                  return ChoiceChip(
                    label: Text(name),
                    selected: category == name,
                    onSelected: (_) {
                      setState(() {
                        category = name;
                        search = '';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                key: ValueKey(category),
                onChanged: (value) => setState(() => search = value),
                decoration: InputDecoration(
                  hintText: 'Search ${category.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? emptyState(
                  Icons.search_off,
                  'Nothing found',
                  'Try a different search.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return itemCard(items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget buildFavorites(BuildContext context) {
    final saved = allItems
        .where((item) => favorites.contains(item.keyId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Your saved collection',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: saved.isEmpty
              ? emptyState(
                  Icons.favorite_border,
                  'No favorites yet',
                  'Explore categories and tap a heart to save an item.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: saved.length,
                  itemBuilder: (context, index) {
                    return itemCard(saved[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget itemCard(FavoriteItem item) {
    final isSaved = favorites.contains(item.keyId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: item.image != null
                  ? Image.asset(
                      'assets/images/${item.image}.jpeg',
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          iconBox(item.icon),
                    )
                  : iconBox(item.icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isSaved ? 'Remove favorite' : 'Add favorite',
              onPressed: () => toggleFavorite(item.keyId),
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.pinkAccent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget iconBox(String emoji) {
    return Container(
      width: 78,
      height: 78,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5DFEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 35),
      ),
    );
  }

  Widget emptyState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 65, color: Colors.pinkAccent),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget buildSettings(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Personalize your app',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const Text('Your preferences are saved automatically.'),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<ThemeMode>(
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value != null) changeTheme(value);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('System default'),
                        secondary: Icon(Icons.phone_android),
                        value: ThemeMode.system,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Light mode'),
                        secondary: Icon(Icons.light_mode_outlined),
                        value: ThemeMode.light,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Dark mode'),
                        secondary: Icon(Icons.dark_mode_outlined),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Favorites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${favorites.length} items currently saved'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: favorites.isEmpty
                        ? null
                        : () => clearFavorites(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear Favorites'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('My Favorites • Module 3')),
      ],
    );
  }
}

class FavoriteItem {
  final String keyId;
  final String title;
  final String subtitle;
  final String category;
  final String icon;
  final String? image;

  const FavoriteItem({
    required this.keyId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    this.image,
  });
}
