import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../models/doctor_model.dart';
import '../../widgets/maa_button.dart';
import '../../widgets/booking_checkout_sheet.dart';

class DoctorProfileScreen extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('About Doctor'),
                  const SizedBox(height: 8),
                  _buildBio(),
                  const SizedBox(height: 32),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Consultation Hours'),
                  const SizedBox(height: 8),
                  _buildAvailability(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 8),
                  _buildLocation(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: MaaColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: MaaColors.primaryGradient,
              ),
            ),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: MaaColors.white.withAlpha(50),
                  shape: BoxShape.circle,
                  border: Border.all(color: MaaColors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    doctor.emoji,
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MaaColors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    doctor.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: MaaColors.white,
                    ),
                  ),
                  if (doctor.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified_rounded,
                      color: MaaColors.pink,
                      size: 22,
                    ).animate(onPlay: (controller) => controller.repeat())
                     .shimmer(duration: 2.seconds, color: MaaColors.white.withAlpha(100))
                  ],
                ],
              ),
              Text(
                doctor.specialization,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: MaaColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: MaaColors.white,
      ),
    );
  }

  Widget _buildBio() {
    return Text(
      doctor.bio.isEmpty 
          ? "Dr. ${doctor.name} is a highly experienced ${doctor.specialization} committed to providing the best care for mothers and babies."
          : doctor.bio,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: MaaColors.textSecondary,
        height: 1.6,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('Experience', doctor.experience, Icons.work_history_rounded, MaaColors.peach),
        _buildStatCard('Rating', doctor.rating, Icons.star_rounded, MaaColors.gold),
        _buildStatCard('Fee', doctor.fee, Icons.payments_rounded, MaaColors.success),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MaaColors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: MaaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: MaaColors.pink),
          const SizedBox(width: 12),
          Text(
            doctor.availableHours,
            style: GoogleFonts.poppins(color: MaaColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: MaaColors.peach),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              doctor.clinicLocation,
              style: GoogleFonts.poppins(color: MaaColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MaaColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: MaaButton(
        label: 'Book Video Consultation',
        onPressed: () => BookingCheckoutSheet.show(context, doctor),
        icon: Icons.videocam_rounded,
      ),
    );
  }
}
