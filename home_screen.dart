import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'medicines_screen.dart';
import 'reminders_screen.dart';
import 'logs_screen.dart';
import 'prescription_screen.dart';
import 'monitoring_screen.dart';
import 'diet_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'pharmacy_screen.dart';
import '../services/notification_service.dart';
import '../models/medicine.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<MedicinesScreenState> _medicinesKey = GlobalKey<MedicinesScreenState>();
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();

  Timer? _notificationTimer;
  final List<_NotifItem> _notifications = [];

  bool _alreadyScheduled = false;


Future<void> _refreshMedicineNotifications() async {
  try {
    final medsData = await ApiService.getMedicines();

    final meds = medsData
        .map((m) => Medicine.fromJson(m as Map<String, dynamic>))
        .toList();

    final now = DateTime.now();

    for (var med in meds) {
      final parts = med.time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

    
        if (now.hour == hour && now.minute == minute) {

          await NotificationService.showInstantNotification(
            title: "💊 Medicine Reminder",
            body: "Time to take ${med.name}",
          );

          
          await ApiService.saveNotification(
            title: "Medicine Reminder",
            message: "Time to take ${med.name}",
            type: "medicine",
          );
        }
      }
    }

  } catch (e) {
    print("Error: $e");
  }
}



@override
void initState() {
  super.initState();

  NotificationService.requestAlarmPermissionManually();

  //  RUN ONCE
  _refreshMedicineNotifications();

  //  RUN EVERY 15 SECONDS 
  _notificationTimer = Timer.periodic(
    const Duration(seconds: 15),
    (_) => _refreshMedicineNotifications(),
  );
}


  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }


    bool _isDueNow(String rawTime) {
      final scheduled = _parseMedicineTime(rawTime);
      if (scheduled == null) return false;

      final now = DateTime.now();
      final difference = now.difference(scheduled).inMinutes;

      return difference >= 0 && difference <= 5;
    }



    

  DateTime? _parseMedicineTime(String rawTime) {
    final text = rawTime.trim();
    if (text.isEmpty) return null;

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(text);

    if (match == null) return null;

    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3)?.toUpperCase();

    if (hour == null || minute == null) return null;

    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatMedicineTime(String rawTime) {
    final scheduled = _parseMedicineTime(rawTime);
    if (scheduled == null) return rawTime;

    final hour12 = scheduled.hour == 0
        ? 12
        : scheduled.hour > 12
            ? scheduled.hour - 12
            : scheduled.hour;

    final minute = scheduled.minute.toString().padLeft(2, '0');
    final period = scheduled.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dashboardKey.currentState?.refresh();
      });
    }

    _refreshMedicineNotifications();
  }

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.medication_outlined, activeIcon: Icons.medication, label: 'Medicines'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Reminders'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Health Logs'),
    _NavItem(icon: Icons.document_scanner_outlined, activeIcon: Icons.document_scanner, label: 'Prescriptions'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Monitoring'),
    _NavItem(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, label: 'Diet Plans'),
    _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'AI Assistant'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    _NavItem(icon: Icons.local_pharmacy_outlined, activeIcon: Icons.local_pharmacy, label: 'Pharmacies'),
  ];

  late final List<Widget> _screens = [
    DashboardScreen(key: _dashboardKey, onViewAllMedicines: () => _switchTab(1)),
    MedicinesScreen(key: _medicinesKey),
    const RemindersScreen(),
    const LogsScreen(),
    const PrescriptionScreen(),
    const MonitoringScreen(),
    const DietScreen(),
    const ChatScreen(),
    ProfileScreen(onNavigateToTab: _switchTab),
    const PharmacyScreen(),
  ];

  static const List<int> _bottomNavIndices = [0, 1, 7, 8];

  void _handleFabPress() {
    if (_selectedIndex == 1) {
      _medicinesKey.currentState?.showAddDialog();
    } else {
      _switchTab(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _medicinesKey.currentState?.showAddDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWide) _buildSideNav(user),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(user, isWide),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide ? null : _buildDrawer(user),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton(
              onPressed: _handleFabPress,
              backgroundColor: const Color(0xFF3BBFB2),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 30),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildSideNav(dynamic user) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(gradient: AppColors.navyGradient),
      child: Column(
        children: [
          _buildSideHeader(user),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (ctx, i) => _buildSideItem(i),
            ),
          ),
          _buildSideLogout(),
        ],
      ),
    );
  }

  Widget _buildSideHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.15))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'CareSync',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user?.initials ?? 'U',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.displayRole ?? '',
                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
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

  Widget _buildSideItem(int index) {
    final item = _navItems[index];
    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _switchTab(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  color: selected ? Colors.white : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 11),
                Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.white60,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideLogout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _logout,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
                const SizedBox(width: 11),
                Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(dynamic user) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3BBFB2), Color(0xFF1A6E6A)],
          ),
        ),
        child: Column(
          children: [
            _buildSideHeader(user),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _navItems.length,
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _switchTab(i);
                  },
                  child: _buildSideItem(i),
                ),
              ),
            ),
            _buildSideLogout(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            ..._bottomNavIndices.take(2).map((navIdx) => _buildBottomNavItem(navIdx)),
            const Expanded(child: SizedBox()),
            ..._bottomNavIndices.skip(2).map((navIdx) => _buildBottomNavItem(navIdx)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int navIdx) {
    final item = _navItems[navIdx];
    final selected = _selectedIndex == navIdx;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _switchTab(navIdx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: selected ? AppColors.navy : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: selected ? AppColors.navy : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic user, bool isWide) {
    final topPadding = MediaQuery.of(context).padding.top;
    final avatarDataUrl = context.watch<AuthProvider>().avatarDataUrl;

    return Container(
      height: 60 + topPadding,
      padding: EdgeInsets.only(left: 8, right: 8, top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 24),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _navItems[_selectedIndex].label,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
                onPressed: _showNotificationsPanel,
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF39C12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_notifications.length}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _switchTab(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: avatarDataUrl == null
                    ? const LinearGradient(
                        colors: [Color(0xFF3BBFB2), Color(0xFF2DB9B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: Border.all(color: const Color(0xFFE0F5F3), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarDataUrl != null
                  ? Image.memory(
                      base64Decode(avatarDataUrl.split(',').last),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _topBarInitials(user?.initials ?? 'U'),
                    )
                  : _topBarInitials(user?.initials ?? 'U'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _topBarInitials(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _logout() {
    if (!mounted) return;
    Provider.of<AuthProvider>(context, listen: false).logout();
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NotificationsPanel(
        notifications: _notifications,
        onClearAll: () {
          Navigator.pop(ctx);
          setState(() => _notifications.clear());
        },
      ),
    );
  }
}

class _NotificationsPanel extends StatefulWidget {
  final List<_NotifItem> notifications;
  final VoidCallback onClearAll;

  const _NotificationsPanel({
    required this.notifications,
    required this.onClearAll,
  });

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E6F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
              ElevatedButton.icon(
                icon: const Icon(Icons.local_pharmacy),
                label: const Text('Find Pharmacies'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PharmacyScreen()),
                  );
                },
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Medicine Notifications',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onClearAll,
                  child: Text(
                    'Clear all',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF3BBFB2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No medicine reminders right now',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF9DB2C8),
                    ),
                  ),
                ),
              )
            else
              ...widget.notifications.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: n.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(n.icon, color: n.iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A2D3E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.body,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF7A8FA6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeAgo(n.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF9DB2C8),
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
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    final d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }
}

class _NotifItem {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String body;
  final DateTime timestamp;

  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}