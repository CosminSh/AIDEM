import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/chat_list_view.dart';
import '../widgets/options_panel.dart';
import '../../providers/global_providers.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    // Send to the session notifier which will pass it to Gemma
    await ref.read(sessionProvider.notifier).handleFreeformInput(text);

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final String phaseTitle = session.currentNode?.id.toUpperCase().replaceAll('_', ' ') ?? "ASSESSMENT";

    // Auto-scroll when new messages arrive
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CURRENT PHASE",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              phaseTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                // TODO: Navigate to My Location screen
              },
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text("MY LOCATION"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: ChatListView(
              messages: session.chatHistory,
              scrollController: _scrollController,
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Option Buttons Area (protocol tree choices)
          if (session.currentNode != null && session.currentNode!.branches.isNotEmpty)
            OptionsPanel(
              branches: session.currentNode!.branches,
              onSelected: (branch) {
                ref.read(sessionProvider.notifier).handleUserSelection(branch);
                _scrollToBottom();
              },
            ),

          // Free-form Gemma Input Area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Ask Gemma anything...",
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mic button
                  IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.textSecondary),
                    onPressed: () {
                      // TODO: wire speech_to_text
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: AppColors.accentBlue,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isSending ? null : _sendMessage,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
