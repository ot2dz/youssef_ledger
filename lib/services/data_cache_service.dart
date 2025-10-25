// lib/services/data_cache_service.dart
import 'dart:async';
import 'package:youssef_fabric_ledger/data/models/category.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/local/db_bus.dart';

/// In-memory cache service to reduce database queries
///
/// This service caches frequently accessed data like categories and party balances
/// to dramatically improve scroll performance and UI responsiveness.
///
/// The cache is automatically invalidated when database changes occur (via DbBus).
class DataCacheService {
  static final DataCacheService instance = DataCacheService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  late StreamSubscription<void> _dbSubscription;

  // Category cache
  Map<int, Category>? _categoryCache;
  DateTime? _categoryCacheTime;
  static const Duration _categoryTTL = Duration(minutes: 30);

  // Party balance cache
  final Map<int, double> _partyBalanceCache = {};
  final Map<int, DateTime> _partyBalanceCacheTime = {};
  static const Duration _partyBalanceTTL = Duration(minutes: 5);

  DataCacheService._() {
    // Listen to database changes and invalidate cache
    _dbSubscription = DbBus.instance.stream.listen((_) {
      invalidateAll();
    });
  }

  /// Get category by ID (with caching)
  Future<Category?> getCategoryById(int categoryId) async {
    // Load all categories into cache if not cached or expired
    if (_categoryCache == null || _isCategoryExpired()) {
      await _loadCategoriesCache();
    }

    return _categoryCache![categoryId];
  }

  /// Get all categories (with caching)
  Future<List<Category>> getAllCategories() async {
    if (_categoryCache == null || _isCategoryExpired()) {
      await _loadCategoriesCache();
    }

    return _categoryCache!.values.toList();
  }

  /// Get party balance by ID (with caching)
  Future<double> getPartyBalance(int partyId) async {
    // Check if cached and not expired
    if (_partyBalanceCache.containsKey(partyId) &&
        !_isPartyBalanceExpired(partyId)) {
      return _partyBalanceCache[partyId]!;
    }

    // Fetch from database and cache
    final balance = await _db.getPartyBalance(partyId);
    _partyBalanceCache[partyId] = balance;
    _partyBalanceCacheTime[partyId] = DateTime.now();

    return balance;
  }

  /// Preload party balances for multiple parties (batch optimization)
  Future<void> preloadPartyBalances(List<int> partyIds) async {
    final toLoad = partyIds
        .where(
          (id) =>
              !_partyBalanceCache.containsKey(id) || _isPartyBalanceExpired(id),
        )
        .toList();

    if (toLoad.isEmpty) return;

    // Load in parallel
    await Future.wait(toLoad.map((id) => getPartyBalance(id)));
  }

  // Private helper methods
  Future<void> _loadCategoriesCache() async {
    final categories = await _db.getCategories('expense');
    final incomeCategories = await _db.getCategories('income');

    _categoryCache = {};
    for (var cat in [...categories, ...incomeCategories]) {
      if (cat.id != null) {
        _categoryCache![cat.id!] = cat;
      }
    }
    _categoryCacheTime = DateTime.now();
  }

  bool _isCategoryExpired() {
    if (_categoryCacheTime == null) return true;
    return DateTime.now().difference(_categoryCacheTime!) > _categoryTTL;
  }

  bool _isPartyBalanceExpired(int partyId) {
    final cacheTime = _partyBalanceCacheTime[partyId];
    if (cacheTime == null) return true;
    return DateTime.now().difference(cacheTime) > _partyBalanceTTL;
  }

  /// Invalidate specific party balance
  void invalidatePartyBalance(int partyId) {
    _partyBalanceCache.remove(partyId);
    _partyBalanceCacheTime.remove(partyId);
  }

  /// Invalidate all party balances
  void invalidateAllPartyBalances() {
    _partyBalanceCache.clear();
    _partyBalanceCacheTime.clear();
  }

  /// Invalidate categories cache
  void invalidateCategories() {
    _categoryCache = null;
    _categoryCacheTime = null;
  }

  /// Invalidate all caches (called on database changes)
  void invalidateAll() {
    invalidateCategories();
    invalidateAllPartyBalances();
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getStats() {
    return {
      'categoriesCached': _categoryCache?.length ?? 0,
      'categoryExpired': _isCategoryExpired(),
      'partyBalancesCached': _partyBalanceCache.length,
      'categoryCacheAge': _categoryCacheTime != null
          ? DateTime.now().difference(_categoryCacheTime!).inSeconds
          : null,
    };
  }

  /// Cleanup resources
  void dispose() {
    _dbSubscription.cancel();
    invalidateAll();
  }
}
