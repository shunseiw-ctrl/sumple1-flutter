import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EarningsCreatePage extends StatefulWidget {
  const EarningsCreatePage({super.key});

  @override
  State<EarningsCreatePage> createState() => _EarningsCreatePageState();
}

class _EarningsCreatePageState extends State<EarningsCreatePage> {
  final _db = FirebaseFirestore.instance;

  // 固定ADMIN UID（MVP）
  static const String _adminUid = '5AeMBYb9PifYVUWMf4lSdCjuM1s1';

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isAdmin => _myUid.isNotEmpty && _myUid == _adminUid;

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

  Future<void> _createEarning() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('管理者のみ操作できます')),
      );
      return;
    }
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('案件を選択してください')),
      );
      return;
    }

    final amount = _parseAmountYen(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金額を入力してください（例: 12000）')),
      );
      return;
    }

    final date = _pickedDate;
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支払い確定日を選択してください')),
      );
      return;
    }

    final app = _selectedApp!.data() ?? {};
    final appId = _selectedApp!.id;

    final targetUid = (app['applicantUid'] ?? '').toString();
    final projectName = (app['projectNameSnapshot'] ?? app['jobTitleSnapshot'] ?? '案件').toString();
    final jobId = (app['jobId'] ?? '').toString();

    if (targetUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('applications.applicantUid が空です')),
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
        const SnackBar(content: Text('支払い確定（売上）を登録しました')),
      );

      setState(() {
        _amountCtrl.clear();
        _pickedDate = null;
        _selectedApp = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録に失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid.isEmpty) {
      return const Scaffold(body: Center(child: Text('ログインしてください')));
    }
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: Text('管理者のみ閲覧できます')),
      );
    }

    final appsQuery = _db
        .collection('applications')
        .where('adminUid', isEqualTo: _myUid)
        .orderBy('createdAt', descending: true)
        .limit(100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('支払い確定（売上登録）'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '物件名で検索（projectNameSnapshot）',
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
                  return Center(child: Text('読み込みエラー: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('担当案件がありません'));
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

                    final name = (m['projectNameSnapshot'] ?? m['jobTitleSnapshot'] ?? '案件').toString();
                    final status = (m['status'] ?? '').toString();
                    final applicantUid = (m['applicantUid'] ?? '').toString();

                    final selected = _selectedApp?.id == appId;

                    return ListTile(
                      selected: selected,
                      leading: CircleAvatar(
                        backgroundColor: selected ? Colors.deepPurple.shade50 : Colors.blueGrey.shade100,
                        child: Icon(
                          Icons.work_outline,
                          color: selected ? Colors.deepPurple : Colors.black54,
                        ),
                      ),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        'status: $status  uid:${applicantUid.isNotEmpty ? applicantUid.substring(0, applicantUid.length > 8 ? 8 : applicantUid.length) : "-"}…',
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: Colors.deepPurple)
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
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: _selectedApp == null
                ? const Text(
              '上のリストから案件を選択してください',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
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
                        decoration: const InputDecoration(
                          labelText: '金額（円）',
                          hintText: '例: 12000',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '支払い確定日',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(
                            _pickedDate == null ? '選択' : _ymd(_pickedDate!),
                            style: TextStyle(
                              color: _pickedDate == null ? Colors.black45 : Colors.black87,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _saving ? '登録中...' : '支払い確定を登録（earnings作成）',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '※売上は支払い確定日に反映されます（タイミー方式）',
                  style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
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
    final name = (m['projectNameSnapshot'] ?? m['jobTitleSnapshot'] ?? '案件').toString();
    final uid = (m['applicantUid'] ?? '').toString();
    final status = (m['status'] ?? '').toString();

    String short(String s) => s.isEmpty ? '-' : (s.length <= 10 ? s : '${s.substring(0, 10)}…');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('appId: ${short(app.id)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
          Text('applicantUid: ${short(uid)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
          Text('status: $status',
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
