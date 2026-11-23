import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/education_article_model.dart';

class EducationProvider extends ChangeNotifier {
  static const String _prefSavedArticles = 'wasteway_saved_articles';
  static const String _prefCompletedArticles = 'wasteway_completed_articles';

  final List<EducationArticleModel> _articles = [];
  final List<QuizQuestionModel> _quizQuestions = [];

  final Set<String> _savedArticleIds = {};
  final Set<String> _completedArticleIds = {};

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showSavedOnly = false;

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  int? _selectedAnswerIndex;

  List<EducationArticleModel> get articles => List.unmodifiable(_articles);
  List<QuizQuestionModel> get quizQuestions => List.unmodifiable(_quizQuestions);
  Set<String> get savedArticleIds => Set.unmodifiable(_savedArticleIds);
  Set<String> get completedArticleIds => Set.unmodifiable(_completedArticleIds);

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get showSavedOnly => _showSavedOnly;

  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  bool get quizCompleted => _quizCompleted;
  int? get selectedAnswerIndex => _selectedAnswerIndex;

  QuizQuestionModel? get currentQuestion =>
      _quizQuestions.isNotEmpty && _currentQuestionIndex < _quizQuestions.length
          ? _quizQuestions[_currentQuestionIndex]
          : null;

  EducationProvider() {
    _seedArticles();
    _seedQuiz();
    _loadUserProgress();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleShowSavedOnly(bool val) {
    _showSavedOnly = val;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _showSavedOnly = false;
    notifyListeners();
  }

  bool isArticleSaved(String id) => _savedArticleIds.contains(id);
  bool isArticleCompleted(String id) => _completedArticleIds.contains(id);

  Future<void> toggleSaveArticle(String id) async {
    if (_savedArticleIds.contains(id)) {
      _savedArticleIds.remove(id);
    } else {
      _savedArticleIds.add(id);
    }
    notifyListeners();
    await _persistProgress();
  }

  Future<void> toggleCompleteArticle(String id) async {
    if (_completedArticleIds.contains(id)) {
      _completedArticleIds.remove(id);
    } else {
      _completedArticleIds.add(id);
    }
    notifyListeners();
    await _persistProgress();
  }

  List<EducationArticleModel> get filteredArticles {
    return _articles.where((article) {
      if (_showSavedOnly && !_savedArticleIds.contains(article.id)) {
        return false;
      }
      if (_selectedCategory != 'All' &&
          !article.category.toLowerCase().contains(_selectedCategory.toLowerCase())) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty && !article.matchesSearch(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<EducationArticleModel> getArticlesForMaterial(String materialName) {
    final lower = materialName.toLowerCase().trim();
    return _articles.where((a) {
      final target = a.targetMaterial?.toLowerCase() ?? '';
      return target.contains(lower) || lower.contains(target) || a.category.toLowerCase().contains(lower);
    }).toList();
  }

  void selectOption(int index) {
    if (_selectedAnswerIndex != null) return;
    _selectedAnswerIndex = index;
    if (index == currentQuestion?.correctIndex) {
      _score++;
    }
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      _currentQuestionIndex++;
      _selectedAnswerIndex = null;
    } else {
      _quizCompleted = true;
    }
    notifyListeners();
  }

  void resetQuiz() {
    _currentQuestionIndex = 0;
    _score = 0;
    _quizCompleted = false;
    _selectedAnswerIndex = null;
    notifyListeners();
  }

  Future<void> _persistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefSavedArticles, _savedArticleIds.toList());
      await prefs.setStringList(_prefCompletedArticles, _completedArticleIds.toList());
    } catch (e) {
      debugPrint('Error saving educational progress: $e');
    }
  }

  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefSavedArticles);
      final completed = prefs.getStringList(_prefCompletedArticles);
      if (saved != null) _savedArticleIds.addAll(saved);
      if (completed != null) _completedArticleIds.addAll(completed);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading educational progress: $e');
    }
  }

  void _seedArticles() {
    _articles.addAll([
      // 1. Waste Segregation & Identification
      const EducationArticleModel(
        id: 'EDU-SEG-01',
        title: 'Mastering Indian 3-Bin Source Segregation (SWM 2016)',
        category: 'Waste Segregation',
        readTime: '4 min read',
        summary: 'Understand the Green, Blue, and Red bins under the Solid Waste Management Rules 2016.',
        content: 'Source segregation is the critical first step in waste recovery. Mixing wet kitchen waste with dry paper or plastic coats recyclables in organic moisture, rendering entire truckloads un-recyclable and forcing them into landfills. Under Indian Solid Waste Management Rules 2016, households must segregate at source into Green (Wet/Biodegradable), Blue (Dry Recyclables), and Red (Domestic Hazardous/Sanitary).',
        practicalTips: [
          'Keep two distinct bins in the kitchen: Green for peels and scraps, Blue for washed milk pouches and dry cartons.',
          'Always rinse and air-dry plastic food containers and milk pouches before dropping into the Blue bin.',
          'Wrap sanitary napkins or diapers securely in newspaper marked with a red cross or "X" symbol.'
        ],
        commonMistakes: [
          'Placing biodegradable food scraps in single-use plastic trash bags inside the green bin.',
          'Throwing greasy pizza boxes into paper recycling instead of tearing greasy portions for composting.'
        ],
        dos: [
          'Wash and completely dry plastic milk packets before disposal',
          'Use newspaper lining or compostable starch bags for the wet bin',
          'Fold cardboard boxes flat to save dry bin collection volume'
        ],
        donts: [
          'Do NOT mix medical syringes, expired medicines or batteries into dry waste',
          'Do NOT put soiled paper napkins into dry recyclables',
          'Do NOT tie wet garbage in non-biodegradable polythene bags'
        ],
        circularityOption: 'Recycle',
        iconEmoji: '♻️',
        isLocationSpecific: true,
        regionalNotice: 'Compliant with Indian Solid Waste Management (SWM) Rules 2016',
        targetMaterial: 'Plastic',
      ),

      // 2. Plastics & Resin Identification Codes
      const EducationArticleModel(
        id: 'EDU-PLA-02',
        title: 'Decoding Resin Identification Codes: Plastics 1 to 7',
        category: 'Plastics & Polymers',
        readTime: '5 min read',
        summary: 'What the chasing arrow numbers mean: PET, HDPE, PVC, LDPE, PP, PS and Multi-layers.',
        content: 'The number inside the chasing arrows triangle is not a recyclability guarantee; it is an industrial Resin Identification Code (RIC). Type 1 (PET) and Type 2 (HDPE) possess established mechanical recovery networks. Types 3 (PVC) and 7 (Multi-layer Packaging) contain mixed plastic polymers or plasticizers that contaminate standard mechanical pelletization pipelines.',
        practicalTips: [
          'Look at the bottom of bottles and containers for the embossed number inside the triangle.',
          'Type 1 (PET water/beverage bottles) and Type 2 (HDPE shampoo/milk jugs) have high scrap cash value.',
          'Type 5 (PP food tubs and medicine containers) can be recycled if collected in unpigmented streams.'
        ],
        commonMistakes: [
          'Assuming plastic cutlery (often Type 6 Polystyrene) can be recycled with drink bottles.',
          'Mixing thermoformed blister packaging with clear PET bottle bales.'
        ],
        dos: [
          'Crush PET bottles vertically with the cap attached after emptying',
          'Check the number: prioritize buying Type 1 and Type 2 packaging',
          'Separate multi-layered chip packets (Type 7) for energy recovery or road asphalt shredding'
        ],
        donts: [
          'Do NOT burn PVC (Type 3) plastics; it releases lethal chlorine dioxins',
          'Do NOT mix black plastic food takeaway containers into standard clear PET streams'
        ],
        circularityOption: 'Recycle',
        iconEmoji: '🧴',
        targetMaterial: 'Plastic',
      ),

      // 3. E-Waste & Battery Safety
      const EducationArticleModel(
        id: 'EDU-EWA-03',
        title: 'Lithium-Ion Battery Safety & E-Waste Handling',
        category: 'E-Waste & Batteries',
        readTime: '4 min read',
        summary: 'How to handle rechargeable cells, prevent fires, and route through authorized take-back centers.',
        content: 'Electronic waste accounts for over 70% of toxic heavy metals in municipal landfills despite making up only 2% of garbage volume. Lithium-ion batteries present severe thermal runaway fire risks when compressed inside compaction garbage trucks. The Indian E-Waste (Management) Rules mandate Extended Producer Responsibility (EPR) where electronics brands must provide authorized drop-off points.',
        practicalTips: [
          'Cover both positive and negative terminals of dead batteries with clear cello tape before storing.',
          'Store depleted batteries in a cool, non-conductive plastic box away from metal keys or coins.',
          'Take smartphones and laptops to brand authorized service centers during upgrade cycles.'
        ],
        commonMistakes: [
          'Tossing alkaline or button batteries directly into common kitchen waste.',
          'Puncturing swollen lithium-polymer phone batteries with scissors or screwdrivers.'
        ],
        dos: [
          'Tape exposed terminals of all batteries with insulating tape',
          'Hand over circuit boards and power cords to authorized e-waste recyclers',
          'Factory reset and remove data storage drives before donating old laptops'
        ],
        donts: [
          'Do NOT dismantle electronics at home with open flame heating',
          'Do NOT dispose of rechargeable cells in residential trash chutes',
          'Do NOT soak damaged lithium batteries in water'
        ],
        circularityOption: 'Return',
        iconEmoji: '🔋',
        isLocationSpecific: true,
        regionalNotice: 'Mandated by Indian E-Waste (Management) Rules',
        targetMaterial: 'Electronic Waste (E-Waste)',
      ),

      // 4. Paper, Cardboard, Glass & Metal Recovery
      const EducationArticleModel(
        id: 'EDU-MAT-04',
        title: 'Paper, Cardboard, Glass & Metal Circular Loops',
        category: 'Paper, Glass & Metals',
        readTime: '5 min read',
        summary: 'How infinitely recyclable aluminium and clean cardboard repulping preserve national energy.',
        content: 'Aluminium and steel are permanent materials; smelting recycled aluminium cans saves 95% of the energy needed to refine virgin bauxite ore. Paper fibers can be recycled 5 to 7 times before becoming too short for papermaking. Glass can be melted indefinitely without quality loss, but requires color sorting (clear cullet, amber, and green).',
        practicalTips: [
          'Leave pull-tabs attached to beverage cans so they do not fall through sorting screens.',
          'Keep cardboard clean and dry; ungreased cardboard retains high cellulose repulping value.',
          'Separate metal screw caps from glass jam jars before drop-off.'
        ],
        commonMistakes: [
          'Putting mirrors, ceramic coffee mugs, or Pyrex glassware into container glass recycling.',
          'Recycling wet or grease-soaked cardboard alongside dry newspapers.'
        ],
        dos: [
          'Flatten shipping boxes to save transport emissions and space',
          'Rinse beverage cans and jam jars with greywater before binning',
          'Stack clean newspapers in bundles tied with natural jute string'
        ],
        donts: [
          'Do NOT break glass bottles into shards; broken glass injures waste collectors',
          'Do NOT put thermal cash register receipts into paper bins (they contain toxic BPA)'
        ],
        circularityOption: 'Recycle',
        iconEmoji: '🥫',
        targetMaterial: 'Metals',
      ),

      // 5. Organic Waste & Composting
      const EducationArticleModel(
        id: 'EDU-ORG-05',
        title: 'Home Composting: Balancing Green Nitrogen & Brown Carbon',
        category: 'Organic & Composting',
        readTime: '4 min read',
        summary: 'Turn wet kitchen waste into black gold soil conditioner while preventing landfill methane.',
        content: 'Organic waste rotting in anaerobic landfill conditions produces methane, a greenhouse gas 28 times more potent than carbon dioxide. Aerobic home composting eliminates methane by providing oxygen to beneficial microbes. Successful composting relies on a 2:1 balance between Carbon "Browns" (dry leaves, shredded cardboard) and Nitrogen "Greens" (fruit peels, vegetable scraps, tea leaves).',
        practicalTips: [
          'Add a handful of dry crushed leaves or sawdust every time you dump wet kitchen peels.',
          'Turn or aerate the compost pile once a week to introduce oxygen and prevent foul odors.',
          'Keep the compost moisture level like a wrung-out sponge.'
        ],
        commonMistakes: [
          'Adding cooked oily gravies, dairy, or cooked meat into small home aerobic composters.',
          'Neglecting brown carbon layers, leading to wet, smelly anaerobic sludge.'
        ],
        dos: [
          'Chop thick vegetable stalks into small pieces to accelerate microbial breakdown',
          'Include crushed eggshells and coffee grounds for calcium and nitrogen enrichment',
          'Use a terracotta or ventilated composter on balconies or backyards'
        ],
        donts: [
          'Do NOT add non-biodegradable tea bags (many contain heat-sealed plastic mesh)',
          'Do NOT include pet feces or diseased garden plants',
          'Do NOT allow compost to become waterlogged during heavy rains'
        ],
        circularityOption: 'Compost',
        iconEmoji: '🌱',
        targetMaterial: 'Biodegradable / Organic',
      ),

      // 6. Textile Reuse, Repair & Donation
      const EducationArticleModel(
        id: 'EDU-TEX-06',
        title: 'Circular Fashion: Textile Repair, Upcycling & Donation',
        category: 'Textiles & Fashion',
        readTime: '3 min read',
        summary: 'Extending clothing lifespans through visible mending, fabric repurposing, and clean donation.',
        content: 'The textile industry generates 10% of global carbon emissions and vast volumes of non-biodegradable synthetic polyester waste. Extending an item\'s life by just 9 months reduces its carbon, waste, and water footprints by 20 to 30%. When garments reach end-of-life, categorize them for mending, repurposing into cleaning rags, or donating to organized charities.',
        practicalTips: [
          'Learn basic needle and thread stitches to fix loose buttons, hem pants, and repair split seams.',
          'Old cotton t-shirts can be cut into reusable domestic cleaning cloths, eliminating paper towels.',
          'Donate only clean, undamaged garments that you would personally be proud to wear.'
        ],
        commonMistakes: [
          'Donating torn, stained, or unwashed clothes that charity shelters must discard as trash.',
          'Throwing cotton textiles into municipal wet waste bins.'
        ],
        dos: [
          'Wash and completely dry clothes before placing in community donation boxes',
          'Explore local tailor alteration services before replacing ill-fitting garments',
          'Opt for natural fibers like cotton, linen, and wool over synthetic micro-polyester'
        ],
        donts: [
          'Do NOT donate wet or mildewed fabrics',
          'Do NOT dispose of old shoes or leather accessories in compost or recyclables'
        ],
        circularityOption: 'Donate',
        iconEmoji: '👕',
        targetMaterial: 'Textiles',
      ),

      // 7. Food Waste Reduction & Responsible Redistribution
      const EducationArticleModel(
        id: 'EDU-FOO-07',
        title: 'Food Waste Prevention & Responsible Surplus Redistribution',
        category: 'Food Waste',
        readTime: '4 min read',
        summary: 'Plan portions, distinguish "Best Before" from "Use By", and connect surplus to food banks.',
        content: 'Nearly one-third of all food produced globally is wasted. In urban households, food waste primarily stems from over-purchasing and misinterpreting date labels. Understanding that "Best Before" indicates optimal flavor quality rather than safety helps prevent premature disposal. For large social gatherings and institutional cafeterias, surplus unserved food can be routed to verified hunger-relief organizations.',
        practicalTips: [
          'Make a weekly meal plan and shopping list before visiting grocery markets to prevent impulsive over-buying.',
          'Adopt the FIFO (First In, First Out) principle: place newly purchased groceries behind older stock.',
          'Freeze surplus chopped vegetables, bread, and ripe bananas for cooking later.'
        ],
        commonMistakes: [
          'Discarding safe, edible canned or dry goods immediately on the "Best Before" date.',
          'Cooking oversized quantities for dinner parties without surplus redistribution arrangements.'
        ],
        dos: [
          'Store root vegetables (potatoes, onions) in dark, well-ventilated cool baskets',
          'Partner with local food rescue helplines (e.g. Robin Hood Army / Feeding India) for event surplus',
          'Transform leftover cooked rice into fermented curd rice or morning upma'
        ],
        donts: [
          'Do NOT store potatoes and onions in the same basket (onions emit ethylene, causing potato sprouting)',
          'Do NOT leave cooked perishable food unrefrigerated for more than 2 hours'
        ],
        circularityOption: 'Reuse',
        iconEmoji: '🍲',
        targetMaterial: 'Biodegradable / Organic',
      ),

      // 8. Reusable Packaging & Return Systems
      const EducationArticleModel(
        id: 'EDU-PKG-08',
        title: 'Reusable Packaging, Deposit-Refund Schemes & Refill Hubs',
        category: 'Reusable Packaging',
        readTime: '3 min read',
        summary: 'Transitioning from single-use packaging to circular refill loops and manufacturer return systems.',
        content: 'Recycling alone cannot solve the packaging crisis; reuse and refill systems address the root problem by keeping primary containers in closed loops. Deposit-Refund Systems (DRS) incentivize consumers to return beverage bottles and delivery containers in exchange for monetary rebates. Choosing zero-waste grocery stores and bulk refilleries eliminates plastic outer wraps entirely.',
        practicalTips: [
          'Carry collapsible cloth tote bags and reusable stainless steel water bottles wherever you travel.',
          'Support local grocery vendors that allow filling pulses, grains, and oils into your own containers.',
          'Return intact aerated beverage glass bottles to neighborhood kirana stores for cash deposit return.'
        ],
        commonMistakes: [
          'Accepting single-use polythene carry bags for every small vegetable purchase.',
          'Discarding returnable milk and beverage glass bottles with regular dry garbage.'
        ],
        dos: [
          'Keep clean cloth bags in your vehicle or backpack for spontaneous shopping',
          'Ask online delivery platforms to opt out of disposable plastic cutlery and napkins',
          'Return transport crates and bubble wrap to courier branches for secondary packing cycles'
        ],
        donts: [
          'Do NOT throw deposit-return glass bottles into scrap yards when neighborhood stores redeem them',
          'Do NOT treat durable reusable containers as single-use disposable items'
        ],
        circularityOption: 'Return',
        iconEmoji: '📦',
        targetMaterial: 'Glass',
      ),

      // 9. Hazardous Waste Handling & Safe Disposal
      const EducationArticleModel(
        id: 'EDU-HAZ-09',
        title: 'Domestic Hazardous Waste: Chemicals, Paint & Fluorescents',
        category: 'Hazardous Waste',
        readTime: '4 min read',
        summary: 'Containment protocols for pesticide containers, aerosol cans, and mercury CFL tubes.',
        content: 'Domestic hazardous waste constitutes materials that are toxic, flammable, corrosive, or reactive. Improper disposal in household trash or sewer drains contaminates municipal water tables and endangers sanitation workers through chemical burns and poisonous fumes. Intact CFL tube bulbs contain mercury vapor that requires careful handling to prevent breakage.',
        practicalTips: [
          'Never pour leftover paint, motor oil, or household bleach down bathroom sinks or storm drains.',
          'Keep household pesticides and solvents in their original containers with clear hazard warning labels.',
          'If a CFL bulb breaks, ventilate the room for 15 minutes and sweep shards with stiff cardboard, not a vacuum.'
        ],
        commonMistakes: [
          'Incinerating or puncturing aerosol spray cans, which can cause violent shrapnel explosions.',
          'Mixing chlorine bleach with ammonia or acid toilet cleaners, producing deadly chloramine gas.'
        ],
        dos: [
          'Hand over fluorescent tubes and paints directly to municipal periodic hazardous collection depots',
          'Store volatile chemicals tightly sealed in a secure, ventilated utility closet out of children reach',
          'Wear protective rubber gloves when handling leaked battery acid or chemical residues'
        ],
        donts: [
          'Do NOT wash paint brushes under garden taps or storm water gutters',
          'Do NOT puncture pressurized insecticide aerosol cans even when empty',
          'Do NOT pour expired liquid antibiotics or medicines down the toilet'
        ],
        circularityOption: 'Safe Disposal',
        iconEmoji: '⚠️',
        isLocationSpecific: true,
        regionalNotice: 'Mandated by Hazardous and Other Wastes Rules, MoEFCC',
        targetMaterial: 'Hazardous / Chemical',
      ),
    ]);
  }

  void _seedQuiz() {
    _quizQuestions.addAll([
      const QuizQuestionModel(
        id: 'Q-01',
        category: 'Segregation',
        question: 'Under Indian 3-bin rules, in which bin should a rinsed and dried plastic milk pouch be placed?',
        options: [
          'Green Wet-Waste Bin',
          'Blue Dry-Waste Bin',
          'Red Hazardous Waste Bin',
          'Compost Pit'
        ],
        correctIndex: 1,
        explanation: 'Once rinsed free of milk fats and dried, plastic film packets belong in the Blue Dry-Waste bin for mechanical recycling.',
      ),
      const QuizQuestionModel(
        id: 'Q-02',
        category: 'Paper',
        question: 'Why should greasy, oil-soaked cardboard pizza box bases NOT be mixed with paper recycling?',
        options: [
          'Pizza grease is toxic to collection trucks',
          'Oil contaminates the water-based repulping process, causing recycled paper defects',
          'Pizza boxes are made of plastic',
          'They burn too quickly'
        ],
        correctIndex: 1,
        explanation: 'Oil and food grease cannot be separated from paper fibers during water pulping. Greasy portions should be torn and added to composting instead.',
      ),
      const QuizQuestionModel(
        id: 'Q-03',
        category: 'Batteries',
        question: 'What is the most critical preparation precaution before dropping off lithium batteries?',
        options: [
          'Soak the battery in salty water',
          'Insulate positive and negative terminals with non-conductive tape',
          'Puncture the outer casing to release pressure',
          'Burn the battery to test charge'
        ],
        correctIndex: 1,
        explanation: 'Taping terminals prevents friction contact short-circuits that cause catastrophic fire runaways in storage and collection trucks.',
      ),
      const QuizQuestionModel(
        id: 'Q-04',
        category: 'Plastics',
        question: 'Which plastic resin code is most widely recycled into clothing fibers (rPET) and new bottles?',
        options: [
          'Type 1 (PET)',
          'Type 3 (PVC)',
          'Type 6 (Polystyrene)',
          'Type 7 (Other Multi-layer)'
        ],
        correctIndex: 0,
        explanation: 'Type 1 (Polyethylene Terephthalate) has the highest mechanical recycling demand and is converted into polyester fleece and food-grade rPET.',
      ),
      const QuizQuestionModel(
        id: 'Q-05',
        category: 'Composting',
        question: 'Why is adding brown carbon materials (dry leaves, shredded cardboard) essential in composting?',
        options: [
          'To make the compost smell like perfume',
          'To balance wet nitrogen, absorb moisture, and provide airflow to prevent anaerobic odors',
          'To attract stray animals',
          'To stop worms from eating peels'
        ],
        correctIndex: 1,
        explanation: 'Brown carbon materials create structural air pockets and absorb excess liquid, enabling aerobic microbes to thrive without foul anaerobic methane smells.',
      ),
      const QuizQuestionModel(
        id: 'Q-06',
        category: 'Hazardous',
        question: 'What should you do if an energy-saving CFL tube bulb accidentally breaks at home?',
        options: [
          'Vacuum immediately with an electric vacuum cleaner',
          'Ventilate the room for 15 minutes, avoid vacuuming, and scoop shards with stiff paper or cardboard',
          'Wash shards down the kitchen sink drain',
          'Cover with wet cloth and leave it'
        ],
        correctIndex: 1,
        explanation: 'CFL bulbs contain trace mercury vapor. Vacuuming disperses toxic mercury droplets into household air. Ventilate and scoop with disposable cardboard.',
      ),
    ]);
  }
}
