import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/extensions/build_context_extensions.dart';

class RatingDialog extends StatefulWidget {
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String targetUid;

  const RatingDialog({
    super.key,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.targetUid,
  });

  static Future<void> show(BuildContext context, {
    required String applicationId,
    required String jobId,
    required String jobTitle,
    required String targetUid,
  }) {
    return showDialog(
      context: context,
      builder: (_) => RatingDialog(
        applicationId: applicationId,
        jobId: jobId,
        jobTitle: jobTitle,
        targetUid: targetUid,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _stars = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ratingDialog_selectStars)),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('ratings').add({
        'applicationId': widget.applicationId,
        'jobId': widget.jobId,
        'raterUid': uid,
        'targetUid': widget.targetUid,
        'stars': _stars,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ratingDialog_submitSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ratingDialog_submitFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              context.l10n.ratingDialog_title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              widget.jobTitle,
              style: TextStyle(fontSize: 14, color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starNum = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _stars = starNum),
                  icon: Icon(
                    starNum <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: starNum <= _stars ? Colors.amber : context.appColors.textHint,
                  ),
                );
              }),
            ),
            if (_stars > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    '',
                    context.l10n.ratingDialog_dissatisfied,
                    context.l10n.ratingDialog_somewhatDissatisfied,
                    context.l10n.ratingDialog_average,
                    context.l10n.ratingDialog_good,
                    context.l10n.ratingDialog_excellent,
                  ][_stars],
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.appColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.l10n.ratingDialog_commentHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(context.l10n.ratingDialog_submit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.ratingDialog_later, style: TextStyle(color: context.appColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
