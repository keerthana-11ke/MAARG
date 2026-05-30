import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatState {
  final List<ChatMessage> messages;

  ChatState({required this.messages});
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(
      messages: [
        ChatMessage(
          text: "Hello, I am your Emergency AI assistant. How can I help you? Choose a quick option below or type your question.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)..add(userMsg);
    state = ChatState(messages: updatedMessages);

    // Analyze keyword responses
    final lowerText = text.toLowerCase();
    String botResponse = "";

    if (lowerText.contains("bleeding")) {
      botResponse = "🩸 **Bleeding Control Protocol:**\n\n"
          "1. **Apply Firm Pressure**: Use a clean cloth, towel, or your hand to apply direct pressure on the wound.\n"
          "2. **Maintain Pressure**: Do NOT lift the cloth to check. If blood seeps through, add another cloth on top.\n"
          "3. **Elevate**: If possible, lift the bleeding limb above the level of the heart to slow down the flow.\n"
          "4. **Keep Warm**: Cover the victim to prevent shock.";
    } else if (lowerText.contains("unconscious")) {
      botResponse = "💤 **Unconscious Patient Protocol:**\n\n"
          "1. **Check Breathing**: Watch the chest for rise and fall, and feel for breath. Shake their shoulders and shout.\n"
          "2. **If Breathing**: Gently roll them into the **Recovery Position** (on their side) to keep the airway clear.\n"
          "3. **If NOT Breathing**: Immediately begin chest compressions (CPR).\n"
          "4. **Do NOT move** the neck or back unless there is immediate danger of fire or explosion.";
    } else if (lowerText.contains("move") || lowerText.contains("moving")) {
      botResponse = "⚠️ **CRITICAL WARNING:**\n\n"
          "Do **NOT** move the victim. There is a high risk of spinal injury.\n"
          "- Keep the head, neck, and spine completely straight.\n"
          "- Only move them if they are in immediate danger of fire, explosion, or incoming traffic.";
    } else if (lowerText.contains("breathing") || lowerText.contains("breath") || lowerText.contains("cpr")) {
      botResponse = "❤️ **CPR Step-by-Step Guide:**\n\n"
          "1. **Hand Placement**: Place the heel of one hand in the center of the chest, and interlock the other hand on top.\n"
          "2. **Compressions**: Push **hard and fast** (2 inches deep, 100-120 compressions per minute).\n"
          "3. **Rhythm**: Push to the beat of 'Stayin\' Alive'.\n"
          "4. **Continuous**: Do NOT stop compressions until medical help arrives.";
    } else if (lowerText.contains("bone") || lowerText.contains("broken") || lowerText.contains("fracture")) {
      botResponse = "🦴 **Fracture / Broken Bone Protocol:**\n\n"
          "1. **Immobilize the Area**: Keep the injured limb completely still. Do NOT try to realign or push back a bone.\n"
          "2. **Support Above & Below**: Place padding or a splint around the joint above and below the fracture.\n"
          "3. **Apply Cold Pack**: Place an ice pack wrapped in a cloth to reduce swelling. Do NOT apply ice directly.\n"
          "4. **Stop Bleeding First**: If there is an open wound with the bone showing, cover it with a sterile dressing and apply pressure surrounding it, not directly on the bone.";
    } else {
      botResponse = "💬 I understand your concern. Please select one of the quick options or specify if the victim is:\n"
          "- **Bleeding**\n"
          "- **Unconscious**\n"
          "- **Not breathing** (needs CPR)\n"
          "- **Broken bone** (fracture)\n"
          "- If you need to **move** them.";
    }

    // Add bot response after a brief delay to simulate typing
    Future.delayed(const Duration(milliseconds: 600), () {
      final botMsg = ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = ChatState(messages: List<ChatMessage>.from(state.messages)..add(botMsg));
    });
  }

  void clearHistory() {
    state = ChatState(
      messages: [
        ChatMessage(
          text: "Hello, I am your Emergency AI assistant. How can I help you? Choose a quick option below or type your question.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
