import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';

/// Member 2 (IT23707122): Provider In-App Chat Screen (5th Interface)
/// Requirements & Usability Traceability:
/// - Milestone 01 Appendix A (Homeowner Poornima): "I would add live chat support, real-time booking status..."
/// - Milestone 02 Section g: "Add a Message provider action to the Booking Confirmation screen"
/// - Milestone 02 Variant B: Provider Profile "Message button lets a homeowner ask a question before booking"
/// - Milestone 03 CRUD: CREATE message, READ message history, DELETE/Recall message
class ProviderChatScreen extends StatefulWidget {
  final ServiceProvider provider;
  final Booking? booking;

  const ProviderChatScreen({
    super.key,
    required this.provider,
    this.booking,
  });

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AppStateService _appState = AppStateService();

  final List<String> _quickPrompts = [
    'Where should you park?',
    'Main water shutoff is located under sink',
    'Are replacement parts included in the quote?',
    'Please ring the doorbell upon arrival',
  ];

  Uint8List? _attachedImageBytes;
  String? _attachedImageName;
  bool _pickingImage = false;

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final size = await file.length();
      if (size == null || size <= 0 || size > 5 * 1024 * 1024) {
        throw StateError('Choose a photo smaller than 5 MB.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw StateError('Choose a photo smaller than 5 MB.');
      }
      if (!mounted) return;
      setState(() {
        _attachedImageBytes = bytes;
        _attachedImageName = file.name;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isProviderTyping = false;

  void _sendMessage([String? textToSend]) {
    final text = textToSend ?? _textController.text.trim();
    if (text.isEmpty && _attachedImageBytes == null) return;

    final bookingId = widget.booking?.id ?? 'INQUIRY-${widget.provider.id}';
    final messageText = text.isNotEmpty
        ? text
        : '📷 Attached photo: ${_attachedImageName ?? "issue_photo"}';

    final imageBase64ToSend = _attachedImageBytes != null
        ? base64Encode(_attachedImageBytes!)
        : null;
    final imageNameToSend = _attachedImageName;

    _appState.sendChatMessage(
      bookingId: bookingId,
      providerId: widget.provider.id,
      senderId: 'customer',
      senderName: 'Poornima Madubashini',
      text: messageText,
      imageBase64: imageBase64ToSend,
      imageName: imageNameToSend,
    );

    _textController.clear();
    setState(() {
      _attachedImageBytes = null;
      _attachedImageName = null;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Automated smart response from the service provider
    _triggerAutomatedProviderReply(messageText, bookingId, hasImage: imageBase64ToSend != null);
  }

  void _triggerAutomatedProviderReply(String userMessage, String bookingId, {bool hasImage = false}) {
    setState(() => _isProviderTyping = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 70,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final lower = userMessage.toLowerCase();
    String reply;
    if (hasImage) {
      reply = 'Thank you for sending the photo! I can see the issue clearly. I will make sure to bring the right spare parts and tools.';
    } else if (lower.contains('park') || lower.contains('driveway') || lower.contains('where should you')) {
      reply = 'You can park in the driveway or along the front curb. I will bring all required tools and supplies!';
    } else if (lower.contains('water') || lower.contains('sink') || lower.contains('shutoff') || lower.contains('leak')) {
      reply = 'Got it! Thank you for letting me know. I will inspect the shutoff valve right as I arrive.';
    } else if (lower.contains('part') || lower.contains('quote') || lower.contains('price') || lower.contains('cost')) {
      reply = 'Standard labor is covered under the upfront quote. Any necessary replacement parts will be confirmed with you beforehand.';
    } else if (lower.contains('doorbell') || lower.contains('ring') || lower.contains('arrival')) {
      reply = 'Understood! I will ring the doorbell and present the digital verification pass upon arrival.';
    } else if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      reply = 'Hello! Thank you for booking. I am preparing the equipment and will be there right on schedule.';
    } else if (lower.contains('time') || lower.contains('when') || lower.contains('today')) {
      reply = 'Everything is on schedule for our appointment slot today. See you shortly!';
    } else {
      reply = 'Received your message! I have saved this in my job notes. Looking forward to completing your service.';
    }

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _appState.sendChatMessage(
        bookingId: bookingId,
        providerId: widget.provider.id,
        senderId: widget.provider.id,
        senderName: widget.provider.name,
        text: reply,
      );
      setState(() => _isProviderTyping = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _deleteMessageDialog(ChatMessage message) {
    if (message.senderId != 'customer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own messages.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to recall this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () {
              _appState.deleteChatMessage(message.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Contact Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.provider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Verified ${widget.provider.category.toUpperCase()} Specialist',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.provider.phone,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  const Icon(Icons.phone, size: 20, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('Connecting call to ${widget.provider.phone}...'),
                ),
              );
            },
            icon: const Icon(Icons.call, size: 16, color: Colors.white),
            label: const Text('Call Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.booking?.id ?? 'INQUIRY-${widget.provider.id}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundImage: NetworkImage(widget.provider.imageUrl),
                  backgroundColor: AppColors.surfaceMuted,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.provider.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.provider.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  Text(
                    'Online • ${widget.provider.phone}',
                    style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: AppColors.primary),
            tooltip: 'Call Provider',
            onPressed: _showCallDialog,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          final messages = _appState.getMessagesForBooking(bookingId, providerId: widget.provider.id);

          return Column(
            children: [
              // Linked Booking Context Header (Direct traceability to booking)
              if (widget.booking != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: AppColors.surfaceMuted,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Linked Job: ${widget.booking!.serviceItem}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${widget.booking!.id} • ${widget.booking!.timeSlot}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.booking!.status.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),

              // Chat Message List
              Expanded(
                child: (messages.isEmpty && !_isProviderTyping)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No messages yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Ask ${widget.provider.name} about scope, tools, or arrival.', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: messages.length + (_isProviderTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(widget.provider.imageUrl),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${widget.provider.name} is typing',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final msg = messages[index];
                          final isMe = msg.senderId == 'customer';
                          final bubbleColor = isMe ? AppColors.primary : AppColors.surface;

                          return GestureDetector(
                            onLongPress: () => _deleteMessageDialog(msg),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundImage: NetworkImage(widget.provider.imageUrl),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: bubbleColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                                          bottomRight: Radius.circular(isMe ? 4 : 16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: isMe ? null : Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 3),
                                              child: Text(
                                                msg.senderName,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          if (msg.imageBase64 != null) ...[
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.memory(
                                                base64Decode(msg.imageBase64!),
                                                width: 220,
                                                height: 160,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 200,
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black12,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.image, size: 16),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          msg.imageName ?? 'Image',
                                                          style: const TextStyle(fontSize: 11),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          Text(
                                            msg.text,
                                            style: TextStyle(
                                              color: isMe ? Colors.white : AppColors.textPrimary,
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                                style: TextStyle(
                                                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.done_all, size: 12, color: Colors.white70),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Quick-Reply Smart Suggestion Pills (Customer Prompts)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final prompt = _quickPrompts[idx];
                    return ActionChip(
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onPressed: () => _sendMessage(prompt),
                    );
                  },
                ),
              ),

              // Bottom Input Box (CREATE message)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_attachedImageBytes != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  _attachedImageBytes!,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _attachedImageName ?? 'Photo selected',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'Photo attached — tap send to upload',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _attachedImageBytes = null;
                                    _attachedImageName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Upload photo of issue',
                            icon: _pickingImage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    _attachedImageBytes != null
                                        ? Icons.check_circle
                                        : Icons.camera_alt_outlined,
                                    color: _attachedImageBytes != null
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                            onPressed: _pickingImage ? null : _pickImage,
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _textController,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Ask about scope, tools, or arrival...',
                                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: IconButton(
                              icon: const Icon(Icons.send, size: 18, color: Colors.white),
                              onPressed: () => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
