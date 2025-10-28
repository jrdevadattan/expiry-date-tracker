import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracker/providers/item_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Welcome message
    _addMessage(ChatMessage(
      text: "Hello! I'm your Expiry Tracker assistant. I can help you with:\n\n"
          "• Check items expiring soon\n"
          "• Get recipe suggestions based on your items\n"
          "• Food storage tips\n"
          "• Inventory statistics\n\n"
          "What would you like to know?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    
    // Add user message
    _addMessage(ChatMessage(text: text, isUser: true));

    // Generate AI response based on user input
    final response = _generateResponse(text.toLowerCase());
    
    // Simulate thinking delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _addMessage(ChatMessage(text: response, isUser: false));
      }
    });
  }

  String _generateResponse(String input) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final items = itemProvider.items;

    // Expiring soon
    if (input.contains('expir') || input.contains('soon') || input.contains('urgent')) {
      final expiringSoon = items.where((item) {
        final daysLeft = item.expiry.difference(DateTime.now()).inDays;
        return daysLeft >= 0 && daysLeft <= 7;
      }).toList();

      if (expiringSoon.isEmpty) {
        return "Great news! You don't have any items expiring in the next 7 days. 🎉";
      }

      final response = StringBuffer("You have ${expiringSoon.length} item(s) expiring soon:\n\n");
      for (final item in expiringSoon.take(5)) {
        final daysLeft = item.expiry.difference(DateTime.now()).inDays;
        response.writeln("• ${item.name} - ${daysLeft == 0 ? 'Today!' : '$daysLeft days'}");
      }
      
      if (expiringSoon.length > 5) {
        response.writeln("\n...and ${expiringSoon.length - 5} more.");
      }
      
      return response.toString();
    }

    // Recipe suggestions
    if (input.contains('recipe') || input.contains('cook') || input.contains('make')) {
      final foodItems = items.where((item) => 
        item.itemType.toLowerCase() == 'food' || 
        item.itemType.toLowerCase() == 'dairy'
      ).take(3).toList();

      if (foodItems.isEmpty) {
        return "You don't have any food items in your inventory yet. Add some items first!";
      }

      final response = StringBuffer("Based on your inventory, here are some recipe ideas:\n\n");
      
      if (foodItems.any((item) => item.name.toLowerCase().contains('tomato'))) {
        response.writeln("🍝 Pasta with Tomato Sauce");
      }
      if (foodItems.any((item) => item.name.toLowerCase().contains('chicken'))) {
        response.writeln("🍗 Grilled Chicken");
      }
      if (foodItems.any((item) => item.name.toLowerCase().contains('egg'))) {
        response.writeln("🍳 Omelet");
      }
      
      // Generic suggestions based on items
      response.writeln("\nYou currently have:");
      for (final item in foodItems) {
        response.writeln("• ${item.name}");
      }
      
      return response.toString();
    }

    // Statistics
    if (input.contains('how many') || input.contains('total') || input.contains('count') || input.contains('stat')) {
      final total = items.length;
      final expired = items.where((item) => item.expiry.isBefore(DateTime.now())).length;
      final expiringSoon = items.where((item) {
        final daysLeft = item.expiry.difference(DateTime.now()).inDays;
        return daysLeft >= 0 && daysLeft <= 7;
      }).length;

      final typeGroups = <String, int>{};
      for (final item in items) {
        typeGroups[item.itemType] = (typeGroups[item.itemType] ?? 0) + 1;
      }

      final response = StringBuffer("📊 Your Inventory Stats:\n\n");
      response.writeln("Total items: $total");
      response.writeln("Expired: $expired");
      response.writeln("Expiring soon (7 days): $expiringSoon");
      response.writeln("\nBy category:");
      typeGroups.forEach((type, count) {
        response.writeln("• $type: $count");
      });

      return response.toString();
    }

    // Storage tips
    if (input.contains('store') || input.contains('keep') || input.contains('fresh') || input.contains('tip')) {
      return "🧊 Food Storage Tips:\n\n"
          "• Keep dairy products at 4°C or below\n"
          "• Store vegetables in the crisper drawer\n"
          "• Keep bread in a cool, dry place\n"
          "• Freeze items you won't use soon\n"
          "• Use airtight containers for opened items\n"
          "• Label everything with dates\n"
          "• First in, first out (FIFO) method\n\n"
          "Need specific tips for a particular item?";
    }

    // Help
    if (input.contains('help') || input.contains('what can you')) {
      return "I can help you with:\n\n"
          "✅ Check expiring items - Ask \"What's expiring soon?\"\n"
          "✅ Get recipe ideas - Ask \"What can I cook?\"\n"
          "✅ Storage tips - Ask \"How should I store food?\"\n"
          "✅ Inventory stats - Ask \"How many items do I have?\"\n\n"
          "Just ask me anything about your food inventory!";
    }

    // Default response
    final responses = [
      "I'm here to help! Try asking about:\n• Items expiring soon\n• Recipe suggestions\n• Storage tips\n• Your inventory stats",
      "I can help you manage your food inventory better. What would you like to know?",
      "Not sure what you mean. Try asking about expiring items, recipes, or storage tips!",
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Text('AI Assistant'),
          ],
        ),
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          const Divider(height: 1),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF00C853),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF00C853),
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF00C853)
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : null,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              radius: 16,
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
