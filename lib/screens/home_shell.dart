import 'package:flutter/material.dart';

import '../core/session_controller.dart';
import 'access_screen.dart';
import 'dashboard_screen.dart';
import 'money_screen.dart';
import 'operations_screens.dart';
import 'report_design_screen.dart';
import 'resource_modules.dart';
import 'trade_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});
  final SessionController session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int selected = 0;

  List<_Destination> get destinations {
    final api = widget.session.api;
    final all = [
      _Destination(
        'Dashboard',
        Icons.dashboard_outlined,
        'dashboard',
        () => DashboardScreen(api: api),
      ),
      _Destination(
        'Reports',
        Icons.analytics_outlined,
        'reports',
        () => ProfessionalReportsScreen(api: api),
      ),
      _Destination(
        'Farms',
        Icons.home_work_outlined,
        'farms',
        () => farmsModule(api),
      ),
      _Destination(
        'Livestock',
        Icons.pets_outlined,
        'livestock',
        () => animalsModule(api),
      ),
      _Destination(
        'Livestock batches',
        Icons.groups_2_outlined,
        'livestock',
        () => BatchesScreen(api: api),
      ),
      _Destination(
        'Health',
        Icons.medical_services_outlined,
        'health',
        () => HealthScreen(api: api),
      ),
      _Destination(
        'Inventory',
        Icons.inventory_2_outlined,
        'inventory',
        () => inventoryModule(api),
      ),
      _Destination(
        'Production',
        Icons.egg_alt_outlined,
        'production',
        () => productionModule(api),
      ),
      _Destination(
        'Sales POS',
        Icons.point_of_sale_outlined,
        'sales',
        () => TradesScreen(api: api, isSale: true),
      ),
      _Destination(
        'Purchase POS',
        Icons.shopping_cart_outlined,
        'purchases',
        () => TradesScreen(api: api, isSale: false),
      ),
      _Destination(
        'Parties',
        Icons.people_alt_outlined,
        'contacts',
        () => contactsModule(api),
      ),
      _Destination(
        'Party ledgers',
        Icons.menu_book_outlined,
        'contacts',
        () => PartyLedgersScreen(api: api),
      ),
      _Destination(
        'Cash & bank setup',
        Icons.account_balance_wallet_outlined,
        'accounts',
        () => accountsModule(api),
      ),
      _Destination(
        'Statements & transfer',
        Icons.swap_horiz,
        'accounts',
        () => MoneyScreen(api: api),
      ),
      _Destination(
        'Investors & shares',
        Icons.pie_chart_outline,
        'investors',
        () => investorsModule(api),
      ),
      _Destination(
        'Quick operations',
        Icons.bolt_outlined,
        null,
        () => QuickOperationsScreen(api: api),
        anyOf: const ['contacts', 'inventory'],
      ),
      _Destination(
        'Accounting',
        Icons.receipt_long_outlined,
        'accounting',
        () => accountingModule(api),
      ),
      _Destination(
        'Categories',
        Icons.category_outlined,
        'accounting',
        () => categoriesModule(api),
      ),
      _Destination(
        'Users & roles',
        Icons.manage_accounts_outlined,
        'users',
        () => AccessScreen(api: api),
      ),
      _Destination(
        'Settings',
        Icons.settings_outlined,
        null,
        () => SettingsScreen(session: widget.session),
      ),
    ];
    return all.where((item) {
      if (item.permission != null) return widget.session.can(item.permission!);
      if (item.anyOf.isNotEmpty) return item.anyOf.any(widget.session.can);
      return true;
    }).toList();
  }

  void select(int index) {
    setState(() => selected = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  int _indexOf(List<_Destination> items, String title) =>
      items.indexWhere((item) => item.title == title);

  Future<void> _openModuleHub(List<_Destination> items) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF4F8FB),
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm management',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    const Text('Choose a module to continue'),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 118,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final palette = _modulePalette(index);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(context, index),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 21,
                                backgroundColor: palette.$1,
                                child: Icon(item.icon, color: palette.$2),
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _moduleSubtitle(item.title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF718078),
                                  fontSize: 11,
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
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) select(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final items = destinations;
    if (selected >= items.length) selected = 0;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final content = KeyedSubtree(
      key: ValueKey('${items[selected].title}-$selected'),
      child: items[selected].builder(),
    );
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: wide ? 18 : 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/livestockos-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.tenantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF173B2A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF18A957),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          items[selected].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718078),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!wide)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF5E7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  widget.session.userName.isEmpty
                      ? 'U'
                      : widget.session.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF07883F),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: _navigation(items))),
      bottomNavigationBar: wide ? null : _bottomNavigation(items),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 270,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: SafeArea(top: false, child: _navigation(items)),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _navigation(List<_Destination> items) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                widget.session.userName.isEmpty
                    ? 'U'
                    : widget.session.userName[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.userName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.session.tenantName,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const Divider(),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: items.length,
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: ListTile(
              selected: selected == index,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(items[index].icon),
              title: Text(
                items[index].title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => select(index),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.session.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ),
      ),
    ],
  );

  Widget _bottomNavigation(List<_Destination> items) {
    final activeTitle = items[selected].title;
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: 72,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Row(
        children: [
          _bottomItem(
            items,
            'Dashboard',
            'Home',
            Icons.home_outlined,
            activeTitle,
          ),
          _bottomItem(
            items,
            'Livestock',
            'Animals',
            Icons.pets_outlined,
            activeTitle,
          ),
          Expanded(
            child: Center(
              child: Semantics(
                button: true,
                label: 'Open all modules',
                child: InkWell(
                  onTap: () => _openModuleHub(items),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF07883F),
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33007838),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ),
          _bottomItem(
            items,
            'Production',
            'Farming',
            Icons.spa_outlined,
            activeTitle,
          ),
          _bottomItem(
            items,
            'Reports',
            'Reports',
            Icons.analytics_outlined,
            activeTitle,
          ),
        ],
      ),
    );
  }

  Widget _bottomItem(
    List<_Destination> items,
    String destination,
    String label,
    IconData icon,
    String activeTitle,
  ) {
    final index = _indexOf(items, destination);
    final active = activeTitle == destination;
    return Expanded(
      child: InkWell(
        onTap: index < 0 ? () => _openModuleHub(items) : () => select(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? _selectedIcon(icon) : icon,
              size: 22,
              color: active ? const Color(0xFF07883F) : const Color(0xFF718078),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF07883F)
                    : const Color(0xFF718078),
                fontSize: 10,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _selectedIcon(IconData icon) {
    if (icon == Icons.home_outlined) return Icons.home;
    if (icon == Icons.pets_outlined) return Icons.pets;
    if (icon == Icons.spa_outlined) return Icons.spa;
    if (icon == Icons.analytics_outlined) return Icons.analytics;
    return icon;
  }

  (Color, Color) _modulePalette(int index) {
    const palettes = [
      (Color(0xFFDFF5E7), Color(0xFF07883F)),
      (Color(0xFFE6F1FF), Color(0xFF2775D8)),
      (Color(0xFFFFE7E5), Color(0xFFE3493F)),
      (Color(0xFFFFF0D7), Color(0xFFE99218)),
      (Color(0xFFF0E5FF), Color(0xFF8946D8)),
    ];
    return palettes[index % palettes.length];
  }

  String _moduleSubtitle(String title) => switch (title) {
    'Dashboard' => 'Farm overview',
    'Reports' => 'Analytics & insights',
    'Livestock' => 'Animals & records',
    'Livestock batches' => 'Flocks & groups',
    'Health' => 'Treatment & vaccines',
    'Inventory' => 'Feed, medicine & stock',
    'Production' => 'Milk, egg & birth',
    'Sales POS' => 'Sales & collection',
    'Purchase POS' => 'Purchase & payment',
    'Investors & shares' => 'Capital & ownership',
    'Accounting' => 'Income & expense',
    'Cash & bank setup' => 'Accounts & balances',
    _ => 'Manage records',
  };
}

class _Destination {
  const _Destination(
    this.title,
    this.icon,
    this.permission,
    this.builder, {
    this.anyOf = const [],
  });
  final String title;
  final IconData icon;
  final String? permission;
  final Widget Function() builder;
  final List<String> anyOf;
}
