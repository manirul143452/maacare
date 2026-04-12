// ============================================================
//  Vaccination Tracker Screen – MaaCare (InsForge)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../models/symptom_vaccination_model.dart';
import '../../providers/user_provider.dart';
import '../../services/insforge_service.dart';

class VaccinationTrackerScreen extends StatefulWidget {
  const VaccinationTrackerScreen({super.key});

  @override
  State<VaccinationTrackerScreen> createState() =>
      _VaccinationTrackerScreenState();
}

class _VaccinationTrackerScreenState extends State<VaccinationTrackerScreen> {
  List<VaccinationModel>? _vaccinations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVaccinations();
  }

  Future<void> _loadVaccinations() async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      var list =
          await InsForgeService.instance.fetchVaccinations(user.id);

      if (list.isEmpty && user.dueDate != null) {
        // Generate schedule and save
        list = generateVaccinationSchedule(
          userId: user.id,
          dueDate: user.dueDate!,
        );
        await InsForgeService.instance.upsertVaccinations(list);
      }

      setState(() {
        _vaccinations = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading medical database: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleComplete(int index) async {
    if (_vaccinations == null) return;
    final vax = _vaccinations![index];
    setState(() => _vaccinations![index].completed = !vax.completed);

    try {
      await InsForgeService.instance
          .markVaccinationComplete(vax.id);
    } catch (_) {
      setState(() => _vaccinations![index].completed = vax.completed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _vaccinations?.length ?? 0;
    final done = _vaccinations?.where((v) => v.completed).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Vaccination Tracker 💉')),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (done < total) {
            debugPrint('Mama, don\'t miss any vaccines! Stay safe 🤱');
          }
        },
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: MaaColors.deepPink))
            : Column(
                children: [
                // Progress header
                Container(
                  padding: const EdgeInsets.all(20),
                  color: MaaColors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$done of $total completed',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge),
                          Text('${total > 0 ? ((done / total) * 100).toInt() : 0}%',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: MaaColors.deepPink)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: total > 0 ? done / total : 0.0,
                          minHeight: 10,
                          backgroundColor: MaaColors.pink.withAlpha(60),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              MaaColors.deepPink),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _vaccinations == null || _vaccinations!.isEmpty
                      ? const Center(
                          child: Text(
                              'No vaccination schedule yet.\nPlease add your due date in onboarding 💕'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _vaccinations!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final vax = _vaccinations![i];
                            final isOverdue = !vax.completed &&
                                vax.dueDate.isBefore(DateTime.now());

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: vax.completed
                                    ? MaaColors.success.withAlpha(15)
                                    : isOverdue
                                        ? MaaColors.error.withAlpha(10)
                                        : MaaColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: vax.completed
                                      ? MaaColors.success.withAlpha(60)
                                      : isOverdue
                                          ? MaaColors.error.withAlpha(60)
                                          : MaaColors.pink.withAlpha(60),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: vax.completed,
                                    onChanged: (_) => _toggleComplete(i),
                                    activeColor: MaaColors.deepPink,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vax.vaccineName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            decoration: vax.completed
                                                ? TextDecoration
                                                    .lineThrough
                                                : null,
                                            color: vax.completed
                                                ? MaaColors.textGrey
                                                : MaaColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          vax.description,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: MaaColors.textGrey),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 12,
                                              color: isOverdue
                                                  ? MaaColors.error
                                                  : MaaColors.textGrey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('dd MMM yyyy')
                                                  .format(vax.dueDate),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isOverdue
                                                    ? MaaColors.error
                                                    : MaaColors.textGrey,
                                                fontWeight: isOverdue
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                            if (isOverdue) ...[
                                              const SizedBox(width: 8),
                                              const Text('OVERDUE',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: MaaColors.error,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (vax.completed)
                                    const Text('✅',
                                        style: TextStyle(fontSize: 20)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      ),
    );
  }
}
