import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:aidem_app/services/llm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/chat_list_view.dart';
import '../../providers/global_providers.dart';
import '../../providers/session_provider.dart';
import '../../services/context_compaction_service.dart';
import '../../services/voice_input_settings_service.dart';
import '../../models/protocol.dart';
import '../widgets/tactical_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'session_summary_screen.dart';

bool isBinaryYesNoQuestion(String text) {
  final trimmed = text.trim();
  if (!trimmed.endsWith('?')) return false;

  final parts = trimmed.split(RegExp(r'[.!?]'));
  final lastPart = parts.reversed
      .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '')
      .trim()
      .toLowerCase();
  if (lastPart.isEmpty) return false;

  if (RegExp(r'\b(what|where|when|why|how|which|who)\b').hasMatch(lastPart)) {
    return false;
  }

  final hasExplicitYesNo =
      lastPart.contains(' or not') || lastPart.contains(' yes or no');
  final hasAlternativeChoice =
      RegExp(r'\bor\b').hasMatch(lastPart) && !hasExplicitYesNo;
  if (hasAlternativeChoice) return false;

  final yesNoStarts = [
    'is ',
    'are ',
    'do ',
    'does ',
    'did ',
    'can ',
    'could ',
    'should ',
    'would ',
    'will ',
    'has ',
    'have ',
    'was ',
    'were ',
    'am ',
    'shall ',
    'may ',
    'might ',
    'must ',
  ];

  return yesNoStarts.any((start) => lastPart.startsWith(start)) ||
      hasExplicitYesNo;
}

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
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
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  bool _isTrackingPath = false;
  bool _desktopToolsExpanded = false;
  DateTime? _lastPathFixAt;
  String? _lastSpokenAiSignature;

  @override
  void initState() {
    super.initState();
    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    Future.microtask(() async {
      await ref.read(speechServiceProvider.notifier).init();
    });

    ref.listenManual(gpsStreamProvider, (previous, next) {
      if (!_isTrackingPath) {
        return;
      }

      final coords = next.when(
        data: (value) => value,
        error: (_, _) => null,
        loading: () => null,
      );
      if (coords == null) {
        return;
      }

      final now = DateTime.now();
      if (_lastPathFixAt != null &&
          now.difference(_lastPathFixAt!).inSeconds < 30) {
        return;
      }

      _lastPathFixAt = now;
      ref.read(sessionProvider.notifier).addLocationFix(coords);
    });

    ref.listenManual(sessionProvider, (previous, next) {
      if (next.isLlmTyping || next.chatHistory.isEmpty) {
        return;
      }

      final lastMessage = next.chatHistory.last;
      if (lastMessage.author != MessageAuthor.ai) {
        return;
      }

      final signature =
          '${lastMessage.timestamp.toIso8601String()}-${lastMessage.text}';
      if (_lastSpokenAiSignature == signature) {
        return;
      }

      _lastSpokenAiSignature = signature;
      final language = ref
          .read(contextCompactionServiceProvider)
          .context
          .detectedLanguage;
      ref
          .read(voiceServiceProvider.notifier)
          .speakAiMessage(lastMessage.text, language: language);
    });

    ref.listenManual(voiceServiceProvider, (previous, next) {
      final error = next.errorMessage;
      if (error == null || previous?.errorMessage == error || !mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingDotController.dispose();
    _breathController.dispose();
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

    await ref
        .read(sessionProvider.notifier)
        .handleFreeformInput(text, imagePath: imagePath);

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
    final markdown = ref
        .read(sessionProvider.notifier)
        .generateMarkdownExport();

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'AIDEM_rescue_handoff.md',
      type: FileType.any,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(markdown);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Chat exported to $outputFile')));
      }
    }
  }

  Future<void> _toggleDictation() async {
    final speech = ref.read(speechServiceProvider.notifier);
    final speechState = ref.read(speechServiceProvider);
    final vosk = ref.read(voskSpeechProvider.notifier);
    final voskState = ref.read(voskSpeechProvider);
    final inputMode = ref.read(voiceInputSettingsProvider).mode;

    if (speechState.isListening || voskState.isListening) {
      await speech.stopListening();
      await vosk.stopListening();
      return;
    }

    if (inputMode == VoiceInputMode.offlineVosk ||
        (inputMode == VoiceInputMode.automatic && Platform.isWindows)) {
      final started = await _startVoskDictation();
      if (started) {
        return;
      }
      if (inputMode == VoiceInputMode.offlineVosk) {
        return;
      }
    }

    final available = await speech.init();
    if (!available) {
      final started = await _startVoskDictation();
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice input is unavailable. Open Settings > Voice diagnostics to prepare the offline fallback.',
            ),
          ),
        );
      }
    } else {
      final started = await speech.startListening(
        onResult: _applyDictationText,
      );
      final newState = ref.read(speechServiceProvider);
      if ((!started || newState.error != null) &&
          inputMode != VoiceInputMode.nativeSystem &&
          mounted) {
        final fallbackStarted = await _startVoskDictation();
        if (!fallbackStarted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Dictation Error: ${newState.error ?? 'Native speech did not start.'}',
              ),
            ),
          );
        }
      } else if ((!started || newState.error != null) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Native dictation error: ${newState.error ?? 'Native speech did not start.'}',
            ),
          ),
        );
      }
    }
  }

  void _applyDictationText(String words) {
    setState(() {
      _textController.text = words;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  Future<bool> _startVoskDictation() async {
    final vosk = ref.read(voskSpeechProvider.notifier);
    final settings = ref.read(voiceInputSettingsProvider);

    await vosk.startListening(
      onResult: _applyDictationText,
      deviceId: settings.inputDeviceId,
    );
    final state = ref.read(voskSpeechProvider);
    if (state.isListening) {
      if (mounted) {
        final debugEnabled = ref.read(voiceInputSettingsProvider).debugEnabled;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              debugEnabled
                  ? 'Offline voice input active. Speak now; debug counters are in Settings.'
                  : 'Offline voice input active.',
            ),
          ),
        );
      }
      return true;
    }

    if (state.error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
    }
    return false;
  }

  Future<void> _showLanguageDialog() async {
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final languages = ContextCompactionService.supportedLanguages;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'SELECT LANGUAGE',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              return ListTile(
                title: Text(
                  lang,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
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
      ref.read(sessionProvider.notifier).addLocationFix(location);

      // Add a special message to chat about location
      await ref
          .read(sessionProvider.notifier)
          .handleFreeformInput("My current GPS coordinates are: $dms");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location shared: $dms')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  void _togglePathTracking() {
    setState(() {
      _isTrackingPath = !_isTrackingPath;
      _lastPathFixAt = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTrackingPath
              ? 'Path recording started. GPS fixes will be added to the handoff.'
              : 'Path recording stopped.',
        ),
      ),
    );
  }

  Future<void> _toggleVoiceReading() async {
    final voice = ref.read(voiceServiceProvider);
    await ref.read(voiceServiceProvider.notifier).toggle();
    final updated = ref.read(voiceServiceProvider);

    if (!mounted) {
      return;
    }

    if (!voice.enabled && updated.enabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voice reading enabled.')));

      final session = ref.read(sessionProvider);
      if (session.chatHistory.isNotEmpty &&
          session.chatHistory.last.author == MessageAuthor.ai) {
        final language = ref
            .read(contextCompactionServiceProvider)
            .context
            .detectedLanguage;
        await ref
            .read(voiceServiceProvider.notifier)
            .speakAiMessage(session.chatHistory.last.text, language: language);
      }
    } else if (voice.enabled && !updated.enabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voice reading disabled.')));
    }
  }

  void _openRescueSummary() {
    final session = ref.read(sessionProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionSummaryScreen(
          history: session.chatHistory,
          situationSummary: session.situationSummary,
          isPracticeMode: session.isPracticeMode,
          currentNodeId: session.currentNode?.id,
          locationHistory: session.locationHistory,
        ),
      ),
    );
  }

  String _formatPhaseTitle(String id) {
    return id
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final String phaseTitle =
        session.currentNode == null || session.currentNode?.id == 'start'
        ? 'Conversation'
        : _formatPhaseTitle(session.currentNode!.id);

    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        centerTitle: false,
        title: Row(
          children: [
            ScaleTransition(
              scale: _breathAnimation,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brandAi.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brandAi.withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandAi.withOpacity(0.12),
                      blurRadius: 12,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppColors.brandAi,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIDEM | ${session.isPracticeMode ? 'Practice' : 'Emergency'}',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.brandAi,
                    fontSize: 12,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phaseTitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
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
                  statusText = 'AI ready';
                  break;
                case LlmStatus.loading:
                  statusColor = AppColors.warning;
                  statusText = 'Loading';
                  break;
                case LlmStatus.mock:
                  statusColor = AppColors.warning;
                  statusText = 'Mock';
                  break;
                case LlmStatus.error:
                  statusColor = AppColors.accentRed;
                  statusText = 'AI error';
                  break;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (llmState.errorMessage != null &&
                          (llmState.status == LlmStatus.mock ||
                              llmState.status == LlmStatus.error)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'AI Error Details: ${llmState.errorMessage}',
                            ),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                    },
                    child: StatusPill(
                      icon: Icons.memory_rounded,
                      label: statusText,
                      color: statusColor,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.language_rounded,
              size: 20,
              color: AppColors.accentBlue,
            ),
            tooltip: 'Change Language',
            onPressed: _showLanguageDialog,
          ),
          Consumer(
            builder: (context, ref, child) {
              final voice = ref.watch(voiceServiceProvider);
              final color = voice.enabled
                  ? AppColors.brandAi
                  : voice.available
                  ? AppColors.textSecondary
                  : AppColors.textMuted;

              return IconButton(
                icon: Icon(
                  voice.isSpeaking
                      ? Icons.record_voice_over_rounded
                      : voice.enabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_outlined,
                  size: 20,
                  color: color,
                ),
                tooltip: !voice.available
                    ? 'Voice reading unavailable here'
                    : voice.enabled
                    ? 'Disable voice reading'
                    : 'Enable voice reading',
                onPressed: voice.isInitializing || !voice.available
                    ? null
                    : _toggleVoiceReading,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: 'Rescue Summary',
            onPressed: session.chatHistory.isEmpty ? null : _openRescueSummary,
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
              icon: const Icon(
                Icons.my_location,
                size: 20,
                color: AppColors.accentBlue,
              ),
              tooltip: 'Share My Location',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _togglePathTracking,
              icon: Icon(
                _isTrackingPath ? Icons.route_rounded : Icons.route_outlined,
                size: 20,
                color: _isTrackingPath
                    ? AppColors.brandAi
                    : AppColors.textSecondary,
              ),
              tooltip: _isTrackingPath
                  ? 'Stop path recording'
                  : 'Start path recording',
            ),
          ),
        ],
      ),
      body: AidemBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1040;
            if (wide) {
              return _buildDesktopSessionBody(session, phaseTitle);
            }

            return Column(
              children: [
                const Divider(color: AppColors.border, height: 1),

                _buildSafetyStrip(
                  rescueReady: session.chatHistory.length > 1,
                  isPracticeMode: session.isPracticeMode,
                ),

                // Situation context chip (shows what Gemma knows)
                if (session.situationSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: TacticalContainer(
                      showGlow: false,
                      borderRadius: AppColors.radius,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sensors_rounded,
                            color: AppColors.brandAi,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Context',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.brandAi,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              session.situationSummary,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Initial Language Selector
                if (session.chatHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: TacticalContainer(
                      animatePulse: true,
                      showGlow: false,
                      accentColor: AppColors.accentBlue,
                      child: Column(
                        children: [
                          Text(
                            'Choose Language',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Select your language before the first response.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showLanguageDialog,
                              icon: const Icon(Icons.translate, size: 18),
                              label: const Text('Choose language'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
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
                          border: Border.all(
                            color: AppColors.accentBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          session.streamingBuffer,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.5,
                          ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                                final opacity =
                                    ((_typingDotController.value * 3 - i) % 1.0)
                                        .clamp(0.2, 1.0);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
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

                // Image Preview Area
                if (_pendingImagePath != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentBlue.withOpacity(0.3),
                      ),
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
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.accentRed,
                              size: 20,
                            ),
                            onPressed: _clearPendingImage,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick Replies (Yes/No)
                if (session.chatHistory.isNotEmpty &&
                    session.chatHistory.last.author == MessageAuthor.ai &&
                    isBinaryYesNoQuestion(session.chatHistory.last.text) &&
                    !session.isLlmTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ActionChip(
                          label: Text(
                            'Yes',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.brandAi,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0,
                            ),
                          ),
                          backgroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          side: BorderSide(
                            color: AppColors.brandAi.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onPressed: _isSending
                              ? null
                              : () {
                                  _textController.text = 'Yes';
                                  _sendMessage();
                                },
                        ),
                        const SizedBox(width: 12),
                        ActionChip(
                          label: Text(
                            'No',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0,
                            ),
                          ),
                          backgroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onPressed: _isSending
                              ? null
                              : () {
                                  _textController.text = 'No';
                                  _sendMessage();
                                },
                        ),
                      ],
                    ),
                  ),

                // Free-form Gemma input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: session.isLlmTyping
                            ? AppColors.brandAi.withOpacity(0.45)
                            : AppColors.border,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandAi.withOpacity(
                            session.isLlmTyping ? 0.12 : 0.04,
                          ),
                          blurRadius: 18,
                          spreadRadius: -10,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('chat_input'),
                            controller: _textController,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: session.isLlmTyping
                                  ? 'Gemma is responding...'
                                  : 'Describe your situation in detail...',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            textInputAction: TextInputAction.send,
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          tooltip: 'Take photo',
                          onPressed: session.isLlmTyping
                              ? null
                              : () => _pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.image_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          tooltip: 'Attach image',
                          onPressed: session.isLlmTyping
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final speechState = ref.watch(
                              speechServiceProvider,
                            );
                            final voskState = ref.watch(voskSpeechProvider);
                            final isListening =
                                speechState.isListening ||
                                voskState.isListening;
                            final isPreparing = voskState.isPreparing;

                            return IconButton(
                              icon: Icon(
                                isPreparing
                                    ? Icons.hourglass_top_rounded
                                    : isListening
                                    ? Icons.graphic_eq_rounded
                                    : Icons.mic,
                                color: isListening
                                    ? AppColors.accentRed
                                    : AppColors.textSecondary,
                              ),
                              tooltip: isPreparing
                                  ? 'Preparing offline voice input'
                                  : isListening
                                  ? 'Stop dictation'
                                  : 'Dictate',
                              onPressed: session.isLlmTyping || isPreparing
                                  ? null
                                  : _toggleDictation,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Material(
                            color: _isSending || session.isLlmTyping
                                ? AppColors.border
                                : AppColors.brandAi,
                            borderRadius: BorderRadius.circular(
                              AppColors.radius,
                            ),
                            child: InkWell(
                              key: const ValueKey('send_button'),
                              borderRadius: BorderRadius.circular(
                                AppColors.radius,
                              ),
                              onTap: (_isSending || session.isLlmTyping)
                                  ? null
                                  : _sendMessage,
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
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopSessionBody(SessionState session, String phaseTitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: _desktopToolsExpanded ? 320 : 64,
            child: _desktopToolsExpanded
                ? _buildDesktopSidePanel(session, phaseTitle)
                : _buildCollapsedDesktopRail(session),
          ),
          SizedBox(width: _desktopToolsExpanded ? 16 : 12),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: _buildDesktopChatPanel(session),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedDesktopRail(SessionState session) {
    return TacticalContainer(
      showGlow: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          _DesktopRailButton(
            icon: Icons.tune_rounded,
            tooltip: 'Open session tools',
            color: AppColors.brandAi,
            onTap: () => setState(() => _desktopToolsExpanded = true),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSoft, height: 1),
          const SizedBox(height: 12),
          _DesktopRailButton(
            icon: Icons.translate_rounded,
            tooltip: 'Language',
            color: AppColors.accentBlue,
            onTap: _showLanguageDialog,
          ),
          const SizedBox(height: 8),
          _DesktopRailButton(
            icon: Icons.my_location_rounded,
            tooltip: 'Share location',
            color: AppColors.accentBlue,
            onTap: _shareLocation,
          ),
          const SizedBox(height: 8),
          _DesktopRailButton(
            icon: _isTrackingPath ? Icons.route_rounded : Icons.route_outlined,
            tooltip: _isTrackingPath
                ? 'Stop path recording'
                : 'Start path recording',
            color: _isTrackingPath ? AppColors.brandAi : AppColors.textMuted,
            onTap: _togglePathTracking,
          ),
          const SizedBox(height: 8),
          _DesktopRailButton(
            icon: Icons.assignment_turned_in_outlined,
            tooltip: 'Rescue summary',
            color: AppColors.brandAi,
            onTap: session.chatHistory.isEmpty ? null : _openRescueSummary,
          ),
          const Spacer(),
          Tooltip(
            message: session.chatHistory.length > 1
                ? 'Summary ready'
                : 'Building summary',
            child: Icon(
              session.chatHistory.length > 1
                  ? Icons.assignment_turned_in_outlined
                  : Icons.assignment_outlined,
              color: session.chatHistory.length > 1
                  ? AppColors.brandAi
                  : AppColors.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidePanel(SessionState session, String phaseTitle) {
    final lastLocation = session.locationHistory.isEmpty
        ? null
        : session.locationHistory.last.toDms();

    return SingleChildScrollView(
      child: Column(
        children: [
          TacticalContainer(
            showGlow: false,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        phaseTitle,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Collapse tools',
                      onPressed: () =>
                          setState(() => _desktopToolsExpanded = false),
                      icon: const Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  session.isPracticeMode
                      ? 'Practice session'
                      : 'Emergency session',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const StatusPill(
                      icon: Icons.fact_check_outlined,
                      label: 'Protocol',
                      color: AppColors.brandAi,
                    ),
                    StatusPill(
                      icon: session.chatHistory.length > 1
                          ? Icons.assignment_turned_in_outlined
                          : Icons.assignment_outlined,
                      label: session.chatHistory.length > 1
                          ? 'Summary ready'
                          : 'Building',
                      color: session.chatHistory.length > 1
                          ? AppColors.brandAi
                          : AppColors.textMuted,
                    ),
                    if (_isTrackingPath)
                      const StatusPill(
                        icon: Icons.route_rounded,
                        label: 'Path on',
                        color: AppColors.accentBlue,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TacticalContainer(
            showGlow: false,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(label: 'Situation'),
                const SizedBox(height: 12),
                _DesktopInfoRow(
                  icon: Icons.subject_rounded,
                  label: 'Summary',
                  value: session.situationSummary.isEmpty
                      ? 'No summary yet'
                      : session.situationSummary,
                  color: AppColors.brandAi,
                ),
                const SizedBox(height: 12),
                _DesktopInfoRow(
                  icon: Icons.my_location_outlined,
                  label: 'Last location',
                  value: lastLocation ?? 'Not shared',
                  color: AppColors.accentBlue,
                ),
                const SizedBox(height: 12),
                _DesktopInfoRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Timeline',
                  value: '${session.chatHistory.length} entries',
                  color: AppColors.accentOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TacticalContainer(
            showGlow: false,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(label: 'Tools'),
                const SizedBox(height: 12),
                _DesktopToolButton(
                  icon: Icons.translate_rounded,
                  label: 'Language',
                  color: AppColors.accentBlue,
                  onTap: _showLanguageDialog,
                ),
                const SizedBox(height: 8),
                _DesktopToolButton(
                  icon: Icons.my_location_rounded,
                  label: 'Share location',
                  color: AppColors.accentBlue,
                  onTap: _shareLocation,
                ),
                const SizedBox(height: 8),
                _DesktopToolButton(
                  icon: _isTrackingPath
                      ? Icons.route_rounded
                      : Icons.route_outlined,
                  label: _isTrackingPath ? 'Stop path' : 'Record path',
                  color: _isTrackingPath
                      ? AppColors.brandAi
                      : AppColors.textSecondary,
                  onTap: _togglePathTracking,
                ),
                const SizedBox(height: 8),
                _DesktopToolButton(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Rescue summary',
                  color: AppColors.brandAi,
                  onTap: session.chatHistory.isEmpty
                      ? null
                      : _openRescueSummary,
                ),
                const SizedBox(height: 8),
                _DesktopToolButton(
                  icon: Icons.download_rounded,
                  label: 'Export chat',
                  color: AppColors.textSecondary,
                  onTap: _exportChat,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Call emergency services first whenever reachable.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopChatPanel(SessionState session) {
    return TacticalContainer(
      padding: EdgeInsets.zero,
      showGlow: false,
      borderRadius: AppColors.radiusLarge,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Text(
                  'Conversation',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                StatusPill(
                  icon: session.chatHistory.length > 1
                      ? Icons.assignment_turned_in_outlined
                      : Icons.assignment_outlined,
                  label: session.chatHistory.length > 1
                      ? 'Summary ready'
                      : 'Building summary',
                  color: session.chatHistory.length > 1
                      ? AppColors.brandAi
                      : AppColors.textMuted,
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          if (session.chatHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _buildLanguagePrompt(compact: true),
            ),
          Expanded(
            child: ChatListView(
              messages: session.chatHistory,
              scrollController: _scrollController,
            ),
          ),
          _buildStreamingFeedback(session),
          _buildPendingImagePreview(),
          _buildQuickReplies(session),
          _buildComposer(session, desktop: true),
        ],
      ),
    );
  }

  Widget _buildLanguagePrompt({required bool compact}) {
    return TacticalContainer(
      animatePulse: true,
      showGlow: false,
      accentColor: AppColors.accentBlue,
      padding: EdgeInsets.all(compact ? 16 : 18),
      child: Column(
        children: [
          Text(
            'Choose Language',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select your language before the first response.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showLanguageDialog,
              icon: const Icon(Icons.translate, size: 18),
              label: const Text('Choose language'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingFeedback(SessionState session) {
    if (session.isLlmTyping && session.streamingBuffer.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
            ),
            child: Text(
              session.streamingBuffer,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    if (session.isLlmTyping) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
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
                    final opacity = ((_typingDotController.value * 3 - i) % 1.0)
                        .clamp(0.2, 1.0);
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
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPendingImagePreview() {
    if (_pendingImagePath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
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
              height: 92,
              width: 92,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: const Icon(
                Icons.cancel,
                color: AppColors.accentRed,
                size: 20,
              ),
              onPressed: _clearPendingImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(SessionState session) {
    if (session.chatHistory.isEmpty ||
        session.chatHistory.last.author != MessageAuthor.ai ||
        !isBinaryYesNoQuestion(session.chatHistory.last.text) ||
        session.isLlmTyping) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ActionChip(
            label: Text(
              'Yes',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.brandAi,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: BorderSide(color: AppColors.brandAi.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: _isSending
                ? null
                : () {
                    _textController.text = 'Yes';
                    _sendMessage();
                  },
          ),
          const SizedBox(width: 12),
          ActionChip(
            label: Text(
              'No',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: _isSending
                ? null
                : () {
                    _textController.text = 'No';
                    _sendMessage();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(SessionState session, {required bool desktop}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, desktop ? 10 : 8, 16, desktop ? 16 : 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: session.isLlmTyping
                ? AppColors.brandAi.withValues(alpha: 0.46)
                : AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandAi.withValues(
                alpha: session.isLlmTyping ? 0.12 : 0.04,
              ),
              blurRadius: 26,
              spreadRadius: -18,
              offset: const Offset(0, 18),
            ),
          ],
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
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                maxLines: null,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              tooltip: 'Take photo',
              onPressed: session.isLlmTyping
                  ? null
                  : () => _pickImage(ImageSource.camera),
            ),
            IconButton(
              icon: const Icon(
                Icons.image_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              tooltip: 'Attach image',
              onPressed: session.isLlmTyping
                  ? null
                  : () => _pickImage(ImageSource.gallery),
            ),
            Consumer(
              builder: (context, ref, _) {
                final speechState = ref.watch(speechServiceProvider);
                final voskState = ref.watch(voskSpeechProvider);
                final isListening =
                    speechState.isListening || voskState.isListening;
                final isPreparing = voskState.isPreparing;

                return IconButton(
                  icon: Icon(
                    isPreparing
                        ? Icons.hourglass_top_rounded
                        : isListening
                        ? Icons.graphic_eq_rounded
                        : Icons.mic,
                    color: isListening
                        ? AppColors.accentRed
                        : AppColors.textSecondary,
                  ),
                  tooltip: isPreparing
                      ? 'Preparing offline voice input'
                      : isListening
                      ? 'Stop dictation'
                      : 'Dictate',
                  onPressed: session.isLlmTyping || isPreparing
                      ? null
                      : _toggleDictation,
                );
              },
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: _isSending || session.isLlmTyping
                    ? AppColors.border
                    : AppColors.brandAi,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const ValueKey('send_button'),
                  customBorder: const CircleBorder(),
                  onTap: (_isSending || session.isLlmTyping)
                      ? null
                      : _sendMessage,
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
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyStrip({
    required bool rescueReady,
    required bool isPracticeMode,
    bool compact = false,
  }) {
    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const StatusPill(
              icon: Icons.fact_check_outlined,
              label: 'Protocol-based',
              color: AppColors.brandAi,
            ),
            const SizedBox(width: 8),
            const StatusPill(
              icon: Icons.call_outlined,
              label: 'Call services first',
              color: AppColors.accentOrange,
            ),
            const SizedBox(width: 8),
            const StatusPill(
              icon: Icons.lock_outline_rounded,
              label: 'Local data',
              color: AppColors.accentBlue,
            ),
            const SizedBox(width: 8),
            StatusPill(
              icon: rescueReady
                  ? Icons.assignment_turned_in_outlined
                  : Icons.assignment_outlined,
              label: rescueReady ? 'Summary ready' : 'Building summary',
              color: rescueReady ? AppColors.brandAi : AppColors.textMuted,
            ),
            if (isPracticeMode) ...[
              const SizedBox(width: 8),
              const StatusPill(
                icon: Icons.school_outlined,
                label: 'Practice/demo',
                color: AppColors.accentBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DesktopInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopRailButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _DesktopRailButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radius),
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppColors.radius),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _DesktopToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DesktopToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radius),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppColors.radius),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
