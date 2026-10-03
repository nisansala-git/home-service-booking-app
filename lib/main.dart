import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'services/app_state_service.dart';
import 'features/member1_discovery_auth/home_discovery_screen.dart';
import 'features/member1_discovery_auth/search_results_screen.dart';
import 'features/member3_payment_reviews/provider_dashboard_screen.dart';
import 'features/member4_notifications_history/my_bookings_screen.dart';
import 'features/member4_notifications_history/provider_notifications_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FixItHomeApp());
}

class FixItHomeApp extends StatelessWidget {
  const FixItHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final AppStateService _appState = AppStateService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final isProvider = _appState.activeRole == 'provider';

        final List<Widget> screens = isProvider
            ? [
                const ProviderDashboardScreen(),
                const ProviderNotificationsScreen(),
                const MyBookingsScreen(),
              ]
            : [
                const HomeDiscoveryScreen(),
                const SearchResultsScreen(),
                const MyBookingsScreen(),
              ];

        return Scaffold(
          body: Column(
            children: [
              // Top Viva Role Switcher Bar (Quickly switch between Homeowner & Provider views)
              Container(
                color: AppColors.primaryDark,
                padding: const EdgeInsets.only(top: 36, bottom: 8, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group_work, color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'KND_HCI_G05 | Role: ${isProvider ? "Provider View" : "Homeowner View"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        final newRole = isProvider ? 'homeowner' : 'provider';
                        _appState.setRole(newRole);
                        setState(() => _currentIndex = 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 1),
                            content: Text('Switched to ${newRole.toUpperCase()} mode'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isProvider ? Icons.swap_horiz : Icons.storefront,
                              size: 14,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isProvider ? 'Switch to Homeowner' : 'Switch to Provider',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Active Screen Body
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),

          // Bottom Navigation Bar
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            elevation: 8,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: isProvider
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      activeIcon: Icon(Icons.dashboard),
                      label: 'Requests',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.notifications_outlined),
                      activeIcon: Icon(Icons.notifications),
                      label: 'Alerts',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history_outlined),
                      activeIcon: Icon(Icons.history),
                      label: 'Job History',
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search_outlined),
                      activeIcon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today_outlined),
                      activeIcon: Icon(Icons.calendar_today),
                      label: 'Bookings',
                    ),
                  ],
          ),
        );
      },
    );
  }
}
