// ============================================================
//  DoctorSlotsScreen – Shift & Slot Configurator
//  Clinical, premium dark theme. Configures days, hours, and 20-min slots.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../widgets/maa_button.dart';

class DoctorSlotsScreen extends StatefulWidget {
  const DoctorSlotsScreen({super.key});

  @override
  State<DoctorSlotsScreen> createState() => _DoctorSlotsScreenState();
}

class _DoctorSlotsScreenState extends State<DoctorSlotsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  DoctorModel? _doctor;
  List<BookingModel> _appointments = [];
  DateTime _selectedDate = DateTime.now();

  // Local config states
  List<String> _selectedDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final doc = await MaaCareBackendService.instance.fetchDoctorByUserId(user.id);
    if (doc != null) {
      final apps = await MaaCareBackendService.instance.fetchAppointmentsForDoctor(doc.id);
      
      // Parse database start/end times
      TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
      try {
        final parts = doc.dailyStartTime.split(':');
        start = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}

      TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);
      try {
        final parts = doc.dailyEndTime.split(':');
        end = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}

      if (mounted) {
        setState(() {
          _doctor = doc;
          _appointments = apps;
          _selectedDays = List<String>.from(doc.availableDays);
          _startTime = start;
          _endTime = end;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_doctor == null) return;
    setState(() => _isSaving = true);

    final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
    final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

    final success = await MaaCareBackendService.instance.updateDoctorProfile(_doctor!.id, {
      'available_days': _selectedDays,
      'daily_start_time': startStr,
      'daily_end_time': endStr,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedules saved successfully! 🩺'), backgroundColor: MaaColors.pink),
        );
        // Reload configuration
        _loadConfig();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save configuration.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<DateTime> _generateSlotsForDay(DateTime date) {
    final List<DateTime> slots = [];
    final startDateTime = DateTime(date.year, date.month, date.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(date.year, date.month, date.day, _endTime.hour, _endTime.minute);

    DateTime current = startDateTime;
    while (current.isBefore(endDateTime)) {
      slots.add(current);
      current = current.add(const Duration(minutes: 20));
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MaaColors.background,
        body: Center(child: CircularProgressIndicator(color: MaaColors.pink)),
      );
    }

    if (_doctor == null) {
      return const Scaffold(
        backgroundColor: MaaColors.background,
        body: Center(child: Text('Error: No doctor profile found.', style: TextStyle(color: Colors.white))),
      );
    }

    final dateSlots = _generateSlotsForDay(_selectedDate);
    final isWorkingDay = _selectedDays.contains(DateFormat('EEEE').format(_selectedDate));

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: MaaColors.cardDark,
        elevation: 0,
        title: Text('Timing Slot Configurator', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActiveDaysConfig(),
                const SizedBox(height: 24),
                _buildShiftHoursConfig(),
                const SizedBox(height: 24),
                _buildPreviewSection(dateSlots, isWorkingDay),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: MaaColors.pink),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        color: MaaColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: MaaButton(
          label: 'Save Schedules',
          onPressed: _saveConfig,
        ),
      ),
    );
  }

  Widget _buildActiveDaysConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Available Days',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the days you are active for consulting bookings.',
            style: GoogleFonts.outfit(fontSize: 12, color: MaaColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                selectedColor: MaaColors.pink,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                checkmarkColor: Colors.black,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftHoursConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Consulting Hours',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure your starting and ending work shift times.',
            style: GoogleFonts.outfit(fontSize: 12, color: MaaColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (picked != null) {
                      setState(() => _startTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start: ${_startTime.format(context)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const Icon(Icons.access_time_rounded, color: Colors.white60, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (picked != null) {
                      setState(() => _endTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'End: ${_endTime.format(context)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const Icon(Icons.access_time_rounded, color: Colors.white60, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(List<DateTime> dateSlots, bool isWorkingDay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slots Preview',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: MaaColors.pink,
                            onPrimary: Colors.white,
                            surface: MaaColors.cardDark,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Row(
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(color: MaaColors.pink, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_calendar_outlined, color: MaaColors.pink, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Preview dynamic 20-minute interval schedules and bookings.',
            style: GoogleFonts.outfit(fontSize: 12, color: MaaColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (!isWorkingDay)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '💤 Weekend / Non-Working Day',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else if (dateSlots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No slots generated. Check Shift Timings.',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dateSlots.length,
              itemBuilder: (context, index) {
                final slotStart = dateSlots[index];
                final slotEnd = slotStart.add(const Duration(minutes: 20));

                // Check double-booking validation
                final booking = _appointments.firstWhere(
                  (app) =>
                      app.appointmentDate.year == slotStart.year &&
                      app.appointmentDate.month == slotStart.month &&
                      app.appointmentDate.day == slotStart.day &&
                      app.appointmentDate.hour == slotStart.hour &&
                      app.appointmentDate.minute == slotStart.minute,
                  orElse: () => BookingModel(
                    id: '',
                    userId: '',
                    doctorId: '',
                    patientName: '',
                    symptoms: '',
                    appointmentDate: DateTime.fromMillisecondsSinceEpoch(0),
                    status: '',
                    paymentStatus: '',
                    meetingLink: '',
                    amount: '',
                    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                  ),
                );

                final isBooked = booking.id.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isBooked ? Colors.red.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBooked ? Colors.redAccent.withValues(alpha: 0.2) : Colors.greenAccent.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isBooked ? Icons.lock_clock_rounded : Icons.check_circle_outline_rounded,
                            color: isBooked ? Colors.redAccent : Colors.greenAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${DateFormat('hh:mm a').format(slotStart)} - ${DateFormat('hh:mm a').format(slotEnd)}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: isBooked ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isBooked ? 'Booked: ${booking.patientName}' : 'Available',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isBooked ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
