/// Structured model representing an educational guide or learning card
class EducationArticleModel {
  final String id;
  final String title;
  final String category;
  final String readTime;
  final String summary;
  final String content;
  final List<String> practicalTips;
  final List<String> commonMistakes;
  final List<String> dos;
  final List<String> donts;
  final String circularityOption; // e.g. Reuse, Repair, Recycle, Donate, Return, Compost, Safe Disposal
  final String iconEmoji;
  final bool isLocationSpecific;
  final String? regionalNotice;
  final String? targetMaterial;

  const EducationArticleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.summary,
    required this.content,
    this.practicalTips = const [],
    this.commonMistakes = const [],
    this.dos = const [],
    this.donts = const [],
    required this.circularityOption,
    required this.iconEmoji,
    this.isLocationSpecific = false,
    this.regionalNotice,
    this.targetMaterial,
  });

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();

    if (title.toLowerCase().contains(q)) return true;
    if (category.toLowerCase().contains(q)) return true;
    if (summary.toLowerCase().contains(q)) return true;
    if (content.toLowerCase().contains(q)) return true;
    if (practicalTips.any((t) => t.toLowerCase().contains(q))) return true;

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'readTime': readTime,
      'summary': summary,
      'content': content,
      'practicalTips': practicalTips,
      'commonMistakes': commonMistakes,
      'dos': dos,
      'donts': donts,
      'circularityOption': circularityOption,
      'iconEmoji': iconEmoji,
      'isLocationSpecific': isLocationSpecific,
      'regionalNotice': regionalNotice,
      'targetMaterial': targetMaterial,
    };
  }

  factory EducationArticleModel.fromJson(Map<String, dynamic> json) {
    return EducationArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      readTime: json['readTime'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      practicalTips: List<String>.from(json['practicalTips'] as List? ?? []),
      commonMistakes: List<String>.from(json['commonMistakes'] as List? ?? []),
      dos: List<String>.from(json['dos'] as List? ?? []),
      donts: List<String>.from(json['donts'] as List? ?? []),
      circularityOption: json['circularityOption'] as String? ?? 'Recycle',
      iconEmoji: json['iconEmoji'] as String? ?? '📖',
      isLocationSpecific: json['isLocationSpecific'] as bool? ?? false,
      regionalNotice: json['regionalNotice'] as String?,
      targetMaterial: json['targetMaterial'] as String?,
    );
  }
}

/// Model representing a waste-management mastery quiz question
class QuizQuestionModel {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestionModel({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] as String,
      category: json['category'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: (json['correctIndex'] as num).toInt(),
      explanation: json['explanation'] as String,
    );
  }
}
