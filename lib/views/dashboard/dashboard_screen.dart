import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm_project/viewmodels/auth_viewmodel.dart';
import 'package:prm_project/viewmodels/notification_viewmodel.dart';
import 'package:prm_project/views/products/product_list_screen.dart';
import 'package:prm_project/views/map/map_screen.dart';
import 'package:prm_project/views/chat/chat_screen.dart';
import 'package:prm_project/views/notifications/notifications_screen.dart';
import 'package:prm_project/views/theme/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProductListScreen(),
    const MapScreen(),
    const ChatScreen(),
    const NotificationsScreen(),
    const ProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final notifVm = Provider.of<NotificationViewModel>(context);
    final unreadCount = notifVm.unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white10, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.darkBg,
          selectedItemColor: AppTheme.primaryNeon,
          unselectedItemColor: AppTheme.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag, color: AppTheme.primaryNeon),
              label: 'Shop',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map, color: AppTheme.primaryNeon),
              label: 'Stores',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble, color: AppTheme.primaryNeon),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('$unreadCount'),
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: Badge(
                label: Text('$unreadCount'),
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications, color: AppTheme.primaryNeon),
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings, color: AppTheme.primaryNeon),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// Simple profile & settings page within dashboard
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);
    final user = authVm.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('S E T T I N G S'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Profile section card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryNeon,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Guest User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'guest@luxurastore.com',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Account Management',
            style: TextStyle(color: AppTheme.secondaryTeal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.textMain),
            title: const Text('Edit Profile'),
            subtitle: const Text('Update names, emails, and photos'),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined, color: AppTheme.textMain),
            title: const Text('Security'),
            subtitle: const Text('Passwords, recovery, and biometrics'),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
            onTap: () {},
          ),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          const Text(
            'Preferences',
            style: TextStyle(color: AppTheme.secondaryTeal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined, color: AppTheme.textMain),
            title: const Text('Dark Theme'),
            trailing: Switch(
              value: true,
              activeColor: AppTheme.primaryNeon,
              onChanged: (_) {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined, color: AppTheme.textMain),
            title: const Text('Language'),
            subtitle: const Text('English (US)'),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
            onTap: () {},
          ),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              authVm.logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRose.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
