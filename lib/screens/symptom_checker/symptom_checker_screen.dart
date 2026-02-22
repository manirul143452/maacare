// ============================================================
//  Symptom Checker Screen – MaaCare (InsForge)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../models/symptom_vaccination_model.dart';
import '../../providers/user_provider.dart';
import '../../services/insforge_service.dart';
import '../../widgets/maa_button.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final Set<String> _selected = {};
  String? _riskLevel;
  bool _isChecking = false;

  void _checkSymptoms() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one symptom 💕')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _riskLevel = evaluateRisk(_selected.toList());
    });

    // Save to InsForge
    final userId = context.read<UserProvider>().user?.id;
    if (userId != null) {
      await InsForgeService.instance.saveSymptomCheck(
        userId: userId,
        symptoms: _selected.toList(),
        riskLevel: _riskLevel!,
      );
    }

    setState(() => _isChecking = false);
  }

  void _clearAll() {
    setState(() {
      _selected.clear();
      _riskLevel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker 🩺'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear',
                  style: TextStyle(color: MaaColors.deepPink)),
            ),
        ],
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (_selected.isNotEmpty && _riskLevel == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Don\'t forget to check your symptoms, Mama! 🩺')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MaaColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: MaaColors.warning.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This is for guidance only. Always consult your doctor for medical advice.',
                        style: TextStyle(
                            fontSize: 12, color: MaaColors.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Select your symptoms:',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: commonSymptoms.map((symptom) {
                  final isSelected = _selected.contains(symptom['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(symptom['name']);
                        } else {
                          _selected.add(symptom['name'] as String);
                        }
                        _riskLevel = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getSymptomColor(symptom['risk'] as String)
                                .withAlpha(40)
                            : MaaColors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? _getSymptomColor(symptom['risk'] as String)
                              : MaaColors.pink.withAlpha(80),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        '${symptom['emoji']} ${symptom['name']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? _getSymptomColor(symptom['risk'] as String)
                              : MaaColors.textDark,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              MaaButton(
                label: 'Check Symptoms',
                isLoading: _isChecking,
                onPressed: _checkSymptoms,
                icon: Icons.medical_information_rounded,
              ),

              if (_riskLevel != null) ...[
                const SizedBox(height: 24),
                _buildResult(_riskLevel!),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(String risk) {
    final config = {
      'low': {
        'color': MaaColors.success,
        'emoji': '✅',
        'title': 'Low Risk',
        'message':
            'These symptoms are common in pregnancy. Stay hydrated, rest well, and monitor changes. Consult your doctor at your next scheduled visit.',
      },
      'medium': {
        'color': MaaColors.warning,
        'emoji': '⚠️',
        'title': 'Moderate Risk',
        'message':
            'Some of your symptoms may need attention. We recommend consulting your doctor soon – don\'t wait for your next scheduled visit.',
      },
      'high': {
        'color': MaaColors.error,
        'emoji': '🚨',
        'title': 'High Risk – See Doctor Now',
        'message':
            'You have selected symptoms that require immediate medical attention. Please contact your OB/GYN or go to the nearest hospital immediately.',
      },
    };

    final c = config[risk]!;
    final color = c['color'] as Color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c['emoji'] as String,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                c['title'] as String,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(c['message'] as String,
              style: const TextStyle(
                  fontSize: 14, color: MaaColors.textGrey, height: 1.5)),
          const SizedBox(height: 16),
          MaaButton(
            label: 'Consult a Doctor 👩‍⚕️',
            onPressed: () => Navigator.pushNamed(context, '/consult'),
          ),
          const SizedBox(height: 12),
          MaaButton(
            label: 'Ask Maa AI About This 🤖',
            outlined: true,
            onPressed: () {
              final prompt = 'Mama, I just checked some symptoms: ${_selected.join(", ")}. '
                  'The risk predicted is $_riskLevel. Can you explain what I should do or if this is normal?';
              Navigator.pushNamed(context, '/chat', arguments: {'initialMessage': prompt});
            },
          ),
        ],
      ),
    );
  }

  Color _getSymptomColor(String risk) {
    switch (risk) {
      case 'high':
        return MaaColors.error;
      case 'medium':
        return MaaColors.warning;
      default:
        return MaaColors.success;
    }
  }
}
