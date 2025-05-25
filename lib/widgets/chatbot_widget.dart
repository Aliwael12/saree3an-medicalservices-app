import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  bool _isExpanded = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your medical assistant. How can I help you today?",
      isUser: false,
    ),
  ];

  final Map<String, String> _responses = {
    'ambulance': "You can request an ambulance by tapping the 'Request Ambulance' service card. Our emergency response team will be dispatched to your location immediately.",
    'test': "You can reserve medical tests by selecting the 'Reserve Test' service. Choose between home collection or visit our lab. We offer various tests including blood tests, X-rays, and more.",
    'doctor': "To book a doctor visit, tap the 'Doctor Visit' service. You can choose your preferred doctor, date, and time for the consultation.",
    'video': "Access educational videos through the 'Educational Videos' section. We provide informative content about various health topics and medical procedures.",
    'payment': "We accept various payment methods including credit cards, debit cards, and mobile payments. Payment is processed securely at the time of service booking.",
    'emergency': "For emergencies, please use the 'Request Ambulance' service immediately. Our emergency response team is available 24/7.",
    'location': "Our main medical center is located at 123 Medical Center, Downtown. You can also use our home visit services for tests and doctor consultations.",
    'hours': "Our medical center is open from 8:00 AM to 8:00 PM daily. Emergency services are available 24/7.",
    'insurance': "We accept most major insurance providers. Please have your insurance details ready when booking services.",
    'contact': "You can reach us through the 'Contact Us' section or call our support line at +1234567890.",
  };

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 500), () {
      String response = _getBotResponse(text.toLowerCase());
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  String _getBotResponse(String userMessage) {
    for (var key in _responses.keys) {
      if (userMessage.contains(key)) {
        return _responses[key]!;
      }
    }
    return "I'm here to help you with information about our medical services. You can ask about ambulance services, medical tests, doctor visits, educational videos, payments, emergencies, locations, working hours, insurance, or how to contact us.";
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isExpanded)
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Medical Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _messages[index];
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: _handleSubmitted,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () => _handleSubmitted(_messageController.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 300.ms),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            backgroundColor: Colors.blue,
            child: Icon(
              _isExpanded ? Icons.close : Icons.chat,
              color: Colors.white,
            ),
          ).animate().scale(duration: 300.ms),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.medical_services,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 