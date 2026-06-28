import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/user_provider.dart';
import '../services/razorpay_web_service.dart';
import '../constants.dart';

class PremiumPaywallSheet extends StatefulWidget {
  final String? message;
  const PremiumPaywallSheet({super.key, this.message});

  static void show(BuildContext context, {String? message}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumPaywallSheet(message: message),
    );
  }

  @override
  State<PremiumPaywallSheet> createState() => _PremiumPaywallSheetState();
}

class _PremiumPaywallSheetState extends State<PremiumPaywallSheet> {
  bool _isLoading = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleMobilePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleMobilePaymentError);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.dispose();
  }

  void _handleMobilePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = false);
    final userProvider = context.read<UserProvider>();
    await userProvider.markPremium(
      planName: 'MaaCare Elite Pass',
      paymentId: response.paymentId ?? 'mobile_success',
    );
    if (mounted) {
      _showSuccessSnackBar();
      Navigator.pop(context);
    }
  }

  void _handleMobilePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown Error"}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome to Elite Pass! 🌟 All features unlocked!',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _startRazorpayCheckout() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    setState(() => _isLoading = true);

    if (kIsWeb) {
      RazorpayWebService.instance.openCheckout(
        keyId: AppConstants.razorpayKey,
        amount: 29900, // ₹299
        currency: 'INR',
        name: 'MaaCare',
        description: 'MaaCare Elite Pass',
        email: user?.email ?? '',
        phone: user?.phone ?? '',
        onSuccess: (paymentId) async {
          setState(() => _isLoading = false);
          await userProvider.markPremium(
            planName: 'MaaCare Elite Pass',
            paymentId: paymentId,
          );
          if (mounted) {
            _showSuccessSnackBar();
            Navigator.pop(context);
          }
        },
        onFailed: (error) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: $error'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        onDismiss: () {
          setState(() => _isLoading = false);
        },
      );
    } else {
      final options = {
        'key': AppConstants.razorpayKey,
        'amount': 29900, // ₹299
        'currency': 'INR',
        'name': 'MaaCare',
        'description': 'MaaCare Elite Pass',
        'prefill': {
          'email': user?.email ?? '',
          'contact': user?.phone ?? '',
        },
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open payment gateway: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _claimTrialUses() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.updateTrialUses(24);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Full Day Free Pass Claimed successfully! 🎁 Enjoy all premium features!',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim free trial: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final userProvider = context.watch<UserProvider>();
    final trialUsesLeft = userProvider.user?.trialUsesLeft ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151525), // Premium Deep Charcoal
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Unlock MaaCare Elite Pass',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0),
            
            if (widget.message != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.pinkAccent.shade100,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),

            // Advantage Cards Grid/List
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFeatureRow(
                    Icons.chat_bubble_outline,
                    'Unlimited AI Companion Chats',
                    'Get 24 hours of unrestricted, premium access to Sakhi AI. Ask unlimited questions about pregnancy, baby care, or parenting without any daily usage limits.',
                  ),
                  const Divider(color: Colors.white10),
                  _buildFeatureRow(
                    Icons.restaurant_menu,
                    'Nutrition & Contraceptive Timeline',
                    'Unlock your complete phase-specific daily meal plan, expert nutrition guides, and customized cycle tracking schedules tailored to your motherhood journey.',
                  ),
                  const Divider(color: Colors.white10),
                  _buildFeatureRow(
                    Icons.music_note,
                    'Relaxing Music Player',
                    'Access all premium sleep tracks, deep-relaxation music, and cycle harmony sound frequencies to soothe your mind and body throughout the day.',
                  ),
                  const Divider(color: Colors.white10),
                  _buildFeatureRow(
                    Icons.health_and_safety,
                    'Priority Gynecare Consultations',
                    'Skip the waiting queue! Get direct, high-priority chat connections to professional gynecologists and maternal care experts.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pricing Info
            Center(
              child: Column(
                children: [
                  Text(
                    '₹299 / Month',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cancel anytime. 100% secure checkout.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checkout Action Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startRazorpayCheckout,
              icon: const Icon(Icons.credit_card_rounded),
              label: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Pay with Razorpay 💳',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.pinkAccent.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),

            if (widget.message == null) ...[
              // Free Trial Option Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _claimTrialUses,
                icon: const Icon(Icons.card_giftcard_rounded),
                label: Text(
                  trialUsesLeft > 0
                      ? 'Full Day Free Pass Active 🎁 ($trialUsesLeft hrs left)'
                      : 'Claim Full Day Free Pass 🎁 (1 left)',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pinkAccent,
                  side: const BorderSide(color: Colors.pinkAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
