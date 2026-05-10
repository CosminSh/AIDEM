import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:aidem_app/services/llm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/chat_list_view.dart';
import '../widgets/options_panel.dart';
import '../../providers/global_providers.dart';
import '../../services/context_compaction_service.dart';
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
  String? _pendingImagePath;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _typingDotController;

  @override
  void initState() {
    super.initState();
    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    Future.microtask(() async {
      await ref.read(speechServiceProvider.notifier).init();
    });
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
    if ((text.isEmpty && _pendingImagePath == null) || _isSending) return;

    final imagePath = _pendingImagePath;
    
    setState(() {
      _isSending = true;
      _pendingImagePath = null;
    });
    
    _textController.clear();
    _focusNode.requestFocus();

    await ref.read(sessionProvider.notifier).handleFreeformInput(text, imagePath: imagePath);

    setState(() => _isSending = false);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _pendingImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImagePath = null;
    });
  }

  Future<void> _exportChat() async {
    final markdown = ref.read(sessionProvider.notifier).generateMarkdownExport();
    
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'survival_aid_export.md',
      type: FileType.any,
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

  Future<void> _toggleDictation() async {
    final speech = ref.read(speechServiceProvider.notifier);
    final speechState = ref.read(speechServiceProvider);

    if (speechState.isListening) {
      await speech.stopListening();
    } else {
      final available = await speech.init();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available. Please check your microphone and Windows settings.')),
          );
        }
        return;
      }

      await speech.startListening(
        onResult: (words) {
          setState(() {
            _textController.text = words;
            // Move cursor to end
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
      );
      
      // Check for immediate errors after starting
      final newState = ref.read(speechServiceProvider);
      if (newState.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dictation Error: ${newState.error}')),
        );
      }
    }
  }

  Future<void> _showLanguageDialog() async {
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final languages = ContextCompactionService.supportedLanguages;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('SELECT LANGUAGE', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              return ListTile(
                title: Text(lang, style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  sessionNotifier.setLanguage(lang);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _shareLocation() async {
    try {
      final gps = ref.read(gpsServiceProvider);
      final location = await gps.getCurrentLocation();
      final dms = location.toDms();
      
      // Add a special message to chat about location
      await ref.read(sessionProvider.notifier).handleFreeformInput(
        "My current GPS coordinates are: $dms",
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location shared: $dms')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
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
          // LLM Status Indicator
          Consumer(
            builder: (context, ref, child) {
              final llmState = ref.watch(llmServiceProvider);
              Color statusColor;
              String statusText;
              
              switch (llmState.status) {
                case LlmStatus.ready:
                  statusColor = AppColors.success;
                  statusText = 'AI READY';
                  break;
                case LlmStatus.loading:
                  statusColor = AppColors.warning;
                  statusText = 'LOADING AI...';
                  break;
                case LlmStatus.mock:
                  statusColor = AppColors.warning;
                  statusText = 'MOCK MODE';
                  break;
                case LlmStatus.error:
                  statusColor = AppColors.accentRed;
                  statusText = 'AI ERROR';
                  break;
                default:
                  statusColor = AppColors.warning;
                  statusText = 'UNKNOWN';
                  break;
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (llmState.errorMessage != null &&
                          (llmState.status == LlmStatus.mock || llmState.status == LlmStatus.error)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('AI Error Details: ${llmState.errorMessage}'),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded, size: 20, color: AppColors.accentBlue),
            tooltip: 'Change Language',
            onPressed: _showLanguageDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Chat',
            onPressed: _exportChat,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _shareLocation,
              icon: const Icon(Icons.my_location, size: 20, color: AppColors.accentBlue),
              tooltip: 'Share My Location',
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
          
          // Initial Language Selector
          if (session.chatHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PRE-FLIGHT LANGUAGE SELECTION',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gemma supports 35+ languages. Select yours for best medical reasoning.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showLanguageDialog,
                      icon: const Icon(Icons.translate, size: 16),
                      label: const Text('CHOOSE LANGUAGE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
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
                    builder: (_, _) {
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

          // Image Preview Area
          if (_pendingImagePath != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_pendingImagePath!),
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.accentRed, size: 20),
                      onPressed: _clearPendingImage,
                    ),
                  ),
                ],
              ),
            ),

          // Quick Replies (Yes/No)
          if (session.chatHistory.isNotEmpty &&
              session.chatHistory.last.author == MessageAuthor.ai &&
              session.chatHistory.last.text.trim().endsWith('?') &&
              !session.isLlmTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ActionChip(
                    label: const Text('Yes', style: TextStyle(color: AppColors.textPrimary)),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.accentBlue.withValues(alpha: 0.5)),
                    onPressed: _isSending ? null : () {
                      _textController.text = 'Yes';
                      _sendMessage();
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('No', style: TextStyle(color: AppColors.textPrimary)),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.accentBlue.withValues(alpha: 0.5)),
                    onPressed: _isSending ? null : () {
                      _textController.text = 'No';
                      _sendMessage();
                    },
                  ),
                ],
              ),
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
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: session.isLlmTyping ? null : () => _pickImage(ImageSource.camera),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.image_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: session.isLlmTyping ? null : () => _pickImage(ImageSource.gallery),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final speechState = ref.watch(speechServiceProvider);
                      final isListening = speechState.isListening;
                      
                      return IconButton(
                        icon: Icon(
                          isListening ? Icons.graphic_eq_rounded : Icons.mic,
                          color: isListening ? AppColors.accentRed : AppColors.textSecondary,
                        ),
                        onPressed: session.isLlmTyping ? null : _toggleDictation,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    },
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
