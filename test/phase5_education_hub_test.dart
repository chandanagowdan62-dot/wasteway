import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/features/education/domain/models/education_article_model.dart';
import 'package:wasteway/features/education/presentation/providers/education_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5: EducationArticleModel Unit Tests', () {
    test('JSON serialization round-trip preservation', () {
      const article = EducationArticleModel(
        id: 'EDU-TEST-01',
        title: 'Composting Basics',
        category: 'Organic & Composting',
        readTime: '3 min read',
        summary: 'Learn green and brown composting ratios.',
        content: 'Composting aerobically prevents landfill methane emissions.',
        practicalTips: ['Add dry leaves', 'Turn weekly'],
        commonMistakes: ['Adding plastic bags'],
        dos: ['Chop vegetable peels'],
        donts: ['Do not add cooked meat'],
        circularityOption: 'Compost',
        iconEmoji: '🌱',
        isLocationSpecific: true,
        regionalNotice: 'Indian SWM 2016 Compliant',
        targetMaterial: 'Biodegradable / Organic',
      );

      final json = article.toJson();
      final revived = EducationArticleModel.fromJson(json);

      expect(revived.id, article.id);
      expect(revived.title, article.title);
      expect(revived.dos.length, 1);
      expect(revived.donts.length, 1);
      expect(revived.practicalTips.length, 2);
      expect(revived.isLocationSpecific, isTrue);
      expect(revived.targetMaterial, 'Biodegradable / Organic');
    });

    test('matchesSearch performs case-insensitive lookup across fields', () {
      const article = EducationArticleModel(
        id: 'EDU-TEST-02',
        title: 'Plastic Resin Codes',
        category: 'Plastics & Polymers',
        readTime: '4 min read',
        summary: 'Understanding PET and HDPE recovery.',
        content: 'Type 1 and Type 2 are widely mechanically recycled.',
        practicalTips: ['Look for the number inside chasing arrows'],
        circularityOption: 'Recycle',
        iconEmoji: '🧴',
      );

      expect(article.matchesSearch('resin'), isTrue);
      expect(article.matchesSearch('hdpe'), isTrue);
      expect(article.matchesSearch('chasing arrows'), isTrue);
      expect(article.matchesSearch('irrelevant_term'), isFalse);
    });
  });

  group('Phase 5: EducationProvider & Quiz Flow Tests', () {
    late EducationProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = EducationProvider();
    });

    test('Contains articles across all 9 approved waste categories', () {
      final categories = provider.articles.map((a) => a.category).toSet();

      expect(categories.any((c) => c.contains('Waste Segregation')), isTrue);
      expect(categories.any((c) => c.contains('Plastics')), isTrue);
      expect(categories.any((c) => c.contains('E-Waste')), isTrue);
      expect(categories.any((c) => c.contains('Paper, Glass & Metals')), isTrue);
      expect(categories.any((c) => c.contains('Organic & Composting')), isTrue);
      expect(categories.any((c) => c.contains('Textiles')), isTrue);
      expect(categories.any((c) => c.contains('Food Waste')), isTrue);
      expect(categories.any((c) => c.contains('Reusable Packaging')), isTrue);
      expect(categories.any((c) => c.contains('Hazardous Waste')), isTrue);
    });

    test('Filters educational articles by category and search keyword', () {
      provider.setCategoryFilter('E-Waste & Batteries');
      final eWasteArticles = provider.filteredArticles;

      expect(eWasteArticles.isNotEmpty, isTrue);
      expect(eWasteArticles.every((a) => a.category.contains('E-Waste')), isTrue);

      provider.clearFilters();
      provider.setSearchQuery('methane');
      final methaneArticles = provider.filteredArticles;

      expect(methaneArticles.isNotEmpty, isTrue);
    });

    test('Retrieves relevant educational guides for specific passport materials', () {
      final plasticGuides = provider.getArticlesForMaterial('Plastic');
      expect(plasticGuides.isNotEmpty, isTrue);
      expect(plasticGuides.any((a) => a.targetMaterial == 'Plastic'), isTrue);

      final eWasteGuides = provider.getArticlesForMaterial('Electronic Waste (E-Waste)');
      expect(eWasteGuides.isNotEmpty, isTrue);
      expect(eWasteGuides.any((a) => a.targetMaterial == 'Electronic Waste (E-Waste)'), isTrue);
    });

    test('Toggles saved bookmark and completed status', () async {
      const articleId = 'EDU-SEG-01';

      expect(provider.isArticleSaved(articleId), isFalse);
      expect(provider.isArticleCompleted(articleId), isFalse);

      await provider.toggleSaveArticle(articleId);
      expect(provider.isArticleSaved(articleId), isTrue);

      await provider.toggleCompleteArticle(articleId);
      expect(provider.isArticleCompleted(articleId), isTrue);

      // Verify showSavedOnly filter
      provider.toggleShowSavedOnly(true);
      final savedOnly = provider.filteredArticles;
      expect(savedOnly.every((a) => a.id == articleId), isTrue);

      // Untoggle bookmark
      await provider.toggleSaveArticle(articleId);
      expect(provider.isArticleSaved(articleId), isFalse);
    });

    test('Interactive quiz handles option selection, scoring and progression', () {
      expect(provider.quizQuestions.isNotEmpty, isTrue);
      expect(provider.score, 0);
      expect(provider.currentQuestionIndex, 0);
      expect(provider.quizCompleted, isFalse);

      final firstQ = provider.currentQuestion!;
      final correctIdx = firstQ.correctIndex;

      // Select correct option
      provider.selectOption(correctIdx);
      expect(provider.score, 1);
      expect(provider.selectedAnswerIndex, correctIdx);

      // Advance to question 2
      provider.nextQuestion();
      expect(provider.currentQuestionIndex, 1);
      expect(provider.selectedAnswerIndex, isNull);

      // Select incorrect option on second question
      final secondQ = provider.currentQuestion!;
      final wrongIdx = (secondQ.correctIndex + 1) % secondQ.options.length;
      provider.selectOption(wrongIdx);
      expect(provider.score, 1); // score remains 1

      // Reset quiz
      provider.resetQuiz();
      expect(provider.currentQuestionIndex, 0);
      expect(provider.score, 0);
      expect(provider.quizCompleted, isFalse);
    });
  });
}
