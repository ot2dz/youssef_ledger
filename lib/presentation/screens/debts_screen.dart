import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';
import '../widgets/parties_list_view.dart';
import '../widgets/debts_stats_card.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _runDataCleanup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runDataCleanup() async {
    try {
      // Ensure SQL views exist (in case migration was missed)
      await DatabaseHelper.instance.ensureViewsExist();

      await DatabaseHelper.instance.fixPartyTypes();
      await DatabaseHelper.instance.logInvalidPartyTypes();
    } catch (e) {
      debugPrint('[DebtsScreen] Error during data cleanup: $e');
    }
  }

  /// Show dialog to add a new party based on current tab
  void _showAddPartyDialog() async {
    final currentRole = _tabController.index == 0
        ? PartyRole.person
        : PartyRole.vendor;
    final roleText = currentRole == PartyRole.person ? 'شخص' : 'مورد';

    final nameController = TextEditingController();
    final newPartyName = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                currentRole == PartyRole.person
                    ? Icons.person_add
                    : Icons.business_outlined,
                color: const Color(0xFF6366F1),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'إضافة $roleText جديد',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "اسم ال$roleText",
              prefixIcon: Icon(
                currentRole == PartyRole.person ? Icons.person : Icons.business,
                color: const Color(0xFF6366F1),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(nameController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إضافة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (newPartyName != null && newPartyName.isNotEmpty) {
      debugPrint(
        '[UI-DEBUG] Adding new party: $newPartyName, Role: $currentRole',
      );

      try {
        if (currentRole == PartyRole.vendor) {
          await DatabaseHelper.instance.createVendor(newPartyName);
        } else {
          await DatabaseHelper.instance.createPerson(newPartyName);
        }
        debugPrint(
          '[UI] Added $roleText: $newPartyName → auto-refresh via DbBus',
        );
      } catch (e) {
        debugPrint('[ERROR] Failed to add $roleText: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'الديون',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF6366F1), // Modern blue color
            foregroundColor: Colors.white,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    debugPrint(
                      '[UI] Opened tab: ${index == 0 ? 'persons' : 'vendors'}',
                    );
                  },
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  labelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: _tabController.index == 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              const Text('أشخاص'),
                            ],
                          );
                        },
                      ),
                    ),
                    Tab(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                size: 20,
                                color: _tabController.index == 1
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              const Text('موردون'),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Stats card
              const Padding(
                padding: EdgeInsets.all(16),
                child: DebtsStatsCard(),
              ),
              // Tabs content
              Expanded(
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    return IndexedStack(
                      index: _tabController.index,
                      children: [
                        // Persons tab
                        PartiesList(role: PartyRole.person),
                        // Vendors tab
                        PartiesList(role: PartyRole.vendor),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final isPersonsTab = _tabController.index == 0;
              return FloatingActionButton.extended(
                onPressed: _showAddPartyDialog,
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                label: Text(
                  isPersonsTab ? 'إضافة شخص' : 'إضافة مورد',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                icon: Icon(
                  isPersonsTab ? Icons.person_add : Icons.business_outlined,
                  size: 22,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
