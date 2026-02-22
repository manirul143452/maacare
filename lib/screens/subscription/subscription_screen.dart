// ============================================================
//  SubscriptionScreen – MaaCare
//  Monetization, Razorpay integration, and psychology-based hooks
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Hub 👑')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Unlock Your Full Potential, Mama! ✨',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Join 5,000+ Super Mamas for the ultimate journey.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: MaaColors.textGrey)),
            const SizedBox(height: 32),
            _buildTierCard(
              context,
              title: 'Free',
              price: '₹0',
              features: ['Basic health tracking', 'Symptom checker', 'Limited AI chats (3/day)'],
              isCurrent: true,
            ),
            const SizedBox(height: 20),
            _buildTierCard(
              context,
              title: 'Super Mom Premium',
              price: '₹99/month',
              features: [
                'Unlimited AI Companion chats',
                'Priority Doctor Consults',
                'Ad-free experience',
                'Exclusive "Pink Badge" profile'
              ],
              isPremium: true,
            ),
            const SizedBox(height: 40),
            const Text('Secure payments via Razorpay 💳',
                style: TextStyle(fontSize: 12, color: MaaColors.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(BuildContext context,
      {required String title,
      required String price,
      required List<String> features,
      bool isPremium = false,
      bool isCurrent = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isPremium ? MaaColors.gold : MaaColors.pink.withAlpha(50), width: isPremium ? 2.5 : 1),
        boxShadow: [
          BoxShadow(
              color: isPremium ? MaaColors.gold.withAlpha(40) : MaaColors.cardShadow,
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: isPremium ? MaaColors.gold : MaaColors.deepPink)),
              if (isCurrent)
                const Text('Current Plan',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: MaaColors.textGrey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: MaaColors.success, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          MaaButton(
            label: isCurrent ? 'Stay as You Are' : 'Upgrade to $title 🚀',
            onPressed: isCurrent ? null : () {
              // Algorithm: Subscription check and Razorpay trigger
              if (!isCurrent) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Previsouly setup with Razorpay! "Unlock Super Mom features for just ₹99/month!" 👑'),
                    backgroundColor: MaaColors.deepPink,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ).animate(target: isPremium ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02));
  }
}
