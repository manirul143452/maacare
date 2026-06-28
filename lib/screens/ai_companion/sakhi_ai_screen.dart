// ============================================================
//  SakhiAiScreen – elder-sisterly AI companion
//  Premium, dark-themed. Isolated from maternal AI flow.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/menstrual_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/premium_paywall_sheet.dart';
import '../../services/bmi_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SakhiAiScreen extends StatefulWidget {
  const SakhiAiScreen({super.key});

  @override
  State<SakhiAiScreen> createState() => _SakhiAiScreenState();
}

class _SakhiAiScreenState extends State<SakhiAiScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final _uuid = const Uuid();

  String? _conversationId;
  bool _isLoading = false;
  bool _isTyping = false;
  int _freeAiChatCount = 0;
  bool _paywallShown = false;

  final String _sakhiSystemPrompt = """
You are 'Sakhi AI', a caring elder sister companion for unmarried girls and women on the MaaCare platform. 
Offer comforting, empathetic, and culturally nuanced sisterly advice using Hinglish and English. 
Absolutely exclude pregnancy, childbirth, or babies from your discussions, as this user is seeking cycle and general menstrual support. 
Be a warm, wise elder sister guide, addressing the user as 'Sakhi' or 'Sis'.
""";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSakhiChat();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSakhiChat() async {
    setState(() => _isLoading = true);
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final sub = await MaaCareBackendService.instance.fetchUserSubscription(user.id);
      if (sub != null) {
        _freeAiChatCount = sub['free_ai_chat_count'] as int? ?? 0;
      }

      final convs = await MaaCareBackendService.instance.fetchConversations(user.id);
      final sakhiConv = convs.firstWhere(
        (c) => c.title == 'Sakhi Chat',
        orElse: () => ConversationModel(
          id: '',
          userId: '',
          title: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );

      if (sakhiConv.id.isNotEmpty) {
        _conversationId = sakhiConv.id;
        await _loadMessages(user.id);
      } else {
        // Create new Sakhi conversation
        final newId = _uuid.v4();
        final newConv = ConversationModel(
          id: newId,
          userId: user.id,
          title: 'Sakhi Chat',
          createdAt: DateTime.now(),
        );
        await MaaCareBackendService.instance.createConversation(newConv);
        _conversationId = newId;
        _addWelcomeMessage();
      }
    } catch (e) {
      debugPrint('Error initializing Sakhi Chat: $e');
      _addWelcomeMessage();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
      _checkPaywall();
    }
  }

  void _checkPaywall() {
    final user = context.read<UserProvider>().user;
    final isPremium = user?.isPremium ?? false;
    if (!isPremium && _freeAiChatCount >= 5 && !_paywallShown) {
      _paywallShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PremiumPaywallSheet.show(context, message: "You've successfully tested your 5 Free AI Consultations. Upgrade to MaaCare Elite Pass for continuous, personalized guidance.");
      });
    }
  }

  Future<void> _loadMessages(String userId) async {
    if (_conversationId == null) return;
    final history = await MaaCareBackendService.instance.fetchChatHistory(userId, conversationId: _conversationId);
    setState(() {
      _messages.clear();
      if (history.isEmpty) {
        _addWelcomeMessage();
      } else {
        _messages.addAll(history);
      }
    });
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      conversationId: _conversationId,
      userId: 'system',
      role: 'assistant',
      content: 'Namaste, Sakhi! 🌸 I am your elder sister and AI companion. I\'m here to listen, support, and help you navigate your period wellness, self-care, or PCOS concerns in absolute confidence. How are you feeling today? 💕',
      createdAt: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final user = context.read<UserProvider>().user;
    final isPremium = user?.isPremium ?? false;
    if (user == null || _conversationId == null) return;

    if (!isPremium && _freeAiChatCount >= 5) {
      PremiumPaywallSheet.show(context, message: "You've successfully tested your 5 Free AI Consultations. Upgrade to MaaCare Elite Pass for continuous, personalized guidance.");
      return;
    }

    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      conversationId: _conversationId,
      userId: user.id,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    // Fire and forget save
    MaaCareBackendService.instance.saveMessage(userMsg).catchError((_) {});

    try {
      // Prepare history payload for AI context (last 10 messages)
      final rawHistory = (_messages.length > 10
              ? _messages.sublist(_messages.length - 10)
              : _messages)
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      // Pre-append cycle details and logged symptoms to the query payload (the last user message)
      if (rawHistory.isNotEmpty && rawHistory.last['role'] == 'user') {
        final menstrual = context.read<MenstrualProvider>();
        final phase = menstrual.cyclePhase;
        final loggedSymptoms = menstrual.loggedSymptoms;
        final symptomsStr = loggedSymptoms.isEmpty ? 'None logged' : loggedSymptoms.join(', ');
        final daysLeft = menstrual.daysUntilNextPeriod;
        final isLate = menstrual.isPeriodLate;
        final daysLateStr = isLate ? '${menstrual.daysLate} Days Late' : '$daysLeft Days Left';

        final heightVal = user.heightCm ?? 0.0;
        final weightVal = user.weightKg ?? 0.0;
        final bmiScore = BmiHelper.calculateBmi(heightCm: heightVal, weightKg: weightVal);
        final bmiStatus = bmiScore > 0 ? BmiHelper.getBmiStatus(bmiScore) : 'Unknown';
        final bmiAlert = bmiScore > 0 ? BmiHelper.getBmiAlert(bmiScore) : 'Not set';
        final bmiContextStr = bmiScore > 0 
            ? 'Score: ${bmiScore.toStringAsFixed(1)}, Status: $bmiStatus, Guidance: $bmiAlert' 
            : 'Not set';

        final prefs = await SharedPreferences.getInstance();
        int chatCount = prefs.getInt('severe_symptom_chat_count') ?? 0;
        String criticalAlertStr = '';
        if (chatCount > 0) {
          await prefs.setInt('severe_symptom_chat_count', chatCount - 1);
          final severeSymptoms = menstrual.loggedSymptomDetails
              .where((d) => d['severity_level'] == 'severe')
              .map((d) => d['symptom_name'] as String)
              .toList();
          if (severeSymptoms.isNotEmpty) {
            criticalAlertStr = ', CRITICAL HEALTH NOTICE: User logged severe symptoms: ${severeSymptoms.join(', ')}. Please check on their health, offer support guidelines, and recommend consulting a gynaecologist';
          }
        }

        final originalContent = rawHistory.last['content'];
        rawHistory.last['content'] = '''
[Context - Cycle Phase: $phase, Cycle State: $daysLateStr, Logged Symptoms: $symptomsStr, BMI Metrics: $bmiContextStr$criticalAlertStr]
User query: $originalContent
''';
      }

      final response = await MaaCareBackendService.instance.invokeAiChat(
        rawHistory,
        systemPrompt: _sakhiSystemPrompt,
      );

      if (response != null) {
        if (response.containsKey('free_ai_chat_count')) {
          _freeAiChatCount = response['free_ai_chat_count'] as int;
        } else if (response['data'] != null &&
            response['data'] is Map &&
            response['data'].containsKey('free_ai_chat_count')) {
          _freeAiChatCount = response['data']['free_ai_chat_count'] as int;
        }

        final isPaywallRoot = response['paywall_limit'] == true;
        final isPaywallData = response['data'] != null &&
            response['data'] is Map &&
            response['data']['paywall_limit'] == true;

        if (isPaywallRoot || isPaywallData || _freeAiChatCount >= 5) {
          setState(() {
            _isTyping = false;
          });
          _checkPaywall();
          return;
        }
      }

      String aiResponseText = 'Achanak network chala gaya, Sis. 💕 Please try again in a moment.';

      if (response != null) {
        if (response.containsKey('data') && response['data'] != null) {
          final data = response['data'];
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            aiResponseText = data['choices'][0]['message']['content'] ?? aiResponseText;
          }
        } else if (response.containsKey('choices') && response['choices'] != null) {
          if (response['choices'].isNotEmpty) {
            aiResponseText = response['choices'][0]['message']['content'] ?? aiResponseText;
          }
        }
      }

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        conversationId: _conversationId,
        userId: 'sakhi_ai',
        role: 'assistant',
        content: aiResponseText,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMsg);
        _isTyping = false;
      });
      _scrollToBottom();

      MaaCareBackendService.instance.saveMessage(assistantMsg).catchError((_) {});
    } catch (e) {
      debugPrint('Error invoking Sakhi AI: $e');
      setState(() => _isTyping = false);
    }
  }

  Future<void> _clearChatHistory() async {
    if (_conversationId == null) return;
    setState(() => _isLoading = true);
    try {
      await MaaCareBackendService.instance.deleteChatHistory(_conversationId!);
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
    } catch (e) {
      debugPrint('Error deleting chat history: $e');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: MaaColors.cardDark,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: MaaColors.pink,
              child: Text('👩‍🦰', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sakhi AI',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Your Elder Sister Companion',
                  style: GoogleFonts.outfit(fontSize: 11, color: MaaColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'clear') _clearChatHistory();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clear',
                child: Text(AppLocalizations.of(context).clearHistory),
              ),
            ],
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (ctx, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingBubble();
                  }
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: MaaColors.pink,
              child: Text('👩‍🦰', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? MaaColors.pink : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: MaaColors.cardDark,
              child: Icon(Icons.person, color: MaaColors.pink, size: 16),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: MaaColors.pink,
            child: Text('👩‍🦰', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.zero,
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(),
                _buildDot(delay: 200),
                _buildDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({int delay = 0}) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: Colors.white70,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 400.ms, delay: Duration(milliseconds: delay));
  }

  Widget _buildInputBar() {
    final user = context.watch<UserProvider>().user;
    final isPremium = user?.isPremium ?? false;
    final isLocked = !isPremium && _freeAiChatCount >= 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !isLocked,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isLocked 
                    ? 'Limit reached. Upgrade to Premium... 🔒' 
                    : 'Ask Sakhi AI anything in absolute privacy... 🌸',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => isLocked ? null : _sendMessage(),
              maxLines: null,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: MaaColors.pink),
            onPressed: isLocked ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
