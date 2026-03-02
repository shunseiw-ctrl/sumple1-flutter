import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class FavoritesPage extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? firebaseAuth;

  const FavoritesPage({super.key, this.firestore, this.firebaseAuth});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final FirebaseFirestore _db;
  late final FirebaseAuth _auth;
  Map<String, Map<String, dynamic>> _jobsCache = {};
  List<String> _lastJobIds = [];
  bool _isLoadingJobs = false;

  @override
  void initState() {
    super.initState();
    _db = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.firebaseAuth ?? FirebaseAuth.instance;
    AnalyticsService.logScreenView('favorites');
  }

  Future<void> _fetchJobs(List<String> jobIds) async {
    if (jobIds.isEmpty) {
      setState(() {
        _jobsCache = {};
        _lastJobIds = [];
      });
      return;
    }

    if (_listEquals(jobIds, _lastJobIds) && _jobsCache.isNotEmpty) return;

    setState(() => _isLoadingJobs = true);
    try {
      final result = <String, Map<String, dynamic>>{};
      const batchSize = 30;
      for (var i = 0; i < jobIds.length; i += batchSize) {
        final batch =
            jobIds.sublist(i, (i + batchSize).clamp(0, jobIds.length));
        final snap = await _db
            .collection('jobs')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snap.docs) {
          result[doc.id] = doc.data();
        }
      }
      if (mounted) {
        setState(() {
          _jobsCache = result;
          _lastJobIds = List.of(jobIds);
          _isLoadingJobs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingJobs = false);
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('お気に入り案件'),
          centerTitle: true,
        ),
        body: const Center(child: Text('ログインが必要です')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('お気に入り案件'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('favorites').doc(uid).snapshots(),
        builder: (context, favSnap) {
          if (favSnap.connectionState == ConnectionState.waiting) {
            return const SkeletonList();
          }

          final favData = favSnap.data?.data();
          final jobIds = List<String>.from(favData?['jobIds'] ?? []);

          if (jobIds.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'お気に入りはまだありません',
              description: '案件の♡をタップして追加できます',
            );
          }

          // jobIds変更時にバッチ取得
          if (!_listEquals(jobIds, _lastJobIds)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchJobs(jobIds);
            });
          }

          if (_isLoadingJobs && _jobsCache.isEmpty) {
            return const SkeletonList();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _lastJobIds = [];
              await _fetchJobs(jobIds);
            },
            color: AppColors.ruri,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: AppConstants.listCacheExtent,
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              itemCount: jobIds.length,
              itemBuilder: (context, i) {
                final jobId = jobIds[i];
                final job = _jobsCache[jobId];
                if (job == null) return const SizedBox.shrink();

                final title = (job['title'] ?? 'タイトルなし').toString();
                final location = (job['location'] ?? '').toString();
                final price = (job['price'] ?? '').toString();
                final date = (job['date'] ?? '').toString();
                final imageUrl = (job['imageUrl'] ?? '').toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: AppShadows.card,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        onTap: () {
                          context.push(RoutePaths.jobDetailPath(jobId),
                              extra: job);
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft:
                                    Radius.circular(AppSpacing.cardRadius),
                                bottomLeft:
                                    Radius.circular(AppSpacing.cardRadius),
                              ),
                              child: SizedBox(
                                width: 100,
                                height: 90,
                                child: imageUrl.isNotEmpty
                                    ? AppCachedImage(
                                        imageUrl: imageUrl,
                                        width: 100,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.chipUnselected,
                                        child: const Icon(Icons.work,
                                            color: AppColors.textHint),
                                      ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: AppTextStyles.labelLarge
                                            .copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: AppSpacing.xs),
                                    if (location.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: AppColors.textHint),
                                          const SizedBox(
                                              width: AppSpacing.xs),
                                          Expanded(
                                              child: Text(location,
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                          color: AppColors
                                                              .textSecondary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis)),
                                        ],
                                      ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        if (price.isNotEmpty)
                                          Text('¥$price',
                                              style: AppTextStyles.salary
                                                  .copyWith(fontSize: 14)),
                                        const Spacer(),
                                        if (date.isNotEmpty)
                                          Text(date,
                                              style:
                                                  AppTextStyles.labelSmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: AppSpacing.sm),
                              child: IconButton(
                                icon: const Icon(Icons.favorite,
                                    color: Colors.red, size: 22),
                                onPressed: () async {
                                  await _db
                                      .collection('favorites')
                                      .doc(uid)
                                      .update({
                                    'jobIds':
                                        FieldValue.arrayRemove([jobId]),
                                    'updatedAt':
                                        FieldValue.serverTimestamp(),
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
