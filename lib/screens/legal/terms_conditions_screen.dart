// ============================================================
//  TermsConditionsScreen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

class TermsConditionsScreen extends StatelessWidget {
  final bool showAcceptButton;
  final VoidCallback? onAccept;

  const TermsConditionsScreen({
    super.key,
    this.showAcceptButton = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: Column(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safe & Supportive Space 🌸',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MaaColors.textDark,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'By joining MaaCare, you agree to follow our community guidelines:\n\n'
                    '1. Supportiveness: This is a safe space for all mothers. Harassment or negativity will not be tolerated.\n'
                    '2. Medical Advice: MaaCare provides informational support. Always consult your doctor for medical decisions.\n'
                    '3. Accountability: You are responsible for the content you share in public groups.\n'
                    '4. Subscription: Premium features are subject to our payment terms.',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Your journey is unique, and we are here to support it.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MaaColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showAcceptButton)
            Padding(
              padding: const EdgeInsets.all(20),
              child: MaaButton(
                label: 'Accept & Join 🤱',
                onPressed: onAccept,
              ),
            ),
        ],
      ),
    );
  }
}
