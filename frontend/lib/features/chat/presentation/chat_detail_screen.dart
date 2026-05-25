import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';
import 'package:frontend/features/chat/data/chat_repository.dart';
import '../domain/message.dart';
import 'package:frontend/features/profile/data/profile_repository.dart';
import 'package:frontend/features/profile/domain/profile.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgController = TextEditingController();

  void _send() async {
    if (_msgController.text.trim().isEmpty) return;
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(widget.receiverId, _msgController.text.trim());
      _msgController.clear();
    } catch (e) {
      ToastService.showError(AuthErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(chatRepositoryProvider);
    final myId = ref.watch(supabaseClientProvider).auth.currentUser!.id;

    final profileRepo = ref.watch(profileRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.receiverName}")),
      body: FutureBuilder<Profile>(
        future: profileRepo.getMyProfile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
             return const Center(child: CircularProgressIndicator());
          }
          final isPremium = snapshot.data!.isPremium;
          if (!isPremium) {
             return const Center(
               child: Padding(
                 padding: EdgeInsets.all(20.0),
                 child: Text(
                   "You need the Supporter tier to unlock 1:1 chat features.\nHead over to your Profile to upgrade!",
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 16),
                 ),
               )
             );
          }

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: repo.getMessagesStream(widget.receiverId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No messages yet. Send a friendly hello!"));
                    }
                    final messages = snapshot.data!;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final m = messages[index];
                        final isMe = m.senderId == myId;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[600] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                              ),
                              boxShadow: isMe ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            child: Text(
                              m.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
