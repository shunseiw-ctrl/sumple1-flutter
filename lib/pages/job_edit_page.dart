import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/utils/prefecture_utils.dart';
import 'package:sumple1/core/utils/job_date_utils.dart' as date_utils;
import 'package:sumple1/presentation/widgets/section_title.dart';
import 'package:sumple1/presentation/widgets/white_card.dart';
import 'package:sumple1/presentation/widgets/form_divider.dart';
import 'package:sumple1/presentation/widgets/labeled_field.dart';
import 'package:sumple1/presentation/widgets/hint_card.dart';

class JobEditPage extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobEditPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<JobEditPage> createState() => _JobEditPageState();
}

class _JobEditPageState extends State<JobEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _dateController;

  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('job_edit');

    _titleController =
        TextEditingController(text: widget.jobData['title']?.toString() ?? '');
    _locationController =
        TextEditingController(text: widget.jobData['location']?.toString() ?? '');
    _priceController =
        TextEditingController(text: widget.jobData['price']?.toString() ?? '0');
    _dateController =
        TextEditingController(text: widget.jobData['date']?.toString() ?? '');

    _descriptionController =
        TextEditingController(text: widget.jobData['description']?.toString() ?? '');
    _notesController =
        TextEditingController(text: widget.jobData['notes']?.toString() ?? '');
    _latitudeController =
        TextEditingController(text: widget.jobData['latitude']?.toString() ?? '');
    _longitudeController =
        TextEditingController(text: widget.jobData['longitude']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }


  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    final text = _dateController.text.trim();
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(text)) {
      final parts = text.split('-').map(int.parse).toList();
      initial = DateTime(parts[0], parts[1], parts[2]);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: context.l10n.jobEdit_datePickerHelp,
      cancelText: context.l10n.jobEdit_datePickerCancel,
      confirmText: context.l10n.jobEdit_datePickerConfirm,
    );

    if (picked == null) return;

    _dateController.text = date_utils.dateKey(picked);
  }

  Future<void> _update() async {
    if (_isLoading) return;

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final priceText = _priceController.text.trim();
    final dateKey = _dateController.text.trim();

    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    if (title.isEmpty || location.isEmpty || priceText.isEmpty || dateKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.jobEdit_snackEmptyFields)),
      );
      return;
    }

    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!iso.hasMatch(dateKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.jobEdit_snackSelectDateFromCalendar)),
      );
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.jobEdit_snackPriceNumeric)),
      );
      return;
    }

    final prefecture = guessPrefecture(location);
    final monthKey = date_utils.monthKeyFromDateKey(dateKey);

    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());

    setState(() => _isLoading = true);

    try {
      final updateData = <String, dynamic>{
        'title': title,
        'location': location,
        'prefecture': prefecture,
        'price': price,

        'date': dateKey,
        'workDateKey': dateKey,
        'workMonthKey': monthKey,

        'description': description,
        'notes': notes,

        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (lat != null) updateData['latitude'] = lat;
      if (lng != null) updateData['longitude'] = lng;

      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update(updateData);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.jobEdit_snackUpdateFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.jobEdit_title,
          style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: context.appColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.appColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
                  : Text(
                context.l10n.jobEdit_updateButton,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          children: [
            SectionTitle(
              title: context.l10n.jobEdit_sectionTitle,
              subtitle: context.l10n.jobEdit_sectionSubtitle,
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: context.l10n.jobEdit_titleLabel,
                    hint: context.l10n.jobEdit_titleHint,
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: AppConstants.maxJobTitleLength,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: context.l10n.jobEdit_locationLabel,
                    hint: context.l10n.jobEdit_locationHint,
                    controller: _locationController,
                    textInputAction: TextInputAction.next,
                    maxLength: AppConstants.maxJobLocationLength,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: context.l10n.jobEdit_priceLabel,
                    hint: context.l10n.jobEdit_priceHint,
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.currency_yen,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: context.l10n.jobEdit_dateLabel,
                    hint: context.l10n.jobEdit_dateHint,
                    controller: _dateController,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.event,
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: context.l10n.jobEdit_descriptionLabel,
                    hint: context.l10n.jobEdit_descriptionHint,
                    controller: _descriptionController,
                    textInputAction: TextInputAction.next,
                    maxLines: 6,
                    maxLength: AppConstants.maxJobDescriptionLength,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: context.l10n.jobEdit_notesLabel,
                    hint: context.l10n.jobEdit_notesHint,
                    controller: _notesController,
                    textInputAction: TextInputAction.done,
                    maxLines: 6,
                    maxLength: AppConstants.maxJobNotesLength,
                    onSubmitted: (_) => _update(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: context.l10n.jobEdit_latitudeLabel,
                    hint: context.l10n.jobEdit_latitudeHint,
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.my_location,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: context.l10n.jobEdit_longitudeLabel,
                    hint: context.l10n.jobEdit_longitudeHint,
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.my_location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            HintCard(
              title: context.l10n.jobEdit_hintTitle,
              body: context.l10n.jobEdit_hintBody,
            ),
          ],
        ),
      ),
    );
  }
}
