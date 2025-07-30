// lib/widgets/social/report_content_dialog.dart
import 'package:flutter/material.dart';
import '../../models/content_moderation.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class ReportContentDialog extends StatefulWidget {
  final String contentId;
  final String contentType; // 'post' or 'comment'
  final String contentOwnerId;
  final String contentOwnerName;
  final Function(ContentReport) onReportSubmitted;

  const ReportContentDialog({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.contentOwnerId,
    required this.contentOwnerName,
    required this.onReportSubmitted,
  });

  @override
  State<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  ModerationReason? _selectedReason;
  final _customReasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReasonSelector(),
                    if (_selectedReason == ModerationReason.other) ...[
                      const SizedBox(height: 16),
                      _buildCustomReasonInput(),
                    ],
                    const SizedBox(height: 16),
                    _buildDescriptionInput(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.report,
            color: Colors.red,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contentType == 'post' ? tr(context, 'report_post') : tr(context, 'report_comment_title'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              Text(
                tr(context, 'help_community_safe'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor(context).withAlpha(153),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: AppTheme.textColor(context).withAlpha(153),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'why_reporting'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        ...ModerationReason.values.map((reason) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildReasonOption(reason),
          );
        }),
      ],
    );
  }

  Widget _buildReasonOption(ModerationReason reason) {
    final isSelected = _selectedReason == reason;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withAlpha(51)
              : AppTheme.textFieldBackground(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : AppTheme.textColor(context).withAlpha(51),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : AppTheme.textColor(context).withAlpha(153),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getReasonTitle(reason),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ContentModerationService.getReasonDescription(reason),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textColor(context).withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'specify_reason'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customReasonController,
          decoration: InputDecoration(
            hintText: tr(context, 'enter_specific_reason'),
            hintStyle: TextStyle(
              color: AppTheme.textColor(context).withAlpha(128),
            ),
            filled: true,
            fillColor: AppTheme.textFieldBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.textColor(context).withAlpha(51),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.textColor(context).withAlpha(51),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          style: TextStyle(
            color: AppTheme.textColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'additional_details'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: tr(context, 'provide_context'),
            hintStyle: TextStyle(
              color: AppTheme.textColor(context).withAlpha(128),
            ),
            filled: true,
            fillColor: AppTheme.textFieldBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.textColor(context).withAlpha(51),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.textColor(context).withAlpha(51),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          style: TextStyle(
            color: AppTheme.textColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: Text(
              tr(context, 'cancel'),
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(153),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _canSubmit() && !_isSubmitting ? _submitReport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    tr(context, 'submit_report'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    if (_selectedReason == null) return false;
    if (_selectedReason == ModerationReason.other && _customReasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final report = ContentReport(
        id: '', // Will be set by Firestore
        reporterId: 'current_user_id', // Will be replaced with actual user ID
        reporterName: 'Current User', // Will be replaced with actual user name
        contentId: widget.contentId,
        contentType: widget.contentType,
        contentOwnerId: widget.contentOwnerId,
        contentOwnerName: widget.contentOwnerName,
        reason: _selectedReason!,
        customReason: _selectedReason == ModerationReason.other 
            ? _customReasonController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim()
            : null,
        reportedAt: DateTime.now(),
        status: ModerationStatus.pending,
        action: ModerationAction.none,
      );

      widget.onReportSubmitted(report);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'report_success_message')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'failed_submit_report').replaceAll('{error}', '$e')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getReasonTitle(ModerationReason reason) {
    switch (reason) {
      case ModerationReason.spam:
        return tr(context, 'spam');
      case ModerationReason.harassment:
        return tr(context, 'harassment_bullying');
      case ModerationReason.inappropriateContent:
        return tr(context, 'inappropriate_content');
      case ModerationReason.falseInformation:
        return tr(context, 'false_information');
      case ModerationReason.hate:
        return tr(context, 'hate_speech');
      case ModerationReason.violence:
        return tr(context, 'violence_harmful');
      case ModerationReason.other:
        return tr(context, 'other');
    }
  }

}