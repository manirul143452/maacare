import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final bool isLoading;

  const SocialAuthButtons({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In Button
        _buildSocialButton(
          text: 'Continue with Google',
          iconData: Icons.g_mobiledata, // Use IconData instead of missing asset
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey.shade300,
          onTap: isLoading ? null : onGoogleSignIn,
        ),
        
        // Apple Sign In Button (Usually only shown on iOS, but can be configured for Android)
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
          const SizedBox(height: 16),
          _buildSocialButton(
            text: 'Continue with Apple',
            iconData: Icons.apple,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            borderColor: Colors.black,
            onTap: isLoading ? null : onAppleSignIn,
            isDarkIcon: true,
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required String text,
    IconData? iconData,
    String? iconPath,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback? onTap,
    bool isDarkIcon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              Image.asset(
                iconPath,
                height: 24,
                color: isDarkIcon ? Colors.white : null,
                errorBuilder: (context, error, stackTrace) => Icon(
                  iconData ?? Icons.login,
                  color: isDarkIcon ? Colors.white : Colors.black,
                  size: 28,
                ),
              )
            else if (iconData != null)
              Icon(
                iconData,
                color: isDarkIcon ? Colors.white : Colors.black,
                size: 32, // Slightly larger for better visual balance
              ),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
