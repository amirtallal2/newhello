import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/chat_repository.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key});

  static const Color primaryBlue = Color(0xFF285F98);
  static const Color headerBackground = Color(0xFFF6F6F6);
  static const Color lineColor = Color(0xFFA6A6AA);
  static const Color dateChip = Color(0xFFDDDDE9);
  static const Color inputBorder = Color(0xFF8E8E93);
  static const Color mutedDark = Color(0x40000000);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  ChatConversationPayload? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isPickingImage = false;
  String? _error;
  int? _threadId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final incomingThreadId = ModalRoute.of(context)?.settings.arguments as int?;
    if (_threadId == incomingThreadId && _conversation != null) {
      return;
    }
    _threadId = incomingThreadId;
    _loadConversation();
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payload = await ChatRepository.instance.loadConversation(
        threadId: _threadId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _conversation = payload;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage({
    String? bodyText,
    String messageType = 'text',
    ChatAttachmentDraft? attachment,
  }) async {
    final conversation = _conversation;
    final normalizedBody = (bodyText ?? _composerController.text).trim();
    final canSend =
        normalizedBody.isNotEmpty ||
        attachment != null ||
        messageType == 'gift' ||
        messageType == 'voice';
    if (conversation == null || !canSend || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final payload = await ChatRepository.instance.sendMessage(
        threadId: conversation.thread.id,
        bodyText: normalizedBody,
        messageType: messageType,
        attachment: attachment,
      );
      if (!mounted) {
        return;
      }
      _composerController.clear();
      setState(() {
        _conversation = payload;
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _sendImageMessage() async {
    if (_isSending || _isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
      );
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      await _sendMessage(
        bodyText: 'صورة',
        messageType: 'image',
        attachment: ChatAttachmentDraft(
          fileName: file.name,
          mimeType: _inferMimeType(file.name),
          bytes: bytes,
        ),
      );
    } on PlatformException catch (error) {
      if (error.code != 'already_active' && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      } else {
        _isPickingImage = false;
      }
    }
  }

  Future<void> _sendGiftMessage(ChatGiftItemData gift, int quantity) async {
    final conversation = _conversation;
    if (conversation == null || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final payload = await ChatRepository.instance.sendGiftMessage(
        threadId: conversation.thread.id,
        giftId: gift.id,
        quantity: quantity,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _conversation = payload;
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _sendVoiceAttachment(String filePath, Duration duration) async {
    if (_isSending) {
      return;
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();
    await _sendMessage(
      bodyText: 'رسالة صوتية ${_formatDuration(duration)}',
      messageType: 'voice',
      attachment: ChatAttachmentDraft(
        fileName: file.uri.pathSegments.isEmpty
            ? 'voice-message.m4a'
            : file.uri.pathSegments.last,
        mimeType: 'audio/mp4',
        bytes: bytes,
      ),
    );
  }

  void _showGiftSheet() {
    final conversation = _conversation;
    if (conversation == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return _ChatGiftSheet(
          isSending: _isSending,
          onSendGift: (gift, quantity) async {
            Navigator.of(context).pop();
            await _sendGiftMessage(gift, quantity);
          },
        );
      },
    );
  }

  void _showVoiceRecorderSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: !_isSending,
      enableDrag: !_isSending,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return _VoiceRecorderSheet(
          onSendVoice: (path, duration) async {
            Navigator.of(context).pop();
            await _sendVoiceAttachment(path, duration);
          },
        );
      },
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetActionTile(
                    icon: Icons.photo_library_rounded,
                    title: 'إرسال صورة',
                    subtitle: 'اختيار صورة من المعرض وإرسالها كرسالة حقيقية',
                    onTap: () {
                      Navigator.of(context).pop();
                      _sendImageMessage();
                    },
                  ),
                  _SheetActionTile(
                    icon: Icons.card_giftcard_rounded,
                    title: 'إرسال هدية',
                    subtitle: 'إرسال هدية تظهر داخل المحادثة',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showGiftSheet();
                    },
                  ),
                  _SheetActionTile(
                    icon: Icons.mic_rounded,
                    title: 'رسالة صوتية',
                    subtitle: 'تسجيل ملف صوتي فعلي ورفعه للمحادثة',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showVoiceRecorderSheet();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyConversationInfo() async {
    final thread = _conversation?.thread;
    if (thread == null) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: '${thread.title} - Chat #${thread.id}'),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ بيانات المحادثة.')));
  }

  void _showConversationActions() {
    final thread = _conversation?.thread;
    if (thread == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((thread.targetUserId ?? 0) > 0)
                    _SheetActionTile(
                      icon: Icons.person_rounded,
                      title: 'فتح الملف الشخصي',
                      subtitle: thread.title,
                      onTap: () {
                        Navigator.of(context).pop();
                        _openThreadProfile();
                      },
                    ),
                  _SheetActionTile(
                    icon: Icons.done_all_rounded,
                    title: 'تحديد كمقروء',
                    subtitle: 'تصفير عداد غير المقروء لهذه المحادثة',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ChatRepository.instance.bulkAction(
                        threadIds: [thread.id],
                        action: 'mark_read',
                      );
                      await _loadConversation();
                    },
                  ),
                  _SheetActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'حذف المحادثة',
                    subtitle: 'إخفاء المحادثة من صندوق الرسائل الخاص بك',
                    isDanger: true,
                    onTap: () async {
                      final rootNavigator = Navigator.of(this.context);
                      Navigator.of(context).pop();
                      await ChatRepository.instance.bulkAction(
                        threadIds: [thread.id],
                        action: 'delete',
                      );
                      if (!mounted) {
                        return;
                      }
                      rootNavigator.pushReplacementNamed(
                        AppRoutes.chatMessages,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  void _openThreadProfile() {
    final thread = _conversation?.thread;
    final userId = thread?.targetUserId;
    if (thread == null || userId == null || userId < 1) {
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: userId,
        fallbackName: thread.title,
        fallbackAvatarAsset: thread.avatarAsset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _ConversationHeader(
              title: conversation?.thread.title ?? 'احمد محمد',
              avatarAsset: conversation?.thread.avatarAsset,
              canOpenProfile: (conversation?.thread.targetUserId ?? 0) > 0,
              onProfileTap: _openThreadProfile,
              onActionsTap: _showConversationActions,
              onCopyTap: _copyConversationInfo,
              onBackTap: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                  return;
                }

                navigator.pushReplacementNamed(AppRoutes.chatMessages);
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _ConversationCanvas(
                      messages: conversation?.messages ?? const [],
                      onRefresh: _loadConversation,
                    ),
            ),
            _MessageComposer(
              controller: _composerController,
              isSending: _isSending || _isPickingImage,
              onSendTap: () => _sendMessage(),
              onAddTap: _showAttachmentSheet,
              onGiftTap: _showGiftSheet,
              onGalleryTap: _sendImageMessage,
              onMicTap: _showVoiceRecorderSheet,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ConversationCanvas extends StatelessWidget {
  const _ConversationCanvas({required this.messages, required this.onRefresh});

  final List<ChatConversationMessageData> messages;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/chat_conversation_background.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
        ),
      ),
      child: RefreshIndicator(
        color: ChatConversationScreen.primaryBlue,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(7, 20, 8, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.topCenter,
                child: _AnnouncementBanner(),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.center,
                child: _DateChip(label: 'Fri, Jul 26'),
              ),
              const SizedBox(height: 18),
              ...messages.map((message) {
                final isOutgoing = message.direction == 'outgoing';
                if (isOutgoing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _OutgoingBubble(
                        message: message.bodyText,
                        messageType: message.messageType,
                        attachmentPath: message.attachmentPath,
                        time: message.timeLabel,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _IncomingBubble(
                      message: message.bodyText,
                      messageType: message.messageType,
                      attachmentPath: message.attachmentPath,
                      time: message.timeLabel,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? const Color(0xFFB45A5A)
        : ChatConversationScreen.primaryBlue;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF6F7C8F),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ChatGiftSheet extends StatefulWidget {
  const _ChatGiftSheet({required this.isSending, required this.onSendGift});

  final bool isSending;
  final Future<void> Function(ChatGiftItemData gift, int quantity) onSendGift;

  @override
  State<_ChatGiftSheet> createState() => _ChatGiftSheetState();
}

class _ChatGiftSheetState extends State<_ChatGiftSheet> {
  late final Future<ChatGiftPanelData> _panelFuture;
  int? _selectedGiftId;
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _panelFuture = ChatRepository.instance.loadGiftPanel();
  }

  Future<void> _send(ChatGiftItemData gift) async {
    if (_isSubmitting || widget.isSending) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await widget.onSendGift(gift, _quantity);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          child: FutureBuilder<ChatGiftPanelData>(
            future: _panelFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final panel = snapshot.data;
              final gifts = panel?.gifts ?? const <ChatGiftItemData>[];
              final selectedGift = gifts.isEmpty
                  ? null
                  : gifts.firstWhere(
                      (gift) => gift.id == _selectedGiftId,
                      orElse: () => gifts.first,
                    );

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'إرسال هدية',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: ChatConversationScreen.primaryBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${panel?.coinsBalance ?? 0} Coin',
                          style: const TextStyle(
                            color: ChatConversationScreen.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (gifts.isEmpty)
                    const SizedBox(
                      height: 180,
                      child: Center(child: Text('لا توجد هدايا متاحة الآن.')),
                    )
                  else
                    SizedBox(
                      height: 270,
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: gifts.length,
                        itemBuilder: (context, index) {
                          final gift = gifts[index];
                          final isSelected =
                              gift.id == (selectedGift?.id ?? _selectedGiftId);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedGiftId = gift.id;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFDCEEFF)
                                    : const Color(0xFFF4F7FB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? ChatConversationScreen.primaryBlue
                                      : const Color(0xFFE0E7EF),
                                  width: isSelected ? 1.3 : 0.7,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ResolvedImage(
                                      path: gift.assetPath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    gift.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: ChatConversationScreen.primaryBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${gift.priceCoins}',
                                    style: const TextStyle(
                                      color: Color(0xFF6F7C8F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <int>[1, 5, 10, 99]
                        .map(
                          (value) => ChoiceChip(
                            label: Text('x$value'),
                            selected: _quantity == value,
                            onSelected: (_) {
                              setState(() {
                                _quantity = value;
                              });
                            },
                            selectedColor: ChatConversationScreen.primaryBlue,
                            labelStyle: TextStyle(
                              color: _quantity == value
                                  ? Colors.white
                                  : ChatConversationScreen.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: selectedGift == null || _isSubmitting
                        ? null
                        : () => _send(selectedGift),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatConversationScreen.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isSubmitting
                          ? 'جاري الإرسال...'
                          : selectedGift == null
                          ? 'اختر هدية'
                          : 'إرسال ${selectedGift.name} x$_quantity',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VoiceRecorderSheet extends StatefulWidget {
  const _VoiceRecorderSheet({required this.onSendVoice});

  final Future<void> Function(String filePath, Duration duration) onSendVoice;

  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isRecording = false;
  bool _isStarting = true;
  bool _isSending = false;
  String? _recordPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      _recorder.cancel();
    }
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isStarting = false;
          _error = 'يجب السماح بالمايك لإرسال رسالة صوتية.';
        });
        return;
      }

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
          noiseSuppress: true,
        ),
        path: path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _recordPath = path;
        _isRecording = true;
        _isStarting = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsed += const Duration(seconds: 1);
          });
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isStarting = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _stopAndSend() async {
    if (_isSending || _isStarting) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      _timer?.cancel();
      final stoppedPath = _isRecording ? await _recorder.stop() : _recordPath;
      _isRecording = false;
      final path = stoppedPath ?? _recordPath;
      if (path == null || !File(path).existsSync()) {
        throw Exception('لم يتم إنشاء ملف صوتي صالح.');
      }

      final fileSize = await File(path).length();
      if (fileSize < 512) {
        throw Exception('التسجيل قصير جدًا. سجل ثانية واحدة على الأقل.');
      }

      await widget.onSendVoice(path, _elapsed);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    if (_isRecording) {
      await _recorder.cancel();
      _isRecording = false;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _durationLabel(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'رسالة صوتية',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: ChatConversationScreen.primaryBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Icon(
                      _error == null
                          ? Icons.mic_rounded
                          : Icons.error_outline_rounded,
                      color: ChatConversationScreen.primaryBlue,
                      size: 42,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error ??
                          (_isStarting
                              ? 'جاري تشغيل المايك...'
                              : _isRecording
                              ? 'جاري التسجيل الآن'
                              : 'التسجيل جاهز للإرسال'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ChatConversationScreen.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _durationLabel(_elapsed),
                      style: const TextStyle(
                        color: Color(0xFF172B3A),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSending ? null : _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ChatConversationScreen.primaryBlue,
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(
                          color: ChatConversationScreen.primaryBlue,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _error != null || _isStarting || _isSending
                          ? null
                          : _stopAndSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChatConversationScreen.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSending ? 'جاري الرفع...' : 'إيقاف وإرسال',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({
    required this.title,
    required this.avatarAsset,
    required this.canOpenProfile,
    required this.onProfileTap,
    required this.onActionsTap,
    required this.onCopyTap,
    required this.onBackTap,
  });

  final String title;
  final String? avatarAsset;
  final bool canOpenProfile;
  final VoidCallback onProfileTap;
  final VoidCallback onActionsTap;
  final VoidCallback onCopyTap;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: ChatConversationScreen.headerBackground,
        boxShadow: [
          BoxShadow(
            color: ChatConversationScreen.lineColor,
            blurRadius: 0,
            offset: Offset(0, 0.33),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(21, 16, 15, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeaderIconButton(
            semanticLabel: 'chat-conversation-actions',
            assetPath: 'assets/images/chat_unavailable_icon.png',
            onTap: onActionsTap,
          ),
          const SizedBox(width: 25),
          _HeaderIconButton(
            semanticLabel: 'chat-conversation-copy',
            assetPath: 'assets/images/chat_clipboard_icon.png',
            onTap: onCopyTap,
          ),
          const Spacer(),
          _HeaderIdentity(
            title: title,
            canOpenProfile: canOpenProfile,
            onTap: onProfileTap,
          ),
          const SizedBox(width: 10),
          _HeaderAvatar(
            avatarAsset: avatarAsset,
            canOpenProfile: canOpenProfile,
            onTap: onProfileTap,
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: onBackTap,
            child: const Icon(
              Icons.chevron_right_rounded,
              color: ChatConversationScreen.primaryBlue,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.semanticLabel,
    required this.assetPath,
    required this.onTap,
  });

  final String semanticLabel;
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              assetPath,
              width: 30,
              height: 30,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIdentity extends StatelessWidget {
  const _HeaderIdentity({
    required this.title,
    required this.canOpenProfile,
    required this.onTap,
  });

  final String title;
  final bool canOpenProfile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canOpenProfile ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اونلاين',
                style: TextStyle(
                  color: Color(0xFF34A853),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF34A853),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 8, height: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.avatarAsset,
    required this.canOpenProfile,
    required this.onTap,
  });

  final String? avatarAsset;
  final bool canOpenProfile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canOpenProfile ? onTap : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF9CC4F0), Color(0xFF285F98)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: avatarAsset != null && avatarAsset!.trim().isNotEmpty
            ? ResolvedImage(path: avatarAsset!, fit: BoxFit.cover)
            : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 279,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Row(
        children: [
          Image.asset(
            'assets/images/chat_warning_icon.png',
            width: 21,
            height: 21,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'الرجاء الالتزام بالقوانين والحفاظ علي الالفاظ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 21,
      decoration: BoxDecoration(
        color: ChatConversationScreen.dateChip,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33989898),
            blurRadius: 0,
            offset: Offset(0, 0.4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3C3C43),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OutgoingBubble extends StatelessWidget {
  const _OutgoingBubble({
    required this.message,
    required this.messageType,
    required this.attachmentPath,
    required this.time,
  });

  final String message;
  final String messageType;
  final String? attachmentPath;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 262),
      decoration: BoxDecoration(
        color: ChatConversationScreen.primaryBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _MessageBubbleContent(
              message: message,
              messageType: messageType,
              attachmentPath: attachmentPath,
              isOutgoing: true,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              color: Color(0x80FFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.done_all_rounded, size: 14, color: Colors.white),
        ],
      ),
    );
  }
}

class _IncomingBubble extends StatelessWidget {
  const _IncomingBubble({
    required this.message,
    required this.messageType,
    required this.attachmentPath,
    required this.time,
  });

  final String message;
  final String messageType;
  final String? attachmentPath;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 262),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: ChatConversationScreen.mutedDark,
            blurRadius: 1.5,
            offset: Offset(1, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MessageBubbleContent(
            message: message,
            messageType: messageType,
            attachmentPath: attachmentPath,
            isOutgoing: false,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0x40000000),
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubbleContent extends StatelessWidget {
  const _MessageBubbleContent({
    required this.message,
    required this.messageType,
    required this.attachmentPath,
    required this.isOutgoing,
  });

  final String message;
  final String messageType;
  final String? attachmentPath;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final textColor = isOutgoing ? Colors.white : Colors.black;
    final type = messageType == 'photo' ? 'image' : messageType;

    if (type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: attachmentPath != null && attachmentPath!.trim().isNotEmpty
                ? () => _openImagePreview(context, attachmentPath!.trim())
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 210,
                height: 160,
                child:
                    attachmentPath != null && attachmentPath!.trim().isNotEmpty
                    ? ResolvedImage(path: attachmentPath!, fit: BoxFit.cover)
                    : Container(
                        color: isOutgoing
                            ? Colors.white.withValues(alpha: 0.16)
                            : const Color(0xFFEAF2FB),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_rounded,
                          color: textColor,
                          size: 38,
                        ),
                      ),
              ),
            ),
          ),
          if (message.trim().isNotEmpty && message.trim() != 'صورة') ...[
            const SizedBox(height: 8),
            _BubbleText(message: message, color: textColor),
          ],
        ],
      );
    }

    if (type == 'gift') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Flexible(
            child: _BubbleText(message: message, color: textColor),
          ),
        ],
      );
    }

    if (type == 'voice') {
      return _VoiceMessageBubble(
        label: message,
        attachmentPath: attachmentPath,
        color: textColor,
      );
    }

    return _BubbleText(message: message, color: textColor);
  }

  void _openImagePreview(BuildContext context, String path) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _ChatImagePreview(path: path),
          );
        },
      ),
    );
  }
}

class _ChatImagePreview extends StatelessWidget {
  const _ChatImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.75,
                maxScale: 4,
                child: Center(
                  child: ResolvedImage(path: path, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceMessageBubble extends StatefulWidget {
  const _VoiceMessageBubble({
    required this.label,
    required this.attachmentPath,
    required this.color,
  });

  final String label;
  final String? attachmentPath;
  final Color color;

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final path = widget.attachmentPath?.trim() ?? '';
    if (path.isEmpty) {
      return;
    }

    if (_isPlaying) {
      await _player.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      return;
    }

    await _player.play(UrlSource(resolveMediaUrl(path), mimeType: 'audio/mp4'));
    if (mounted) {
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = (widget.attachmentPath ?? '').trim().isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 214),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          InkWell(
            onTap: canPlay ? _togglePlayback : null,
            customBorder: const CircleBorder(),
            child: Icon(
              _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: widget.color.withValues(alpha: canPlay ? 1 : 0.45),
              size: 24,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(minWidth: 46, maxWidth: 92),
              height: 4,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label.isEmpty ? 'رسالة صوتية' : widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: widget.color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleText extends StatelessWidget {
  const _BubbleText({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        message,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSendTap,
    required this.onAddTap,
    required this.onGiftTap,
    required this.onGalleryTap,
    required this.onMicTap,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSendTap;
  final VoidCallback onAddTap;
  final VoidCallback onGiftTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: ChatConversationScreen.headerBackground,
        boxShadow: [
          BoxShadow(
            color: ChatConversationScreen.lineColor,
            blurRadius: 0,
            offset: Offset(0, -0.33),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          _ComposerIconButton(
            semanticLabel: 'chat-composer-add',
            assetPath: 'assets/images/chat_add_icon.png',
            size: 30,
            onTap: isSending ? null : onAddTap,
          ),
          const SizedBox(width: 18),
          _ComposerIconButton(
            semanticLabel: 'chat-composer-gift',
            assetPath: 'assets/images/chat_gift_icon.png',
            size: 30,
            onTap: isSending ? null : onGiftTap,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ChatConversationScreen.inputBorder,
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _ComposerIconButton(
                    semanticLabel: 'chat-composer-gallery',
                    assetPath: 'assets/images/chat_gallery_icon.png',
                    size: 20,
                    padding: 2,
                    onTap: isSending ? null : onGalleryTap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!isSending) {
                          onSendTap();
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xFF172B3A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'اكتب رسالة',
                        hintStyle: TextStyle(
                          color: Color(0x803C3C43),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _TextSendButton(onTap: isSending ? null : onSendTap),
          const SizedBox(width: 8),
          _ComposerIconButton(
            semanticLabel: 'chat-composer-mic',
            assetPath: 'assets/images/chat_mic_icon.png',
            size: 22,
            onTap: isSending ? null : onMicTap,
          ),
        ],
      ),
    );
  }
}

class _TextSendButton extends StatelessWidget {
  const _TextSendButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      label: 'chat-composer-text-send',
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: enabled
                ? ChatConversationScreen.primaryBlue
                : const Color(0xFFB8C7D7),
            shape: BoxShape.circle,
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x33285F98),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.semanticLabel,
    required this.assetPath,
    required this.size,
    required this.onTap,
    this.padding = 4,
  });

  final String semanticLabel;
  final String assetPath;
  final double size;
  final VoidCallback? onTap;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              filterQuality: FilterQuality.high,
              opacity: onTap == null
                  ? const AlwaysStoppedAnimation<double>(0.45)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
