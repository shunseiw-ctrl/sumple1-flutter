import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../core/services/payment_service.dart';
import '../core/enums/user_role.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import '../core/services/analytics_service.dart';
import '../core/providers/firebase_providers.dart';

class EarningsCreatePage extends ConsumerStatefulWidget {
  const EarningsCreatePage({super.key});

  @override
  ConsumerState<EarningsCreatePage> createState() => _EarningsCreatePageState();
}

class _EarningsCreatePageState extends ConsumerState<EarningsCreatePage> {
  late final FirebaseFirestore _db = ref.read(firestoreProvider);
  final _authService = AuthService();

  String get _myUid => ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('earnings_create');
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() => _isAdmin = role.isAdmin);
    }
  }

  String _query = '';

  DocumentSnapshot<Map<String, dynamic>>? _selectedApp;

  final _amountCtrl = TextEditingController();
  DateTime? _pickedDate;

  bool _saving = false;

  String _two(int n) => n.toString().padLeft(2, '0');
  String _ymd(DateTime d) => '${d.year}/${_two(d.month)}/${_two(d.day)}';

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _pickedDate ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (d != null) {
      setState(() => _pickedDate = d);
    }
  }

  int _parseAmountYen(String s) {
    final cleaned = s.replaceAll(',', '').replaceAll('¥', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _createStripePayment() async {
    if (!_isAdmin || _selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_selectJob)),
      );
      return;
    }

    final amount = _parseAmountYen(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_enterAmount)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await PaymentService().createPaymentIntent(
        applicationId: _selectedApp!.id,
        amount: amount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_stripeCreated(result['paymentId'].toString()))),
      );

      setState(() {
        _amountCtrl.clear();
        _selectedApp = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_stripeFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createEarning() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_adminOnly)),
      );
      return;
    }
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_selectJob)),
      );
      return;
    }

    final amount = _parseAmountYen(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_enterAmountExample)),
      );
      return;
    }

    final date = _pickedDate;
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_selectPaymentDate)),
      );
      return;
    }

    final app = _selectedApp!.data() ?? {};
    final appId = _selectedApp!.id;

    final targetUid = (app['applicantUid'] ?? '').toString();
    final projectName = (app['projectNameSnapshot'] ?? app['jobTitleSnapshot'] ?? context.l10n.common_job).toString();
    final jobId = (app['jobId'] ?? '').toString();

    if (targetUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_applicantUidEmpty)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payoutConfirmedAt = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, 0, 0, 0),
      );

      await _db.collection('earnings').add({
        'uid': targetUid,
        'applicationId': appId,
        'jobId': jobId,
        'projectNameSnapshot': projectName,
        'amount': amount,
        'payoutConfirmedAt': payoutConfirmedAt,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_earningRegistered)),
      );

      setState(() {
        _amountCtrl.clear();
        _pickedDate = null;
        _selectedApp = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.earningsCreate_registerFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid.isEmpty) {
      return Scaffold(body: Center(child: Text(context.l10n.common_pleaseLogin)));
    }
    if (!_isAdmin) {
      return Scaffold(
        body: Center(child: Text(context.l10n.common_adminOnlyView)),
      );
    }

    final appsQuery = _db
        .collection('applications')
        .where('adminUid', isEqualTo: _myUid)
        .orderBy('createdAt', descending: true)
        .limit(100);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.earningsCreate_title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: context.l10n.earningsCreate_searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: appsQuery.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text(context.l10n.common_loadError('${snap.error}')));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text(context.l10n.earningsCreate_noAssignedJobs));
                }

                final filtered = docs.where((d) {
                  final m = d.data();
                  final name = (m['projectNameSnapshot'] ?? m['jobTitleSnapshot'] ?? '').toString();
                  if (_query.isEmpty) return true;
                  return name.toLowerCase().contains(_query.toLowerCase());
                }).toList();

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = filtered[i];
                    final m = d.data();
                    final appId = d.id;

                    final name = (m['projectNameSnapshot'] ?? m['jobTitleSnapshot'] ?? context.l10n.common_job).toString();
                    final status = (m['status'] ?? '').toString();
                    final applicantUid = (m['applicantUid'] ?? '').toString();

                    final selected = _selectedApp?.id == appId;

                    return ListTile(
                      selected: selected,
                      leading: CircleAvatar(
                        backgroundColor: selected ? context.appColors.primaryPale : Colors.blueGrey.shade100,
                        child: Icon(
                          Icons.work_outline,
                          color: selected ? context.appColors.primary : context.appColors.textSecondary,
                        ),
                      ),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        'status: $status  uid:${applicantUid.isNotEmpty ? applicantUid.substring(0, applicantUid.length > 8 ? 8 : applicantUid.length) : "-"}…',
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: context.appColors.primary)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        setState(() {
                          _selectedApp = d;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              border: Border(top: BorderSide(color: context.appColors.divider)),
            ),
            child: _selectedApp == null
                ? Text(
              context.l10n.earningsCreate_selectFromList,
              style: TextStyle(color: context.appColors.textSecondary, fontWeight: FontWeight.w700),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedSummary(app: _selectedApp!),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.l10n.earningsCreate_amountLabel,
                          hintText: context.l10n.earningsCreate_amountHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.l10n.earningsCreate_paymentDateLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(
                            _pickedDate == null ? context.l10n.common_select : _ymd(_pickedDate!),
                            style: TextStyle(
                              color: _pickedDate == null ? context.appColors.textHint : context.appColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _createEarning,
                    child: Text(
                      _saving ? context.l10n.common_registering : context.l10n.earningsCreate_registerButton,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _createStripePayment(),
                    icon: const Icon(Icons.credit_card, size: 18),
                    label: Text(
                      context.l10n.earningsCreate_stripePayButton,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.stripeColor,
                      side: BorderSide(color: context.appColors.stripeColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.earningsCreate_earningsNote,
                  style: TextStyle(fontSize: 12, color: context.appColors.textHint, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> app;
  const _SelectedSummary({required this.app});

  @override
  Widget build(BuildContext context) {
    final m = app.data() ?? {};
    final name = (m['projectNameSnapshot'] ?? m['jobTitleSnapshot'] ?? context.l10n.common_job).toString();
    final uid = (m['applicantUid'] ?? '').toString();
    final status = (m['status'] ?? '').toString();

    String short(String s) => s.isEmpty ? '-' : (s.length <= 10 ? s : '${s.substring(0, 10)}…');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appColors.primaryPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('appId: ${short(app.id)}',
              style: TextStyle(fontSize: 12, color: context.appColors.textSecondary, fontWeight: FontWeight.w700)),
          Text('applicantUid: ${short(uid)}',
              style: TextStyle(fontSize: 12, color: context.appColors.textSecondary, fontWeight: FontWeight.w700)),
          Text('status: $status',
              style: TextStyle(fontSize: 12, color: context.appColors.textSecondary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
