import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class Message {
  final bool isUser;
  final String message;
  final DateTime date;
  final bool isLoading; // New property to indicate loading state

  Message({
    required this.isUser,
    required this.message,
    required this.date,
    this.isLoading = false, // Default to false
  });
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _userInput = TextEditingController();
  static const apiKey =
      'AIzaSyDI7Bjn6HTZllGHPEtxdmLas9HNlNLnOco'; // Replace with your Gemini API key
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  final List<Message> _messages = [];
  final ScrollController _scrollController =
      ScrollController(); // ScrollController

  Future<void> sendMessage() async {
    final message = _userInput.text;
    if (message.isEmpty) return;

    setState(() {
      _messages
          .add(Message(isUser: true, message: message, date: DateTime.now()));
      _userInput.clear();
      // Add a loading message
      _messages.add(Message(
          isUser: false, message: '', date: DateTime.now(), isLoading: true));
    });

    // Scroll to the bottom after adding a new message
    _scrollToBottom();

    try {
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(message));

      final responseText = response.text;
      if (responseText == null) {
        throw Exception('Empty response received');
      }

      setState(() {
        // Update the loading message with the AI's response
        _messages.removeLast(); // Remove the loading message
        _messages.add(Message(
          isUser: false,
          message: responseText,
          date: DateTime.now(),
        ));
      });
    } catch (e, stackTrace) {
      debugPrint('Error in sendMessage: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        // Update the loading message with an error message
        _messages.removeLast(); // Remove the loading message
        _messages.add(Message(
          isUser: false,
          message:
              "Error: Something went wrong. Please check your API key and try again.\nError details: $e",
          date: DateTime.now(),
        ));
      });
    } finally {
      // Scroll to the bottom after the message is added
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Bot'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController, // Attach the ScrollController
                itemCount: _messages.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(
                    isUser: message.isUser,
                    message: message.isLoading
                        ? "Loading..." // Show loading text
                        : message.message,
                    date: DateFormat('HH:mm').format(message.date),
                    isLoading: message
                        .isLoading, // Pass loading state to MessageBubble
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userInput,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: sendMessage,
                    backgroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;
  final bool isLoading; // New property to indicate loading state

  const MessageBubble({
    Key? key,
    required this.isUser,
    required this.message,
    required this.date,
    required this.isLoading, // Required parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4).copyWith(
          left: isUser ? 64 : 0,
          right: isUser ? 0 : 64,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isUser ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading) // Display a loading indicator when isLoading is true
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 8),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                        color: Colors.white), // Adjust color as needed
                  ),
                ],
              )
            else ...[
              Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  color: isUser ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
