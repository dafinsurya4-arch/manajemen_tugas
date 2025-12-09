import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUid;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUid,
  });

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  // Using MessageService via Provider; no local field needed.
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final message = MessageModel(
      id: id,
      senderId: widget.currentUid,
      text: text,
      createdAt: DateTime.now(),
    );
    try {
      await Provider.of<MessageService>(
        context,
        listen: false,
      ).sendMessage(widget.groupId, message);
      _controller.clear();
      // scroll to bottom after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(widget.groupName, style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: Provider.of<MessageService>(
                context,
              ).streamMessages(widget.groupId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                final messages = snap.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m.senderId == widget.currentUid;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[600] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(m.senderId)
                                      .get(),
                                  builder: (ctx, userSnap) {
                                    final name = userSnap.hasData
                                        ? ((userSnap.data!.data()
                                                      as Map<
                                                        String,
                                                        dynamic
                                                      >?)?['fullName']
                                                  as String? ??
                                              'Unknown')
                                        : '';
                                    return Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey[700],
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 6),
                                Text(
                                  m.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  DateFormat('dd/MM HH:mm').format(m.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan... ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _send,
                  child: Icon(Icons.send),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
