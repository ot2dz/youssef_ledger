// lib/presentation/widgets/parties_list_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/local/db_bus.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';
import 'package:youssef_fabric_ledger/presentation/screens/party_details_screen.dart';
import '../theme/action_button_styles.dart';
import '../widgets/debt_transaction_modal.dart';

// Filter options for parties
enum PartyFilterType { all, withBalance, withoutBalance, recentActivity }

// Enhanced party data structure to include statistics
class PartyWithStats {
  final Party party;
  final double balance;
  final int transactionCount;
  final DateTime? lastTransactionDate;

  PartyWithStats({
    required this.party,
    required this.balance,
    required this.transactionCount,
    this.lastTransactionDate,
  });
}

/// Role-isolated parties list widget with keep-alive and auto-refresh
class PartiesList extends StatefulWidget {
  final PartyRole role;

  const PartiesList({required this.role, super.key});

  @override
  State<PartiesList> createState() => _PartiesListState();
}

class _PartiesListState extends State<PartiesList>
    with AutomaticKeepAliveClientMixin {
  List<PartyWithStats> partiesWithStats = [];
  List<PartyWithStats> filteredParties = [];
  bool isLoading = true;
  late StreamSubscription<void> _dbSubscription;

  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PartyFilterType _filterType = PartyFilterType.all;

  @override
  bool get wantKeepAlive => true; // Keep this tab alive across navigation

  @override
  void initState() {
    super.initState();
    debugPrint('[REPO] PartiesList(${widget.role.name}) initializing');

    // Subscribe to database changes for auto-refresh
    _dbSubscription = DbBus.instance.stream.listen((_) {
      debugPrint('[UI] DbBus event → PartiesList(${widget.role.name}) refresh');
      _loadPartiesAndBalances();
    });

    _loadPartiesAndBalances();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dbSubscription.cancel();
    super.dispose();
  }

  /// Load parties with enhanced statistics (optimized version)
  Future<void> _loadPartiesAndBalances() async {
    try {
      debugPrint('[PARTIES] Loading parties for role: ${widget.role.name}');

      final List<Party> loadedParties;
      if (widget.role == PartyRole.person) {
        loadedParties = await DatabaseHelper.instance.getPersons();
      } else {
        loadedParties = await DatabaseHelper.instance.getVendors();
      }

      debugPrint('[PARTIES] Loaded ${loadedParties.length} parties');

      // Get all stats in a single query for better performance
      final allStats = await DatabaseHelper.instance.getAllPartiesStats(
        widget.role,
      );

      final List<PartyWithStats> loadedPartiesWithStats = [];
      for (Party party in loadedParties) {
        if (party.id != null) {
          final stats =
              allStats[party.id!] ??
              {
                'balance': 0.0,
                'transactionCount': 0,
                'lastTransactionDate': null,
              };

          loadedPartiesWithStats.add(
            PartyWithStats(
              party: party,
              balance: stats['balance'] as double,
              transactionCount: stats['transactionCount'] as int,
              lastTransactionDate: stats['lastTransactionDate'] as DateTime?,
            ),
          );
        }
      }

      debugPrint(
        '[PARTIES] Final parties with stats: ${loadedPartiesWithStats.length}',
      );

      if (mounted) {
        setState(() {
          partiesWithStats = loadedPartiesWithStats;
          _filterAndSearchParties();
          isLoading = false;
        });
        debugPrint('[PARTIES] State updated, isLoading: false');
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to load ${widget.role.name} parties: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Filter and search parties based on current criteria
  void _filterAndSearchParties() {
    List<PartyWithStats> filtered = partiesWithStats;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((partyStats) {
        return partyStats.party.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (partyStats.party.phone != null &&
                partyStats.party.phone!.contains(_searchQuery));
      }).toList();
    }

    // Apply type filter
    switch (_filterType) {
      case PartyFilterType.withBalance:
        filtered = filtered.where((p) => p.balance != 0.0).toList();
        break;
      case PartyFilterType.withoutBalance:
        filtered = filtered.where((p) => p.balance == 0.0).toList();
        break;
      case PartyFilterType.recentActivity:
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        filtered = filtered.where((p) {
          return p.lastTransactionDate != null &&
              p.lastTransactionDate!.isAfter(oneWeekAgo);
        }).toList();
        break;
      case PartyFilterType.all:
        // No additional filtering
        break;
    }

    filteredParties = filtered;
  }

  /// Handle search query changes
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterAndSearchParties();
    });
  }

  /// Handle filter type changes
  void _onFilterChanged(PartyFilterType filterType) {
    setState(() {
      _filterType = filterType;
      _filterAndSearchParties();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return PageStorage(
      bucket: PageStorageBucket(),
      child: Builder(
        key: PageStorageKey('parties_${widget.role.name}'),
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search and Filter Bar - Using Flexible to allow shrinking
              Flexible(flex: 0, child: _buildSearchAndFilterBar()),

              // Results Count Bar - Using Flexible to allow shrinking
              if (partiesWithStats.isNotEmpty)
                Flexible(flex: 0, child: _buildResultsCountBar()),

              // Parties List - Takes remaining space
              Expanded(child: _buildPartiesList()),
            ],
          );
        },
      ),
    );
  }

  /// Build search and filter bar
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText:
                  'البحث عن ${widget.role == PartyRole.vendor ? 'مورد' : 'شخص'}...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            textDirection: TextDirection.rtl,
          ),

          const SizedBox(height: 6),

          // Filter Chips
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', PartyFilterType.all),
                  const SizedBox(width: 8),
                  _buildFilterChip('لديهم رصيد', PartyFilterType.withBalance),
                  const SizedBox(width: 8),
                  _buildFilterChip('بدون رصيد', PartyFilterType.withoutBalance),
                  const SizedBox(width: 8),
                  _buildFilterChip('نشاط حديث', PartyFilterType.recentActivity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build results count bar
  Widget _buildResultsCountBar() {
    final totalCount = partiesWithStats.length;
    final filteredCount = filteredParties.length;

    if (totalCount == filteredCount &&
        _searchQuery.isEmpty &&
        _filterType == PartyFilterType.all) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            'عرض $filteredCount من أصل $totalCount',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const Spacer(),
          if (_searchQuery.isNotEmpty || _filterType != PartyFilterType.all)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterType = PartyFilterType.all;
                  _filterAndSearchParties();
                });
              },
              icon: const Icon(Icons.clear_all, size: 14),
              label: const Text('مسح'),
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 11),
                minimumSize: const Size(0, 24),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String label, PartyFilterType filterType) {
    final isSelected = _filterType == filterType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(filterType),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  /// Build the main parties list
  Widget _buildPartiesList() {
    if (partiesWithStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.role == PartyRole.vendor ? Icons.store : Icons.person,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد ${widget.role == PartyRole.vendor ? 'موردين' : 'أشخاص'} حالياً',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (filteredParties.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج للبحث عن "$_searchQuery"',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('list_${widget.role.name}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredParties.length,
      itemBuilder: (context, index) => _buildPartyCard(filteredParties[index]),
    );
  }

  Widget _buildPartyCard(PartyWithStats partyWithStats) {
    final party = partyWithStats.party;
    final balance = partyWithStats.balance;
    final transactionCount = partyWithStats.transactionCount;
    final lastTransactionDate = partyWithStats.lastTransactionDate;

    final isPositive = balance > 0;
    final isZero = balance == 0;

    // Assert role consistency in debug mode
    assert(
      party.role == widget.role,
      'Expected ${widget.role} but got ${party.role} for party ${party.name}',
    );

    // Format last transaction date
    String? lastTransactionText;
    if (lastTransactionDate != null) {
      final now = DateTime.now();
      final difference = now.difference(lastTransactionDate);

      if (difference.inDays == 0) {
        lastTransactionText = 'اليوم';
      } else if (difference.inDays == 1) {
        lastTransactionText = 'أمس';
      } else if (difference.inDays < 7) {
        lastTransactionText = 'منذ ${difference.inDays} أيام';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        lastTransactionText = weeks == 1 ? 'منذ أسبوع' : 'منذ $weeks أسابيع';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        lastTransactionText = months == 1 ? 'منذ شهر' : 'منذ $months أشهر';
      } else {
        final years = (difference.inDays / 365).floor();
        lastTransactionText = years == 1 ? 'منذ سنة' : 'منذ $years سنوات';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isZero
                  ? Colors.grey
                  : isPositive
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Icon(
                widget.role == PartyRole.vendor ? Icons.store : Icons.person,
                color: isZero
                    ? Colors.grey.shade600
                    : isPositive
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
            ),
            title: Text(
              party.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (party.phone != null && party.phone!.isNotEmpty)
                  Text(party.phone!),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      transactionCount == 0
                          ? 'لا توجد معاملات'
                          : '$transactionCount معاملة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (transactionCount > 0) ...[
                      if (lastTransactionText != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lastTransactionText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${balance.abs().toStringAsFixed(2)} د.ج',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isZero
                        ? Colors.grey
                        : isPositive
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                Text(
                  isZero
                      ? 'متوازن'
                      : isPositive
                      ? (widget.role == PartyRole.vendor
                            ? 'مستحق له'
                            : 'مستحق منه')
                      : (widget.role == PartyRole.vendor
                            ? 'مستحق منه'
                            : 'مستحق له'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      PartyDetailsScreen(party: party, initialBalance: balance),
                ),
              );
            },
          ),
          // Action buttons based on role
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: _getButtonsForParty(party)),
          ),
        ],
      ),
    );
  }

  /// Get action buttons based on party role
  List<Widget> _getButtonsForParty(Party party) {
    if (widget.role == PartyRole.vendor) {
      return [
        // Vendor buttons: Purchase and Payment
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handlePurchaseAction(context, party),
            icon: const Icon(Icons.shopping_cart, size: 20),
            label: const Text('شراء'),
            style: ActionButtonStyles.redActionStyle.copyWith(
              minimumSize: WidgetStateProperty.all(const Size(0, 52)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handlePaymentAction(context, party),
            icon: const Icon(Icons.payment, size: 20),
            label: const Text('تسديد'),
            style: ActionButtonStyles.greenActionStyle.copyWith(
              minimumSize: WidgetStateProperty.all(const Size(0, 52)),
            ),
          ),
        ),
      ];
    } else {
      return [
        // Person buttons: Loan and Receive
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handleLoanAction(context, party),
            icon: const Icon(Icons.arrow_upward, size: 20),
            label: const Text('إقراض'),
            style: ActionButtonStyles.redActionStyle.copyWith(
              minimumSize: WidgetStateProperty.all(const Size(0, 52)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handleReceiveAction(context, party),
            icon: const Icon(Icons.arrow_downward, size: 20),
            label: const Text('استلام'),
            style: ActionButtonStyles.greenActionStyle.copyWith(
              minimumSize: WidgetStateProperty.all(const Size(0, 52)),
            ),
          ),
        ),
      ];
    }
  }

  /// Handle purchase action (vendors)
  void _handlePurchaseAction(BuildContext context, Party party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DebtTransactionModal(
        party: party,
        transactionKind: 'purchase_credit',
        onTransactionSaved: _loadPartiesAndBalances,
      ),
    );
  }

  /// Handle payment action (vendors)
  void _handlePaymentAction(BuildContext context, Party party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DebtTransactionModal(
        party: party,
        transactionKind: 'payment',
        onTransactionSaved: _loadPartiesAndBalances,
      ),
    );
  }

  /// Handle loan action (persons)
  void _handleLoanAction(BuildContext context, Party party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DebtTransactionModal(
        party: party,
        transactionKind: 'loan_out',
        onTransactionSaved: _loadPartiesAndBalances,
      ),
    );
  }

  /// Handle receive action (persons)
  void _handleReceiveAction(BuildContext context, Party party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DebtTransactionModal(
        party: party,
        transactionKind: 'settlement',
        onTransactionSaved: _loadPartiesAndBalances,
      ),
    );
  }
}

/// ويدجت لعرض بطاقة الطرف مع رصيده
class PartyBalanceCard extends StatefulWidget {
  final Party party;

  const PartyBalanceCard({super.key, required this.party});

  @override
  State<PartyBalanceCard> createState() => _PartyBalanceCardState();
}

class _PartyBalanceCardState extends State<PartyBalanceCard> {
  double balance = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  /// تحميل رصيد الطرف
  Future<void> _loadBalance() async {
    try {
      final partyBalance = await DatabaseHelper.instance.getPartyBalance(
        widget.party.id!,
      );
      setState(() {
        balance = partyBalance;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = balance > 0;
    final isZero = balance == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isZero
              ? Colors.grey
              : isPositive
              ? Colors.red.shade100
              : Colors.green.shade100,
          child: Icon(
            widget.party.type == 'vendor' ? Icons.store : Icons.person,
            color: isZero
                ? Colors.grey.shade600
                : isPositive
                ? Colors.red.shade700
                : Colors.green.shade700,
          ),
        ),
        title: Text(
          widget.party.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: widget.party.phone != null && widget.party.phone!.isNotEmpty
            ? Text(widget.party.phone!)
            : null,
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${balance.abs().toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isZero
                          ? Colors.grey
                          : isPositive
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  Text(
                    isZero
                        ? 'متوازن'
                        : isPositive
                        ? (widget.party.type == 'vendor'
                              ? 'مستحق له'
                              : 'مستحق منه')
                        : (widget.party.type == 'vendor'
                              ? 'مستحق منه'
                              : 'مستحق له'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
        onTap: () {
          debugPrint(
            '[onTap] Party tapped: id=${widget.party.id}, name=${widget.party.name}, type=${widget.party.type}',
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PartyDetailsScreen(
                party: widget.party,
                initialBalance: balance,
              ),
            ),
          );
        },
      ),
    );
  }
}
