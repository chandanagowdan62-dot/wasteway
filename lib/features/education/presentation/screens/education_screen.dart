import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/education_provider.dart';
import '../../../passport/presentation/providers/passport_provider.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final Set<String> _expandedArticleIds = {};

  final List<String> _categories = [
    'All',
    'Waste Segregation',
    'Plastics & Polymers',
    'E-Waste & Batteries',
    'Paper, Glass & Metals',
    'Organic & Composting',
    'Textiles & Fashion',
    'Food Waste',
    'Reusable Packaging',
    'Hazardous Waste',
  ];

  @override
  Widget build(BuildContext context) {
    final eduProvider = context.watch<EducationProvider>();
    final articles = eduProvider.filteredArticles;
    final currentQ = eduProvider.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Awareness & Education Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'Responsible Waste Management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Practical guides, Indian SWM rules, material segregation do\'s and don\'ts, and interactive quizzes.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Learning Progress Bar
            Row(
              children: [
                Expanded(
                  child: _ProgressStatCard(
                    icon: Icons.check_circle_outline,
                    color: AppColors.primaryGreen,
                    value: '${eduProvider.completedArticleIds.length} / ${eduProvider.articles.length}',
                    label: 'Topics Completed',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProgressStatCard(
                    icon: Icons.bookmark_border,
                    color: AppColors.secondaryTeal,
                    value: '${eduProvider.savedArticleIds.length}',
                    label: 'Saved Guides',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProgressStatCard(
                    icon: Icons.quiz_outlined,
                    color: Colors.purple,
                    value: '${eduProvider.score} / ${eduProvider.quizQuestions.length}',
                    label: 'Quiz Score',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Interactive Waste-Management Quiz Card
            EcoCard(
              backgroundColor: const Color(0xFFF3E5F5),
              border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.quiz, color: Colors.purple, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Segregation Mastery Quiz',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(
                        label: 'Score: ${eduProvider.score} / ${eduProvider.quizQuestions.length}',
                        color: Colors.purple,
                        isFilled: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!eduProvider.quizCompleted && currentQ != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${eduProvider.currentQuestionIndex + 1} of ${eduProvider.quizQuestions.length}',
                          style: TextStyle(fontSize: 12, color: Colors.purple[800], fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            currentQ.category,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentQ.question,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ...currentQ.options.asMap().entries.map((entry) {
                      final optionIdx = entry.key;
                      final optionText = entry.value;
                      final isSelected = eduProvider.selectedAnswerIndex == optionIdx;
                      final hasAnswered = eduProvider.selectedAnswerIndex != null;
                      final isCorrect = optionIdx == currentQ.correctIndex;

                      Color buttonColor = Colors.white;
                      Color borderColor = const Color(0xFFD1C4E9);
                      if (hasAnswered) {
                        if (isCorrect) {
                          buttonColor = const Color(0xFFE8F5E9);
                          borderColor = AppColors.primaryGreen;
                        } else if (isSelected) {
                          buttonColor = const Color(0xFFFFEBEE);
                          borderColor = AppColors.alertRed;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: hasAnswered ? null : () => eduProvider.selectOption(optionIdx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: buttonColor,
                              border: Border.all(color: borderColor, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${String.fromCharCode(65 + optionIdx)}.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: hasAnswered && isCorrect ? AppColors.primaryGreen : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (hasAnswered && isCorrect)
                                  const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 18)
                                else if (hasAnswered && isSelected)
                                  const Icon(Icons.cancel, color: AppColors.alertRed, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (eduProvider.selectedAnswerIndex != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withAlpha(40)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                currentQ.explanation,
                                style: TextStyle(fontSize: 12, color: Colors.purple[900], height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: eduProvider.nextQuestion,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          child: Text(
                            eduProvider.currentQuestionIndex == eduProvider.quizQuestions.length - 1
                                ? 'Finish Quiz'
                                : 'Next Question',
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Completed Quiz State
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 48),
                            const SizedBox(height: 8),
                            const Text(
                              'Quiz Completed!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You scored ${eduProvider.score} out of ${eduProvider.quizQuestions.length} (${((eduProvider.score / eduProvider.quizQuestions.length) * 100).toInt()}%)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: eduProvider.resetQuiz,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retake Quiz'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search guides, tips, do\'s and don\'ts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: eduProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => eduProvider.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: eduProvider.setSearchQuery,
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: const Icon(Icons.bookmark, size: 14),
                      label: const Text('Saved'),
                      selected: eduProvider.showSavedOnly,
                      selectedColor: AppColors.secondaryTeal.withAlpha(30),
                      onSelected: (val) => eduProvider.toggleShowSavedOnly(val),
                    ),
                  ),
                  ..._categories.map((cat) {
                    final isSel = eduProvider.selectedCategory == cat && !eduProvider.showSavedOnly;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: AppColors.primaryGreen.withAlpha(30),
                        onSelected: (val) {
                          if (val) {
                            eduProvider.toggleShowSavedOnly(false);
                            eduProvider.setCategoryFilter(cat);
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Articles Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${articles.length} Educational Guides',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (eduProvider.searchQuery.isNotEmpty ||
                    eduProvider.selectedCategory != 'All' ||
                    eduProvider.showSavedOnly)
                  TextButton(
                    onPressed: eduProvider.clearFilters,
                    child: const Text('Reset Filters'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Articles List
            if (articles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      const Text(
                        'No matching guides found.',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try clearing your search or category filters.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: eduProvider.clearFilters,
                        child: const Text('Show All Guides'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...articles.map((article) {
                final isExpanded = _expandedArticleIds.contains(article.id);
                final isSaved = eduProvider.isArticleSaved(article.id);
                final isCompleted = eduProvider.isArticleCompleted(article.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: EcoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Article Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.iconEmoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen.withAlpha(20),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          article.category,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        article.readTime,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    article.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      color: isCompleted ? Colors.grey[600] : const Color(0xFF1E2220),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: isSaved ? AppColors.secondaryTeal : Colors.grey,
                                size: 22,
                              ),
                              tooltip: isSaved ? 'Remove Bookmark' : 'Bookmark Guide',
                              onPressed: () => eduProvider.toggleSaveArticle(article.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Regional / Location Notice if applicable
                        if (article.isLocationSpecific && article.regionalNotice != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Color(0xFF1565C0)),
                                const SizedBox(width: 4),
                                Text(
                                  article.regionalNotice!,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Summary
                        Text(
                          article.summary,
                          style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.35),
                        ),

                        // Expandable Details (Content, Tips, Do's & Don'ts)
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            article.content,
                            style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
                          ),
                          const SizedBox(height: 14),

                          // Do's and Don'ts Grid
                          if (article.dos.isNotEmpty || article.donts.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBF9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE0E5E2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Material Do\'s & Don\'ts',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  ...article.dos.map((d) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.check, size: 14, color: AppColors.primaryGreen),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(d, style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20))),
                                            ),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 4),
                                  ...article.donts.map((d) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.close, size: 14, color: AppColors.alertRed),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(d, style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C))),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Common Mistakes to Avoid
                          if (article.commonMistakes.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.report_problem_outlined, size: 14, color: Colors.amber[900]),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Common Mistake to Avoid:',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown[900]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...article.commonMistakes.map((m) => Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text('• $m', style: TextStyle(fontSize: 12, color: Colors.brown[800])),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Connected Passport / Circularity Link
                          if (article.targetMaterial != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final passportProvider = context.read<PassportProvider>();
                                      final matches = passportProvider.passports.where(
                                        (p) => p.primaryMaterial.toLowerCase().contains(article.targetMaterial!.toLowerCase()),
                                      );
                                      if (matches.isNotEmpty) {
                                        passportProvider.setActivePassport(matches.first);
                                        context.push(RouteNames.passportDetail);
                                      } else {
                                        context.go(RouteNames.passports);
                                      }
                                    },
                                    icon: const Icon(Icons.assignment_outlined, size: 16),
                                    label: Text('Passports for ${article.targetMaterial}'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],

                        const SizedBox(height: 10),

                        // Footer Buttons: Expand / Collapse and Mark Completed
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedArticleIds.remove(article.id);
                                  } else {
                                    _expandedArticleIds.add(article.id);
                                  }
                                });
                              },
                              icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18),
                              label: Text(isExpanded ? 'Show Less' : 'Read Full Guide & Tips'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => eduProvider.toggleCompleteArticle(article.id),
                              icon: Icon(
                                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                size: 16,
                                color: isCompleted ? AppColors.primaryGreen : Colors.grey,
                              ),
                              label: Text(
                                isCompleted ? 'Completed' : 'Mark Done',
                                style: TextStyle(
                                  color: isCompleted ? AppColors.primaryGreen : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isCompleted ? AppColors.primaryGreen : Colors.grey[400]!),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _ProgressStatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E5E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
