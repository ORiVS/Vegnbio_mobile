import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatefulWidget {
  static const route = '/c/profile/settings';
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool notifOrders = true;
  bool notifPromos = true;
  bool darkMode = false; // Branche si tu as un ThemeController

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: const Text('Notifications de commande'),
                value: notifOrders,
                onChanged: (v) => setState(() => notifOrders = v),
              ),
              const Divider(height: 0),
              SwitchListTile(
                secondary: const Icon(Icons.campaign),
                title: const Text('Notifications promos & actus'),
                value: notifPromos,
                onChanged: (v) => setState(() => notifPromos = v),
              ),
              const Divider(height: 0),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Thème sombre'),
                value: darkMode,
                onChanged: (v) => setState(() => darkMode = v),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
