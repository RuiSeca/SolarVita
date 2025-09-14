import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'contact_us'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactHeader(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildContactForm(context),
            const SizedBox(height: 24),
            _buildContactInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'we_are_here_to_help'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(context, 'contact_us_description'),
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': tr(context, 'live_chat'),
        'subtitle': tr(context, 'chat_with_support_team'),
        'color': Colors.blue,
        'onTap': () => _showNotImplementedSnackBar(context, tr(context, 'live_chat')),
      },
      {
        'icon': Icons.email_outlined,
        'title': tr(context, 'send_email'),
        'subtitle': tr(context, 'email_support_team'),
        'color': Colors.green,
        'onTap': () => _scrollToContactForm(),
      },
      {
        'icon': Icons.phone_outlined,
        'title': tr(context, 'phone_support'),
        'subtitle': tr(context, 'call_support_line'),
        'color': Colors.orange,
        'onTap': () => _showPhoneDialog(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'quick_actions'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) => _buildActionCard(context, action)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, Map<String, dynamic> action) {
    return GestureDetector(
      onTap: action['onTap'] as VoidCallback,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withAlpha(26),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (action['color'] as Color).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                action['icon'] as IconData,
                color: action['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action['title'] as String,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action['subtitle'] as String,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textColor(context).withAlpha(128),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return Form(
      key: _formKey,
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
          const SizedBox(height: 16),
          
          // Category Selection
          _buildCategorySelection(context),
          const SizedBox(height: 16),
          
          // Name Field
          _buildTextField(
            controller: _nameController,
            label: tr(context, 'your_name'),
            hint: tr(context, 'enter_your_name'),
            icon: Icons.person_outline,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return tr(context, 'name_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email Field
          _buildTextField(
            controller: _emailController,
            label: tr(context, 'email_address'),
            hint: tr(context, 'enter_email_address'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return tr(context, 'email_required');
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return tr(context, 'invalid_email');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Subject Field
          _buildTextField(
            controller: _subjectController,
            label: tr(context, 'subject'),
            hint: tr(context, 'enter_subject'),
            icon: Icons.subject_outlined,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return tr(context, 'subject_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Message Field
          _buildTextField(
            controller: _messageController,
            label: tr(context, 'message'),
            hint: tr(context, 'enter_your_message'),
            icon: Icons.message_outlined,
            maxLines: 5,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return tr(context, 'message_required');
              }
              if (value!.length < 10) {
                return tr(context, 'message_too_short');
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(tr(context, 'sending')),
                      ],
                    )
                  : Text(
                      tr(context, 'send_message'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection(BuildContext context) {
    final categories = [
      {'value': 'general', 'label': tr(context, 'general_inquiry')},
      {'value': 'technical', 'label': tr(context, 'technical_support')},
      {'value': 'billing', 'label': tr(context, 'billing_issue')},
      {'value': 'feature', 'label': tr(context, 'feature_request')},
      {'value': 'bug', 'label': tr(context, 'bug_report')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'category'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategory == category['value'];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category['value'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withAlpha(51),
                  ),
                ),
                child: Text(
                  category['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withAlpha(51)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withAlpha(51)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: AppTheme.cardColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'other_ways_to_reach_us'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            context,
            icon: Icons.email,
            title: tr(context, 'email'),
            value: 'support@solarvita.com',
          ),
          _buildContactItem(
            context,
            icon: Icons.phone,
            title: tr(context, 'phone'),
            value: '+1 (555) 123-4567',
          ),
          _buildContactItem(
            context,
            icon: Icons.access_time,
            title: tr(context, 'business_hours'),
            value: '${tr(context, 'monday_friday')} 9 AM - 6 PM EST',
          ),
          _buildContactItem(
            context,
            icon: Icons.language,
            title: tr(context, 'website'),
            value: 'www.solarvita.com',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToContactForm() {
    // In a real implementation, you would scroll to the form section
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'scroll_to_form')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPhoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'phone_support')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(context, 'call_us_at')),
            const SizedBox(height: 8),
            SelectableText(
              '+1 (555) 123-4567',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${tr(context, 'business_hours')}: ${tr(context, 'monday_friday')} 9 AM - 6 PM EST',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'close')),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate form submission
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'message_sent_successfully')),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
      setState(() => _selectedCategory = 'general');
    }
  }

  void _showNotImplementedSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ${tr(context, 'feature_coming_soon')}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}