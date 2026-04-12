// ============================================================
//  PrivacyPolicyScreen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool showAcceptButton;
  final VoidCallback? onAccept;

  const PrivacyPolicyScreen({
    super.key,
    this.showAcceptButton = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Column(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your privacy is our priority 🤱',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MaaColors.textDark,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'At MaaCare, we collect data to provide you with a personalized experience. '
                    'This includes your pregnancy stage, mood logs, and health interests.\n\n'
                    '1. Data Usage: We use your data only for personalized tips, AI responses, and community matching.\n'
                    '2. Security: Your data is encrypted and stored securely.\n'
                    '3. Community: When you post in Parents Park, you can choose to remain anonymous.\n'
                    '4. Data Deletion: You can request to delete your data at any time from the settings.',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'By using this app, you agree to our privacy practices.',
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
                label: 'Agree & Continue 💕',
                onPressed: onAccept,
              ),
            ),
        ],
      ),
    );
  }
}
