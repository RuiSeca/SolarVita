// lib/screens/profile/settings/app/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int _selectedTab = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  final List<FAQ> _faqs = [
    FAQ(
      question: 'How do I track my workouts?',
      answer:
          'You can track your workouts by going to the Health tab and selecting "Track Workout". Choose your workout type and start tracking your progress.',
    ),
    FAQ(
      question: 'How does the eco-friendly reward system work?',
      answer:
          'Each sustainable action earns you eco-points. These points can be used for discounts on eco-friendly products from our partners or can be converted to tree plantations.',
    ),
    FAQ(
      question: 'Can I connect my fitness devices?',
      answer:
          'Yes! SolarVita supports most major fitness devices and apps. Go to Settings > Preferences > Connect Devices to set up your device.',
    ),
    FAQ(
      question: 'How do I change my goals?',
      answer:
          'You can update your fitness and sustainability goals in your profile settings under Preferences > Sustainability Goals.',
    ),
    FAQ(
      question: 'Can I share a workout with others?',
      answer:
          'You can share your workout simply by clicking the "Share" button on the workout details page.',
    ),
    FAQ(
      question: 'Can I customize my workout plans?',
      answer:
          'Yes! You can create custom workout plans in the Health tab. Just select "Create Plan" and add your preferred exercises.',
    ),

    FAQ(
      question: 'How can I reset my password?',
      answer:
          'If you need to reset your password, go to Settings > Account > Reset Password. You will receive an email with instructions.',
    ),

    FAQ(
      question: 'Does the app work offline?',
      answer:
          'Yes, you can log your workouts offline, and the data will sync automatically once you are back online.',
    ),

    FAQ(
      question: 'How do I enable notifications?',
      answer:
          'To enable notifications, go to Settings > Notifications and choose which alerts you want to receive.',
    ),

    FAQ(
      question: 'Can I track my carbon footprint?',
      answer:
          'Yes! In the Eco Tips button, located at the top right of the dashboard, you can monitor your carbon footprint and get tips on how to reduce it with eco-friendly habits.',
    ),

    FAQ(
      question: 'How do community challenges work?',
      answer:
          'Community challenges encourage healthy and sustainable habits. Join through the "Challenges" tab, complete tasks, and earn rewards.',
    ),

    // Add more FAQs as needed
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildSelectedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildTab('FAQ', 0),
          _buildTab('Chat', 1),
          _buildTab('Contact Us', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textColor(context).withValues(alpha: 153),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedTab) {
      case 0:
        return _buildFAQView();
      case 1:
        return _buildChatView();
      case 2:
        return _buildContactView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFAQView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        return _FAQItem(faq: _faqs[index]);
      },
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _ChatMessage(
                message: 'Hello! How can I help you today?',
                isBot: true,
              ),
              _ChatMessage(
                message:
                    'Our support bot is here to answer your questions about SolarVita.',
                isBot: true,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            border: Border(
              top: BorderSide(color: AppTheme.textColor(context).withValues(alpha: 26)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: TextStyle(color: AppTheme.textColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: AppTheme.textColor(context).withValues(alpha: 153)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.textFieldBackground(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    // Handle sending message
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send us a message',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'Enter your name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _messageController,
            label: 'Message',
            hint: 'How can we help you?',
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _sendEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Send Message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: AppTheme.textColor(context).withValues(alpha: 26)),
          const SizedBox(height: 24),
          Text(
            'Other ways to reach us',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'support@solarvita.com',
            onTap: () => _launchEmail('support@solarvita.com'),
          ),
          _buildContactOption(
            icon: Icons.phone,
            title: 'Phone',
            subtitle: '+1 (555) 123-4567',
            onTap: () => _launchPhone('+15551234567'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: AppTheme.textColor(context)),
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textColor(context).withValues(alpha: 153)),
            filled: true,
            fillColor: AppTheme.textFieldBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 153),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.textColor(context).withValues(alpha: 153), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail() async {
    // Implement email sending logic
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}

class FAQ {
  final String question;
  final String answer;

  FAQ({required this.question, required this.answer});
}

class _FAQItem extends StatefulWidget {
  final FAQ faq;

  const _FAQItem({required this.faq});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.faq.question,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.remove : Icons.add,
            color: AppColors.primary,
          ),
          onExpansionChanged: (value) => setState(() => _isExpanded = value),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.faq.answer,
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 153),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String message;
  final bool isBot;

  const _ChatMessage({
    required this.message,
    required this.isBot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.support_agent,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBot ? AppTheme.cardColor(context) : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isBot ? Colors.white : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
