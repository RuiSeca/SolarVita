// lib/screens/profile/settings/app/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';

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

  List<FAQ> get _faqs => [
    FAQ(
      questionKey: 'faq_track_workouts_q',
      answerKey: 'faq_track_workouts_a',
    ),
    FAQ(
      questionKey: 'faq_eco_rewards_q',
      answerKey: 'faq_eco_rewards_a',
    ),
    FAQ(
      questionKey: 'faq_connect_devices_q',
      answerKey: 'faq_connect_devices_a',
    ),
    FAQ(
      questionKey: 'faq_change_goals_q',
      answerKey: 'faq_change_goals_a',
    ),
    FAQ(
      questionKey: 'faq_share_workout_q',
      answerKey: 'faq_share_workout_a',
    ),
    FAQ(
      questionKey: 'faq_customize_plans_q',
      answerKey: 'faq_customize_plans_a',
    ),
    FAQ(
      questionKey: 'faq_reset_password_q',
      answerKey: 'faq_reset_password_a',
    ),
    FAQ(
      questionKey: 'faq_offline_mode_q',
      answerKey: 'faq_offline_mode_a',
    ),
    FAQ(
      questionKey: 'faq_notifications_q',
      answerKey: 'faq_notifications_a',
    ),
    FAQ(
      questionKey: 'faq_carbon_footprint_q',
      answerKey: 'faq_carbon_footprint_a',
    ),
    FAQ(
      questionKey: 'faq_community_challenges_q',
      answerKey: 'faq_community_challenges_a',
    ),
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
          tr(context, 'help_support'),
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
          _buildTab(tr(context, 'faq'), 0),
          _buildTab(tr(context, 'chat'), 1),
          _buildTab(tr(context, 'contact_us'), 2),
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
            color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor(context),
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
            children: [
              _ChatMessage(
                message: tr(context, 'chat_hello_message'),
                isBot: true,
              ),
              _ChatMessage(
                message: tr(context, 'chat_support_bot_message'),
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
                    hintText: tr(context, 'type_your_message'),
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
                  color: AppTheme.primaryColor,
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
            tr(context, 'send_us_message'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            label: tr(context, 'name'),
            hint: tr(context, 'enter_your_name'),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: tr(context, 'email'),
            hint: tr(context, 'enter_your_email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _messageController,
            label: tr(context, 'message'),
            hint: tr(context, 'how_can_we_help'),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _sendEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              tr(context, 'send_message'),
              style: const TextStyle(
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
            tr(context, 'other_ways_to_reach_us'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            icon: Icons.email,
            title: tr(context, 'email'),
            subtitle: 'support@solarvita.com',
            onTap: () => _launchEmail('support@solarvita.com'),
          ),
          _buildContactOption(
            icon: Icons.phone,
            title: tr(context, 'phone'),
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
                color: AppTheme.primaryColor.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
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
  final String questionKey;
  final String answerKey;

  FAQ({required this.questionKey, required this.answerKey});
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
            tr(context, widget.faq.questionKey),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.remove : Icons.add,
            color: AppTheme.primaryColor,
          ),
          onExpansionChanged: (value) => setState(() => _isExpanded = value),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                tr(context, widget.faq.answerKey),
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
                color: AppTheme.primaryColor.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.support_agent,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBot ? AppTheme.cardColor(context) : AppTheme.primaryColor,
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
                color: AppTheme.primaryColor.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
