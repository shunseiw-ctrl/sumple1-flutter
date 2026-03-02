import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/job_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('JobCard', () {
    Widget buildCard({
      String title = 'テスト案件タイトル',
      String location = '東京都渋谷区',
      String dateText = '2026-04-01',
      String priceText = '¥15000',
      String? imageUrl,
      String? category,
      List<BadgeSpec> badges = const [],
      bool showLegacyWarning = false,
      Map<String, dynamic> data = const {'slots': '5', 'applicantCount': '0'},
      bool isOwner = false,
      bool isFavorite = false,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
      VoidCallback? onToggleFavorite,
      String? heroTag,
    }) {
      return buildTestApp(
        SingleChildScrollView(
          child: JobCard(
            title: title,
            location: location,
            dateText: dateText,
            priceText: priceText,
            imageUrl: imageUrl,
            category: category,
            badges: badges,
            showLegacyWarning: showLegacyWarning,
            data: data,
            isOwner: isOwner,
            isFavorite: isFavorite,
            onTap: onTap ?? () {},
            onEdit: onEdit,
            onDelete: onDelete,
            onToggleFavorite: onToggleFavorite,
            heroTag: heroTag,
          ),
        ),
      );
    }

    testWidgets('displays title correctly', (tester) async {
      await tester.pumpWidget(buildCard(title: '足場組立の案件'));
      await tester.pump();

      expect(find.text('足場組立の案件'), findsOneWidget);
    });

    testWidgets('displays location correctly', (tester) async {
      await tester.pumpWidget(buildCard(location: '神奈川県横浜市'));
      await tester.pump();

      expect(find.text('神奈川県横浜市'), findsOneWidget);
    });

    testWidgets('displays price correctly', (tester) async {
      await tester.pumpWidget(buildCard(priceText: '¥20000'));
      await tester.pump();

      expect(find.text('¥20000'), findsOneWidget);
      expect(find.text(' /日'), findsOneWidget);
    });

    testWidgets('shows correct favorite icon based on isFavorite', (tester) async {
      // Not favorite - shows border icon
      await tester.pumpWidget(buildCard(isFavorite: false));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);

      // Favorite - shows filled icon
      await tester.pumpWidget(buildCard(isFavorite: true));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('shows placeholder image when imageUrl is null', (tester) async {
      await tester.pumpWidget(buildCard(imageUrl: null, category: '解体'));
      await tester.pump();

      // The placeholder uses categoryIcon - for '解体' it's Icons.handyman
      expect(find.byIcon(Icons.handyman), findsWidgets);
    });
  });

  group('JobCard.categoryIcon', () {
    test('returns correct icon for known categories', () {
      expect(JobCard.categoryIcon('解体'), Icons.handyman);
      expect(JobCard.categoryIcon('内装'), Icons.format_paint);
      expect(JobCard.categoryIcon('外壁'), Icons.home_work);
      expect(JobCard.categoryIcon('電気'), Icons.electrical_services);
      expect(JobCard.categoryIcon('配管'), Icons.plumbing);
      expect(JobCard.categoryIcon('土木'), Icons.landscape);
      expect(JobCard.categoryIcon('塗装'), Icons.brush);
    });

    test('returns construction icon for unknown category', () {
      expect(JobCard.categoryIcon(null), Icons.construction);
      expect(JobCard.categoryIcon('不明'), Icons.construction);
    });
  });

  group('BadgeSpec', () {
    test('creates with required fields', () {
      const badge = BadgeSpec(
        label: 'テスト',
        bg: Colors.blue,
        fg: Colors.white,
      );
      expect(badge.label, 'テスト');
      expect(badge.bg, Colors.blue);
      expect(badge.fg, Colors.white);
    });
  });

  group('JobCard Hero', () {
    Widget buildCard({
      String? imageUrl,
      String? heroTag,
    }) {
      return buildTestApp(
        SingleChildScrollView(
          child: JobCard(
            title: 'テスト',
            location: '東京',
            dateText: '2026-04-01',
            priceText: '¥15000',
            imageUrl: imageUrl,
            badges: const [],
            showLegacyWarning: false,
            data: const {'slots': '5', 'applicantCount': '0'},
            isOwner: false,
            onTap: () {},
            onEdit: null,
            onDelete: null,
            heroTag: heroTag,
          ),
        ),
      );
    }

    testWidgets('画像ありJobCardにheroTag指定でHero widgetが存在', (tester) async {
      await tester.pumpWidget(buildCard(
        imageUrl: 'https://example.com/test.jpg',
        heroTag: 'hero-job-image-abc123',
      ));
      await tester.pump();

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('Heroタグがjob IDを含む', (tester) async {
      await tester.pumpWidget(buildCard(
        imageUrl: 'https://example.com/test.jpg',
        heroTag: 'hero-job-image-abc123',
      ));
      await tester.pump();

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'hero-job-image-abc123');
    });

    testWidgets('画像なしJobCardにHeroなし', (tester) async {
      await tester.pumpWidget(buildCard(
        imageUrl: null,
        heroTag: 'hero-job-image-abc123',
      ));
      await tester.pump();

      expect(find.byType(Hero), findsNothing);
    });
  });
}
