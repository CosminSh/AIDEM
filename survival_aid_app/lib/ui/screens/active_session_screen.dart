import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/chat_list_view.dart';
import '../widgets/options_panel.dart';
import '../../providers/global_providers.dart';
import '../../models/protocol.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  late AnimationController _typingDotController;

  @override
  void initState() {
    super.initState();
    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingDotController.dispose();
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
    _focusNode.requestFocus();

    await ref.read(sessionProvider.notifier).handleFreeformInput(text);

    setState(() => _isSending = false);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Future<void> _exportChat() async {
    final markdown = ref.read(sessionProvider.notifier).generateMarkdownExport();
    
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'survival_aid_export.md',
      type: FileType.custom,
      allowedExtensions: ['md'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(markdown);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat exported to $outputFile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final String phaseTitle =
        session.currentNode?.id.toUpperCase().replaceAll('_', ' ') ?? 'ASSESSMENT';

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
              'CURRENT PHASE',
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
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Chat',
            onPressed: _exportChat,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('MY LOCATION'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentBlue,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(color: AppColors.border, height: 1),

          // Situation context chip (shows what Gemma knows)
          if (session.situationSummary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.accentBlue, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Context: ',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      session.situationSummary,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Chat history
          Expanded(
            child: ChatListView(
              messages: session.chatHistory,
              scrollController: _scrollController,
            ),
          ),

          // Streaming tokens (live typewriter as Gemma generates)
          if (session.isLlmTyping && session.streamingBuffer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                  ),
                  child: Text(
                    session.streamingBuffer,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ),

          // Gemma typing indicator (3 dots)
          if (session.isLlmTyping && session.streamingBuffer.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: AnimatedBuilder(
                    animation: _typingDotController,
                    builder: (_, __) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final opacity = ((_typingDotController.value * 3 - i) % 1.0).clamp(0.2, 1.0);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Opacity(
                              opacity: opacity,
                              child: const CircleAvatar(
                                radius: 4,
                                backgroundColor: AppColors.accentBlue,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ),

          const Divider(color: AppColors.border, height: 1),

          // Protocol option buttons
          // Hide buttons on 'start' node to encourage free-form description
          if (session.currentNode != null && 
              session.currentNode!.id != 'start' &&
              session.currentNode!.branches.isNotEmpty && 
              !session.isLlmTyping)
            OptionsPanel(
              branches: session.currentNode!.branches
                  .where((b) => b.target != 'start') // hide self-loop button
                  .toList(),
              onSelected: (branch) {
                ref.read(sessionProvider.notifier).handleUserSelection(branch);
                _scrollToBottom();
              },
            ),

          // Free-form Gemma input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: session.isLlmTyping
                      ? AppColors.accentBlue.withOpacity(0.5)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chat_input'),
                      controller: _textController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: session.isLlmTyping
                            ? 'Gemma is responding...'
                            : 'Describe your situation in detail...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.textSecondary),
                    onPressed: session.isLlmTyping ? null : () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: _isSending || session.isLlmTyping
                          ? AppColors.border
                          : AppColors.accentBlue,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        key: const ValueKey('send_button'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: (_isSending || session.isLlmTyping) ? null : _sendMessage,
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
