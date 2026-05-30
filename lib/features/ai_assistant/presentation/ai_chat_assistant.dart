import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../services/ai_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/local_auth_service.dart';

class AIChatAssistantPage extends ConsumerStatefulWidget {
  const AIChatAssistantPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AIChatAssistantPage> createState() => _AIChatAssistantPageState();
}

class _AIChatAssistantPageState extends ConsumerState<AIChatAssistantPage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  String _streamingText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  String _getUserId() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) return user.uid;
    final isGuest = ref.read(guestModeProvider);
    if (isGuest) return 'guest_user';
    return 'anonymous';
  }

  void _loadHistory() {
    final userId = _getUserId();
    final history = LocalStorageService.getAIChatHistory(userId);
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
    }
  }

  // Quick Starter Prompts
  final List<String> _starterPrompts = [
    "Sun'iy intellekt haqida insho yozish",
    "Mijozlar uchun rasmiy rahmatnoma yozish",
    "Kitob o'qishning 5 ta foydali tomoni",
    "Biznes loyiha uchun g'oyalar to'plami"
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _saveChatHistory() {
    final userId = _getUserId();
    LocalStorageService.saveAIChatHistory(userId, _messages);
  }

  // Handle message send
  Future<void> _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isGenerating) return;

    _inputController.clear();
    setState(() {
      _messages.add({'role': 'user', 'message': trimmedText});
      _isGenerating = true;
      _streamingText = '';
    });
    _scrollToBottom();
    _saveChatHistory();

    final aiService = ref.read(aiServiceProvider);

    try {
      // Package conversation history
      final history = _messages
          .sublist(0, _messages.length - 1)
          .map((msg) => {'role': msg['role']!, 'message': msg['message']!})
          .toList();

      final fullResponse = await aiService.chatMessage(trimmedText, history);
      
      // Perform a premium streaming characters typing animation
      await _animateTextStream(fullResponse);
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'model',
            'message': "Kechirasiz, so'rovni bajarishda xatolik yuz berdi: ${e.toString().replaceFirst("Exception: ", "")}"
          });
          _isGenerating = false;
        });
        _saveChatHistory();
      }
    }
  }

  // Streaming text animation characters
  Future<void> _animateTextStream(String fullResponse) async {
    final chars = fullResponse.split('');
    String currentText = '';
    
    for (int i = 0; i < chars.length; i++) {
      if (!mounted) return;
      currentText += chars[i];
      
      setState(() {
        _streamingText = currentText;
      });
      _scrollToBottom();
      
      // Variable delay for highly natural human-AI typing flow
      await Future.delayed(Duration(milliseconds: chars[i] == '.' || chars[i] == '\n' ? 60 : 15));
    }

    if (mounted) {
      setState(() {
        _messages.add({'role': 'model', 'message': fullResponse});
        _streamingText = '';
        _isGenerating = false;
      });
      _scrollToBottom();
      _saveChatHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              "Matn Muharriri AI Chat",
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat history stream
            Expanded(
              child: _messages.isEmpty
                  ? _buildConversationStarter(theme, isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _messages.length + (_isGenerating && _streamingText.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          // Show streaming message
                          return _buildChatBubble(
                            role: 'model',
                            message: _streamingText,
                            theme: theme,
                            isDark: isDark,
                            isStreaming: true,
                          );
                        }
                        
                        final msg = _messages[index];
                        return _buildChatBubble(
                          role: msg['role']!,
                          message: msg['message']!,
                          theme: theme,
                          isDark: isDark,
                        );
                      },
                    ),
            ),

            if (_isGenerating && _streamingText.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Matn Muharriri fikrlamoqda...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ),
              ),
            ],

            // Input panel box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor, width: 1.0),
                      ),
                      child: TextField(
                        controller: _inputController,
                        maxLines: null,
                        style: theme.textTheme.bodyLarge,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) => _sendMessage(val),
                        decoration: const InputDecoration(
                          hintText: "Matn Muharriri dan so'rang...",
                          filled: false,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_inputController.text),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationStarter(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.aiGradient,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            "Sun'iy intellektga asoslangan yordamchi",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Yozish va tahrirlash jarayonlaringizni jadallashtiring. Istalgan mavzuda matn yarating, savollar so'rang yoki hujjatlarni tahlil qiling.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Quyidagi shablonlardan boshlang:",
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _starterPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) => GestureDetector(
              onTap: () => _sendMessage(_starterPrompts[idx]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor, width: 1.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.primaryColor, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _starterPrompts[idx],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required String role,
    required String message,
    required ThemeData theme,
    required bool isDark,
    bool isStreaming = false,
  }) {
    final isUser = role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.primaryColor
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: theme.primaryColor, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
