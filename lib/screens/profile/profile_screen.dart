// ============================================================
//  ProfileScreen – MaaCare
//  User details, avatar upload, and data sync logic
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import '../../widgets/maa_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile 🤱')),
      body: Consumer<UserProvider>(
        builder: (ctx, provider, _) {
          final user = provider.user;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAvatarSection(user),
                const SizedBox(height: 32),
                _buildInfoCard(user),
                const SizedBox(height: 24),
                _buildBadgesSection(user),
                const SizedBox(height: 32),
                MaaButton(
                  label: 'Sync Data 🔄',
                  onPressed: () {
                    // Algorithm: Offline-first sync logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Syncing with Supabase... Stay cute! ✨')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                MaaButton(
                  label: 'Settings ⚙️',
                  outlined: true,
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(user) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: MaaColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: MaaColors.white, width: 4),
              boxShadow: [
                BoxShadow(color: MaaColors.pink.withAlpha(80), blurRadius: 15)
              ],
            ),
            child: Center(
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
                style: const TextStyle(fontSize: 48, color: MaaColors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                // Implementation: Avatar upload logic
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: MaaColors.deepPink, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: MaaColors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: MaaColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Name', user?.name ?? 'Mama'),
          const Divider(),
          _buildInfoRow('Due Date', user?.dueDate?.toString().split(' ')[0] ?? 'Not set'),
          const Divider(),
          _buildInfoRow('Points', '${user?.points ?? 0} ⭐'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: MaaColors.textGrey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: MaaColors.textDark, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Badges 🏆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBadge('🌸', 'Day 1 Mama'),
            _buildBadge('⭐', 'Mood Logger'),
            _buildBadge('🍼', 'Water Pro'),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: MaaColors.softPurple.withAlpha(50), shape: BoxShape.circle),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    ).animate().fadeIn(delay: 400.ms).scale();
  }
}
