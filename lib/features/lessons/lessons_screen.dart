import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_question_model.dart';
import '../quiz/quiz_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, String?> _expandedTopics = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ─── Light palette (matches ShopScreen) ──────────────────
  static const Color _bg       = Color(0xFFF7F7F7);
  static const Color _cardBg   = Colors.white;
  static const Color _dark     = Color(0xFF1A1A2E);
  static const Color _green    = Color(0xFF3DBE7A);
  static const Color _grey     = Color(0xFF9E9E9E);
  static const Color _blue     = Color(0xFF4A90D9);

  // Per-category accent colors
  static const Color _catFundamentals = Color(0xFF3DBE7A); // green
  static const Color _catDataTypes    = Color(0xFF4A90D9); // blue

  Color _categoryColor(LessonCategory cat) =>
      cat.id == 'fundamentals' ? _catFundamentals : _catDataTypes;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 16),
                    ...LessonCategory.all.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildCategoryCard(cat),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: _dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Lessons',
              style: TextStyle(
                color: _dark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: _green, size: 14),
                const SizedBox(width: 5),
                Text(
                  '${LessonCategory.all.fold(0, (s, c) => s + c.topics.length)} topics',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Intro card ───────────────────────────────────────────

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _green.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded, color: _green, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn Flutter While You Walk',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Study here, then get quizzed every 500m milestone.',
                  style: TextStyle(
                    color: _grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category card ────────────────────────────────────────

  Widget _buildCategoryCard(LessonCategory category) {
    final color = _categoryColor(category);
    final topicCount = category.topics.length;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category header strip
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(category.icon, color: color, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.subtitle,
                        style: const TextStyle(
                          color: _grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$topicCount topics',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Topic list
          ...category.topics.asMap().entries.map((entry) {
            final isLast = entry.key == topicCount - 1;
            return _buildTopicTile(category, entry.value, isLast);
          }),

          // Practice quiz button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: GestureDetector(
              onTap: () => _launchPracticeQuiz(category),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.quiz_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    
                    Flexible(
                      child: Text(
                      'Practice Quiz — ${category.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                       overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Topic tile ───────────────────────────────────────────

  Widget _buildTopicTile(
      LessonCategory category, LessonTopic topic, bool isLast) {
    final isExpanded = _expandedTopics[category.id] == topic.id;
    final color = _categoryColor(category);

    return Column(
      children: [
        // Divider above each topic
        const Divider(
          height: 1,
          color: Color(0xFFEEEEEE),
          indent: 18,
          endIndent: 18,
        ),
        InkWell(
          onTap: () => setState(() {
            _expandedTopics[category.id] = isExpanded ? null : topic.id;
          }),
          borderRadius: isLast && !isExpanded
              ? const BorderRadius.vertical(bottom: Radius.circular(20))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isExpanded ? color : const Color(0xFFDDDDDD),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    topic.title,
                    style: TextStyle(
                      color: isExpanded ? _dark : _grey,
                      fontSize: 14,
                      fontWeight: isExpanded
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? color : _grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildTopicContent(category, topic),
      ],
    );
  }

  Widget _buildTopicContent(LessonCategory category, LessonTopic topic) {
    final color = _categoryColor(category);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              topic.content,
              style: TextStyle(
                color: _dark.withOpacity(0.75),
                fontSize: 13,
                height: 1.65,
              ),
            ),
          ),
          if (topic.codeSnippet != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Text(
                topic.codeSnippet!,
                style: const TextStyle(
                  color: Color(0xFF1A5C3A),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.65,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Practice quiz ────────────────────────────────────────

  Future<void> _launchPracticeQuiz(LessonCategory category) async {
    final questions = QuizQuestion.getByCategory(category.id, count: 5);
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          milestoneNumber: 0, // 0 = practice, not a milestone quiz
        ),
      ),
    );
    // Practice quizzes don't affect completedQuizCount
  }
}