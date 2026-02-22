// ============================================================
//  HelpCenterScreen – MaaCare
//  Searchable FAQ and support contact
// ============================================================

import 'package:flutter/material.dart';
import '../../app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, String>> _faqs = [
    {'q': 'How to use AI chat?', 'a': 'Just type your question in the chat screen! Maa AI is always listening and ready to support you.'},
    {'q': 'Is my data safe?', 'a': 'Yes! We use end-to-end encryption for your personal logs and never sell your data.'},
    {'q': 'How to track my baby\'s growth?', 'a': 'Go to the Pregnancy Tracker screen. We provide week-by-week updates based on your due date.'},
    {'q': 'What is Super Mom Premium?', 'a': 'It unlocks unlimited AI chats, priority consulting, and an ad-free experience for just ₹99.'},
  ];

  late List<Map<String, String>> _filteredFaqs;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _faqs;
  }

  void _filter(String query) {
    setState(() {
      _filteredFaqs = _faqs
          .where((f) => f['q']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center 🆘')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search FAQ (e.g., AI, Safety)...',
                prefixIcon: const Icon(Icons.search_rounded, color: MaaColors.deepPink),
                filled: true,
                fillColor: MaaColors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredFaqs.length,
              itemBuilder: (ctx, i) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(_filteredFaqs[i]['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_filteredFaqs[i]['a']!, style: const TextStyle(fontSize: 13, color: MaaColors.textGrey, height: 1.4)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildSupportFooter(),
        ],
      ),
    );
  }

  Widget _buildSupportFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: MaaColors.pink.withAlpha(20)),
      child: Column(
        children: [
          const Text('Still have questions?', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text('Ask Maa AI Companion'),
            style: TextButton.styleFrom(foregroundColor: MaaColors.deepPink),
          ),
        ],
      ),
    );
  }
}
