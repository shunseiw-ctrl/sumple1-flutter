import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/router/route_paths.dart';

class AdminJobManagementTab extends StatefulWidget {
  const AdminJobManagementTab({super.key});

  @override
  State<AdminJobManagementTab> createState() => _AdminJobManagementTabState();
}

class _AdminJobManagementTabState extends State<AdminJobManagementTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  int _limit = 20;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'タイトル・場所で検索',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          // ステータスフィルタチップ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'すべて', value: 'all', selected: _statusFilter, onSelected: (v) => setState(() => _statusFilter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '公開中', value: 'active', selected: _statusFilter, onSelected: (v) => setState(() => _statusFilter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '完了', value: 'completed', selected: _statusFilter, onSelected: (v) => setState(() => _statusFilter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '下書き', value: 'draft', selected: _statusFilter, onSelected: (v) => setState(() => _statusFilter = v)),
                ],
              ),
            ),
          ),
          // 求人リスト
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .orderBy('createdAt', descending: true)
                  .limit(_limit)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        const Text(
                          'データの読み込みに失敗しました',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}'.contains('permission-denied')
                              ? '権限がありません'
                              : 'ネットワーク接続を確認してください',
                          style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                var docs = snap.data?.docs ?? [];

                // クライアントサイドフィルタ
                if (_statusFilter != 'all') {
                  docs = docs.where((doc) {
                    final status = (doc.data()['status'] ?? 'active').toString();
                    return status == _statusFilter;
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    final location = (data['location'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || location.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_off_outlined, size: 48, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          '案件がまだありません',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '右下のボタンから案件を投稿できます',
                          style: TextStyle(fontSize: 13, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: docs.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == docs.length) {
                      if ((snap.data?.docs.length ?? 0) >= _limit) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _limit += 20),
                              child: const Text('もっと見る'),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final doc = docs[index];
                    final data = doc.data();
                    final title = (data['title'] ?? 'タイトルなし').toString();
                    final location = (data['location'] ?? '').toString();
                    final price = data['price'];
                    final date = (data['date'] ?? '').toString();

                    return _JobCard(
                      jobId: doc.id,
                      title: title,
                      location: location,
                      price: price is int ? price : int.tryParse(price.toString()) ?? 0,
                      date: date,
                      onTap: () {
                        context.push(RoutePaths.jobDetailPath(doc.id), extra: data);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RoutePaths.postJob);
        },
        backgroundColor: AppColors.ruri,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('案件を投稿', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ruriPale : AppColors.chipUnselected,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: AppColors.ruri, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.ruri : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String jobId;
  final String title;
  final String location;
  final int price;
  final String date;
  final VoidCallback onTap;

  const _JobCard({
    required this.jobId,
    required this.title,
    required this.location,
    required this.price,
    required this.date,
    required this.onTap,
  });

  String _formatPrice(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return '\u00a5${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ruriPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work, color: AppColors.ruri, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            location.isNotEmpty ? location : '場所未設定',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.event, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          date.isNotEmpty ? date : '未定',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 応募者数表示
                    _ApplicationCount(jobId: jobId),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatPrice(price),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationCount extends StatelessWidget {
  final String jobId;
  const _ApplicationCount({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Row(
          children: [
            const Icon(Icons.people, size: 14, color: AppColors.ruri),
            const SizedBox(width: 4),
            Text(
              '応募者 $count人',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ruri,
              ),
            ),
          ],
        );
      },
    );
  }
}
