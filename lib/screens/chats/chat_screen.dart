import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/identity_repository.dart';
import '../../data/messages_repository.dart';
import '../../models/contact.dart';
import '../../services/mesh_router.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/user_avatar.dart';

/// A single conversation. Messages are sent via [MeshRouter] (which floods
/// them across the mesh toward [contact]'s Mesh ID) and read from
/// [MessagesRepository], which [MeshRouter] fills in as messages are sent
/// or arrive. Wrapped in a [ListenableBuilder] so an incoming message shows
/// up here immediately if this screen is already open when it arrives.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contact});

  final Contact contact;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    MeshRouter.instance.sendChatMessage(widget.contact.meshId, text);

    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final myMeshId = IdentityRepository.instance.user!.meshId;

    return Scaffold(
      backgroundColor: AppColors.conversationTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: widget.contact.username,
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              textColor: Colors.white,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.contact.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.contact.meshId,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.conversationTop, AppColors.conversationBottom],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: MessagesRepository.instance,
                  builder: (context, _) {
                    final thread = MessagesRepository.instance.threadWith(
                      widget.contact.meshId,
                    );

                    if (thread.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet. Say hello 👋',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: thread.length,
                      itemBuilder: (context, index) {
                        final message = thread[index];
                        return MessageBubble(
                          text: message.content,
                          isOutgoing: message.senderId == myMeshId,
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.chip + 6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}