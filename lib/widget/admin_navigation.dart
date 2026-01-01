import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashier_app/admin/history_page.dart';
import 'package:cashier_app/admin/stock_page.dart';
import 'package:cashier_app/admin/summary_page.dart';
import 'package:cashier_app/api/auth_service.dart';
import 'package:cashier_app/login_page.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int selectedIndex = 0;
  bool _isLoggingOut = false;

  static const List<Widget> _pages = <Widget>[
    StockPage(),
    HistoryPage(),
    SummaryPage(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> onLogout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService.instance.logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no appBar here
      body: Column(
        children: [
          AdminNavBar(
            selectedIndex: selectedIndex,
            onIconTap: onItemTapped,
            onLogoutTap: onLogout,
          ),
          Expanded(child: _pages[selectedIndex]),
        ],
      ),
    );
  }
}

class AdminNavBar extends StatelessWidget {
  const AdminNavBar({
    super.key,
    required this.selectedIndex,
    required this.onIconTap,
    required this.onLogoutTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onIconTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF137048);

    return Material(
      color: bg,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // LEFT
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/Logo.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFFC107),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "ASEP'S POS",
                      style: GoogleFonts.aclonica(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // CENTER
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TopIcon(
                        iconBuilder:
                            (color) => SvgPicture.asset(
                              'assets/Stock.svg',
                              width: 30,
                              height: 30,
                              colorFilter: ColorFilter.mode(
                                color,
                                BlendMode.srcIn,
                              ),
                            ),
                        isSelected: selectedIndex == 0,
                        onTap: () => onIconTap(0),
                      ),
                      const SizedBox(width: 24),
                      _TopIcon(
                        iconBuilder:
                            (color) => Icon(
                              Icons.history,
                              color: color,
                              size: 32,
                            ),
                        isSelected: selectedIndex == 1,
                        onTap: () => onIconTap(1),
                      ),
                      const SizedBox(width: 24),
                      _TopIcon(
                        iconBuilder:
                            (color) => Icon(
                              Icons.pie_chart_outline,
                              color: color,
                              size: 32,
                            ),
                        isSelected: selectedIndex == 2,
                        onTap: () => onIconTap(2),
                      ),
                    ],
                  ),
                ),

                // RIGHT
                ElevatedButton(
                  onPressed: onLogoutTap,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFCFF5E4),
                    foregroundColor: bg,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({
    required this.iconBuilder,
    required this.isSelected,
    required this.onTap,
  });

  final Widget Function(Color color) iconBuilder;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0XFF27DD8E) : Colors.white70;

    return InkResponse(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconBuilder(color),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 3,
            width: isSelected ? 18 : 0,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0XFF27DD8E) : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
