// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  final file = File('lib/screens/guide/child_care_guide_screen.dart');
  String content = await file.readAsString();

  content = content.replaceFirst(
    "import '../../app_theme.dart';",
    "import '../../app_theme.dart';\nimport 'data/guide_localizations.dart';"
  );

  content = content.replaceFirst(
    "  late final List<GuideSection> _sections = [",
    "  List<GuideSection> _getSections(Map<String, dynamic> data) {\n    return ["
  );
  
  content = content.replaceFirst(
    "      content: _BreastfeedingContent(),",
    "      title: data['tabs'][0],\n      content: _BreastfeedingContent(data: data),"
  );
  content = content.replaceFirst(
    "      content: _LatchingContent(),",
    "      title: data['tabs'][1],\n      content: _LatchingContent(data: data),"
  );
  content = content.replaceFirst(
    "      content: _KMCContent(),",
    "      title: data['tabs'][2],\n      content: _KMCContent(data: data),"
  );
  content = content.replaceFirst(
    "      content: _FeedingContent(),",
    "      title: data['tabs'][3],\n      content: _FeedingContent(data: data),"
  );
  content = content.replaceFirst(
    "      content: _ToiletTrainingContent(),",
    "      title: data['tabs'][4],\n      content: _ToiletTrainingContent(data: data),"
  );
  content = content.replaceFirst(
    "      content: _PlayDevelopmentContent(),",
    "      title: data['tabs'][5],\n      content: _PlayDevelopmentContent(data: data),"
  );
  content = content.replaceFirst(
    "      content: _MilestonesContent(),",
    "      title: data['tabs'][6],\n      content: _MilestonesContent(data: data),"
  );

  content = content.replaceAll(RegExp(r"title: '[^']+',\n\s*icon:"), "icon:");

  content = content.replaceFirst(
    "  ];\n\n  @override",
    "    ];\n  }\n\n  @override"
  );

  content = content.replaceFirst(
    "  Widget build(BuildContext context) {",
    "  Widget build(BuildContext context) {\n    final data = GuideLocalizations.getChildCareData(context);\n    final _sections = _getSections(data);"
  );

  // Replace content classes
  content = content.replaceAll(RegExp(r"class _BreastfeedingContent extends StatelessWidget \{[\s\S]*?\}\n\}"), """class _BreastfeedingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BreastfeedingContent({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['breastfeeding']['header'],
            Icons.child_care_rounded,
            MaaColors.pink,
            imageEmoji: '🤱',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['breastfeeding']['infoTitle'],
            data['breastfeeding']['infoDesc'],
            MaaColors.softPurple,
          ),
          const SizedBox(height: 16),
          ...(data['breastfeeding']['bullets'] as List).map((b) => _buildBulletPoint(b.toString())),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['breastfeeding']['tipTitle'],
            data['breastfeeding']['tipDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}""");

  content = content.replaceAll(RegExp(r"class _LatchingContent extends StatelessWidget \{[\s\S]*?\}\n\}"), """class _LatchingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LatchingContent({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['latching']['header'],
            Icons.pregnant_woman_rounded,
            MaaColors.softPurple,
            imageEmoji: '💜',
          ),
          const SizedBox(height: 20),
          ...(data['latching']['steps'] as List).asMap().entries.map((e) => _buildStepCard(
            '\${e.key + 1}',
            e.value['title'],
            e.value['desc'],
            [MaaColors.pink, MaaColors.softPurple, MaaColors.warning, MaaColors.success, MaaColors.lightBlue][e.key % 5],
          )),
          const SizedBox(height: 24),
          _buildSubHeader(data['latching']['subHeader']),
          const SizedBox(height: 16),
          ...(data['latching']['positions'] as List).asMap().entries.map((e) => _buildPositionCard(
            e.value['title'],
            e.value['desc'],
            [Icons.chair_rounded, Icons.swap_horiz_rounded, Icons.sports_rounded, Icons.bed_rounded][e.key % 4],
          )),
        ],
      ),
    ).animate().fadeIn();
  }
}""");

  content = content.replaceAll(RegExp(r"class _KMCContent extends StatelessWidget \{[\s\S]*?\}\n\}"), """class _KMCContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KMCContent({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['kmc']['header'],
            Icons.favorite_rounded,
            MaaColors.warning,
            imageEmoji: '🦘',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['kmc']['infoTitle'],
            data['kmc']['infoDesc'],
            MaaColors.warning,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.pink.withAlpha(30),
                  MaaColors.softPurple.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.pink.withAlpha(40)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.wc_rounded,
                  size: 48,
                  color: MaaColors.pink,
                ),
                const SizedBox(height: 12),
                Text(
                  data['kmc']['howToTitle'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MaaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['kmc']['howToDesc'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSubHeader(data['kmc']['benefitsTitle']),
          const SizedBox(height: 16),
          ...(data['kmc']['benefits'] as List).asMap().entries.map((e) => _buildBenefitCard(
            e.value.toString(),
            [Icons.thermostat_rounded, Icons.favorite_rounded, Icons.trending_up_rounded, Icons.favorite_border_rounded, Icons.child_care_rounded, Icons.shield_rounded][e.key % 6]
          )),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['kmc']['rememberTitle'],
            data['kmc']['rememberDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}""");

  content = content.replaceAll(RegExp(r"class _FeedingContent extends StatelessWidget \{[\s\S]*?\}\n\}"), """class _FeedingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FeedingContent({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['feeding']['header'],
            Icons.restaurant_rounded,
            MaaColors.success,
            imageEmoji: '🥣',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['feeding']['infoTitle'],
            data['feeding']['infoDesc'],
            MaaColors.success,
          ),
          const SizedBox(height: 20),
          _buildSubHeader(data['feeding']['subHeader']),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: (data['feeding']['foods'] as List).asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildFoodChip(
                  e.value.toString(),
                  ['🌾', '🍌', '🥑', '🍠'][e.key % 4],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          ...(data['feeding']['bullets'] as List).map((b) => _buildBulletPoint(b.toString())),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['feeding']['alertTitle'],
            data['feeding']['alertDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}""");

  content = content.replaceAll(RegExp(r"class _ToiletTrainingContent extends StatelessWidget \{[\s\S]*?\}\n\}"), """class _ToiletTrainingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ToiletTrainingContent({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['toiletTraining']['header'],
            Icons.bathroom_rounded,
            MaaColors.lightBlue,
            imageEmoji: '🚽',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['toiletTraining']['infoTitle'],
            data['toiletTraining']['infoDesc'],
            MaaColors.lightBlue,
          ),
          const SizedBox(height: 20),
          _buildSubHeader(data['toiletTraining']['signsTitle']),
          const SizedBox(height: 12),
          ...(data['toiletTraining']['signs'] as List).map((s) => _buildBulletPoint(s.toString())),
          const SizedBox(height: 24),
          _buildSubHeader(data['toiletTraining']['stepsTitle']),
          const SizedBox(height: 16),
          ...(data['toiletTraining']['steps'] as List).asMap().entries.map((e) => _buildStepCard(
            '\${e.key + 1}',
            e.value['title'],
            e.value['desc'],
            [MaaColors.lightBlue, MaaColors.pink, MaaColors.success, MaaColors.warning][e.key % 4],
          )),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['toiletTraining']['tipTitle'],
            data['toiletTraining']['tipDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}""");

  content = content.replaceAll(RegExp(r"class _PlayDevelopmentContent extends StatelessWidget \{[\s\S]*?\}\n\}"), """class _PlayDevelopmentContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PlayDevelopmentContent({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['play']['header'],
            Icons.toys_rounded,
            MaaColors.gold,
            imageEmoji: '🧸',
          ),
          const SizedBox(height: 20),
          ...(data['play']['ages'] as List).asMap().entries.map((e) => _buildAgeGroupToysCard(
            e.value['title'],
            List<String>.from(e.value['items']),
            [MaaColors.gold, MaaColors.softPurple, MaaColors.pink, MaaColors.success][e.key % 4],
          )),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['play']['infoTitle'],
            data['play']['infoDesc'],
            MaaColors.pink,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}""");

  content = content.replaceAll(RegExp(r"class _MilestonesContent extends StatelessWidget \{[\s\S]*?\}\n\}"), """class _MilestonesContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MilestonesContent({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['milestones']['header'],
            Icons.auto_graph_rounded,
            MaaColors.primary,
            imageEmoji: '📈',
          ),
          const SizedBox(height: 20),
          ...(data['milestones']['stages'] as List).asMap().entries.map((e) => _buildMilestoneCard(
            e.value['title'],
            List<String>.from(e.value['items']),
            [MaaColors.primary, MaaColors.warning, MaaColors.pink, MaaColors.success][e.key % 4],
          )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MaaColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MaaColors.softPurple.withAlpha(50)),
            ),
            child: Text(
              data['milestones']['disclaimer'],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: MaaColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}""");

  await file.writeAsString(content);
  print('Done refactoring child_care_guide_screen.dart');
}
