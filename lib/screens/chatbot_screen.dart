import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kavach/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatService chatService;

  const ChatScreen({super.key, required this.chatService});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _promptsScrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes to update the UI
    _controller.addListener(() {
      setState(() {}); // Trigger UI update when text changes
    });
  }

  void _startNewChat() {
    setState(() {
      messages.clear();
      _controller.clear();
      isGenerating = false;
    });
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

  void sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "message": userMessage});
      isGenerating = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      String botResponse;
      List<String> safetyKeywords = [
        "emergency",
        "safety",
        "help",
        "danger",
        "accident",
        "alert",
        "rescue",
        "injury",
        "fire",
        "medical",
        "hazard",
        "threat",
        "crime",
      ];
      bool isSafetyQuery = safetyKeywords.any(
        (keyword) => userMessage.toLowerCase().contains(keyword.toLowerCase()),
      );

      // Fetch the bot response without truncation
      botResponse = await widget.chatService.getResponse(userMessage);

      setState(() {
        messages.add({"sender": "bot", "message": botResponse});
        isGenerating = false;
      });
    } catch (e) {
      setState(() {
        messages.add({
          "sender": "bot",
          "message": "Error: Unable to process your request.",
        });
        isGenerating = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      appBar: AppBar(
        backgroundColor: Colors.white, // White app bar
        surfaceTintColor: Colors.white, // Prevents color tinting when scrolled
        scrolledUnderElevation: 1, // Removes elevation shadow when scrolled
        elevation: 0,
        shadowColor: Colors.black.withOpacity(
          0.7,
        ), // Border color when elevated
        leadingWidth: 80,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_back,
                color: Colors.blueAccent,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _startNewChat,
            child: const Icon(
              CupertinoIcons.refresh,
              color: Colors.black,
              size: 22,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Container(height: 0.5, color: Colors.grey.withOpacity(0.3)),
              Expanded(
                child: messages.isEmpty ? _buildEmptyState() : _buildChatList(),
              ),
              _buildPredefinedPrompts(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA).withOpacity(0.4),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              CupertinoIcons.shield,
              size: 40,
              color: Colors.grey[600]!.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Safety Buddy',
            style: TextStyle(
              color: const Color(0xFF111111).withOpacity(0.4),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length + (isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isGenerating) {
          return _buildTypingIndicator();
        }

        final current = messages[index];
        final isUser = current["sender"] == "user";

        // Group consecutive messages from the same sender
        final isFirstInGroup =
            index == 0 || messages[index - 1]["sender"] != current["sender"];
        final isLastInGroup =
            index == messages.length - 1 ||
            messages[index + 1]["sender"] != current["sender"];

        return _buildMessageBubble(
          current,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        );
      },
    );
  }

  Widget _buildMessageBubble(
    Map<String, String> messageData, {
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final bool isUser = messageData["sender"] == "user";

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 16 : 4,
        bottom: isLastInGroup ? 16 : 4,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && isLastInGroup)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF007AFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.shield_fill,
                color: Colors.white,
                size: 16,
              ),
            )
          else if (!isUser)
            const SizedBox(width: 36),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF17272D) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : (isLastInGroup
                            ? const Radius.circular(5)
                            : const Radius.circular(20)),
                  bottomRight: isUser
                      ? (isLastInGroup
                            ? const Radius.circular(5)
                            : const Radius.circular(20))
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                child: Text(
                  messageData["message"] ?? "",
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF111111),
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),

          if (isUser && isLastInGroup)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF8E8E93),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
                size: 16,
              ),
            )
          else if (isUser)
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.shield_fill,
              color: Colors.white,
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTypingDot(delay: 0),
                _buildTypingDot(delay: 300),
                _buildTypingDot(delay: 600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot({required int delay}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: (value - (delay / 1500)) % 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF8E8E93),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPredefinedPrompts() {
    final List<String> predefinedPrompts = [
      "Report an emergency",
      "Safety tips for home",
      "Emergency contacts",
      "Create a safety plan",
      "First aid basics",
      "Evacuation procedures",
    ];

    // Hide prompts if there are any messages
    if (messages.isNotEmpty) {
      return const SizedBox.shrink(); // Returns an empty widget
    }

    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        controller: _promptsScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: predefinedPrompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _controller.text = predefinedPrompts[index];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  predefinedPrompts[index],
                  style: const TextStyle(
                    color: Color(0xFF17272D),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Color(0xFF111111), fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Ask Safety Buddy",
                  hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Send button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isGenerating
                  ? () {
                      setState(() {
                        isGenerating = false;
                      });
                    }
                  : _controller.text.trim().isEmpty
                  ? null
                  : sendMessage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isGenerating
                      ? const Color(0xFFFF3B30) // Red for stop
                      : const Color(0xFF17272D), // Blue for send
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isGenerating
                      ? CupertinoIcons.stop_fill
                      : CupertinoIcons.arrow_up,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}