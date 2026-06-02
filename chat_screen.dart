import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_Message> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _showSuggestions = true;

  final List<String> _suggestions = [
    'How do I manage blood pressure?',
    'Foods to avoid with my medicine?',
    'Tips for taking medicines on time',
    'What does my adherence score mean?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      text: "Hello! I'm your CareSync AI health assistant. Ask me about your medications, diet tips, or health advice.",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _ctrl.clear();
      _sending = true;
      _showSuggestions = false;
    });
    _scrollToBottom();

    try {
      final response = await ApiService.sendChatMessage(text);
      if (mounted) {
        setState(() {
          _messages.add(_Message(text: response, isUser: false));
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Message(
            //text: "Sorry, I couldn't connect. Please check your connection.",
            text: "Error: $e",
            isUser: false,
          ));
          _sending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatusBar(),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i >= _messages.length) return _buildTypingIndicator();
              final msg = _messages[i];
              return Column(
                children: [
                  _buildMessage(msg),
                  if (i == 0 && _showSuggestions) _buildSuggestions(),
                ],
              );
            },
          ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.tealGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CareSync AI', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text('Online', style: GoogleFonts.poppins(color: AppColors.green, fontSize: 11)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: AppColors.teal, size: 13),
                const SizedBox(width: 4),
                Text('AI Powered', style: GoogleFonts.poppins(color: AppColors.teal, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Try asking:', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _suggestions.map((s) => GestureDetector(
              onTap: () => _send(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                ),
                child: Text(s, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.teal)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_Message msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(gradient: AppColors.tealGradient, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: msg.isUser ? AppColors.navyGradient : null,
                color: msg.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: msg.isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: AppColors.navy.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.person, color: AppColors.navy, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(gradient: AppColors.tealGradient, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.6), shape: BoxShape.circle),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _send(),
              maxLines: null,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask about your health...',
                hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: _sending ? null : AppColors.navyGradient,
                color: _sending ? AppColors.border : null,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
