import 'package:flutter/material.dart';
import '../../models/quiz_question_model.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final int milestoneNumber;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.milestoneNumber,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  int _correctCount = 0;
  bool _showResult = false;

  // Per-question answer tracking for result breakdown
  final List<int?> _userAnswers = [];

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnim;

  // ─── Light palette (matches ShopScreen) ──────────────────
  static const Color _bg       = Color(0xFFF7F7F7);
  static const Color _cardBg   = Colors.white;
  static const Color _dark     = Color(0xFF1A1A2E);
  static const Color _green    = Color(0xFF3DBE7A);
  static const Color _red      = Color(0xFFE53935);
  static const Color _grey     = Color(0xFF9E9E9E);
  static const Color _blue     = Color(0xFF4A90D9);

  int get _totalQuestions => widget.questions.length;
  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];
  bool get _passed => _correctCount >= (_totalQuestions * 0.6).ceil();
  bool get _isPractice => widget.milestoneNumber == 0;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOutCubic,
    );
    // Pre-fill answer tracking list
    _userAnswers.addAll(List.filled(_totalQuestions, null));
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_answered) return;
    final isCorrect = index == _currentQuestion.correctIndex;
    setState(() {
      _selectedOptionIndex = index;
      _userAnswers[_currentIndex] = index;
      _answered = true;
      if (isCorrect) _correctCount++;
    });
    _feedbackController.forward(from: 0);
  }

  void _nextQuestion() {
    if (_currentIndex < _totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _answered = false;
      });
      _feedbackController.reset();
    } else {
      setState(() => _showResult = true);
    }
  }

  void _finishQuiz() => Navigator.of(context).pop(_passed);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: _showResult ? _buildResultScreen() : _buildQuestionScreen(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // QUESTION SCREEN
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuestionScreen() {
    return Column(
      children: [
        _buildQuizHeader(),
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _buildQuestionCard(),
                const SizedBox(height: 14),
                _buildOptions(),
                if (_answered) ...[
                  const SizedBox(height: 14),
                  _buildFeedback(),
                  const SizedBox(height: 14),
                  _buildNextButton(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Quiz header ──────────────────────────────────────────

  Widget _buildQuizHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 16, 6),
      child: Row(
        children: [
          // Skip button
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded, size: 18, color: _grey),
            label: const Text(
              'Skip',
              style: TextStyle(
                color: _grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Quiz type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isPractice
                  ? _blue.withOpacity(0.12)
                  : _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isPractice
                      ? Icons.science_rounded
                      : Icons.emoji_events_rounded,
                  color: _isPractice ? _blue : _green,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  _isPractice
                      ? 'Practice'
                      : 'Milestone #${widget.milestoneNumber}',
                  style: TextStyle(
                    color: _isPractice ? _blue : _green,
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

  // ─── Progress bar ─────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentIndex + 1} of $_totalQuestions',
                style: const TextStyle(
                  color: _grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_correctCount correct',
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented progress dots
          Row(
            children: List.generate(_totalQuestions, (i) {
              Color dotColor;
              if (i < _currentIndex) {
                // answered — check if correct
                final wasCorrect = _userAnswers[i] ==
                    widget.questions[i].correctIndex;
                dotColor = wasCorrect ? _green : _red;
              } else if (i == _currentIndex) {
                dotColor = _dark;
              } else {
                dotColor = const Color(0xFFDDDDDD);
              }
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < _totalQuestions - 1 ? 4 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─── Question card ────────────────────────────────────────

  Widget _buildQuestionCard() {
    final catLabel = _currentQuestion.categoryId == 'fundamentals'
        ? 'Flutter Fundamentals'
        : 'Flutter Data Types';
    final catColor = _currentQuestion.categoryId == 'fundamentals'
        ? _green
        : _blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_library_rounded,
                    color: catColor, size: 12),
                const SizedBox(width: 5),
                Text(
                  catLabel,
                  style: TextStyle(
                    color: catColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _currentQuestion.question,
            style: const TextStyle(
              color: _dark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Options ──────────────────────────────────────────────

  Widget _buildOptions() {
    return Column(
      children: List.generate(
        _currentQuestion.options.length,
        (i) => _buildOptionTile(i),
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final option = _currentQuestion.options[index];
    final isCorrect = index == _currentQuestion.correctIndex;
    final isSelected = index == _selectedOptionIndex;
    final labels = ['A', 'B', 'C', 'D'];

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color labelBg;
    Widget? trailingIcon;

    if (!_answered) {
      bgColor = _cardBg;
      borderColor = const Color(0xFFEEEEEE);
      textColor = _dark;
      labelBg = const Color(0xFFF0F0F0);
    } else if (isCorrect) {
      bgColor = _green.withOpacity(0.08);
      borderColor = _green;
      textColor = _dark;
      labelBg = _green;
      trailingIcon =
          const Icon(Icons.check_circle_rounded, color: _green, size: 20);
    } else if (isSelected) {
      bgColor = _red.withOpacity(0.08);
      borderColor = _red;
      textColor = _dark;
      labelBg = _red;
      trailingIcon =
          const Icon(Icons.cancel_rounded, color: _red, size: 20);
    } else {
      bgColor = _cardBg;
      borderColor = const Color(0xFFEEEEEE);
      textColor = _grey;
      labelBg = const Color(0xFFF0F0F0);
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Letter circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: labelBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: (_answered && (isCorrect || isSelected))
                        ? Colors.white
                        : _grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight:
                      isCorrect && _answered ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }

  // ─── Feedback ─────────────────────────────────────────────

  Widget _buildFeedback() {
    final isCorrect = _selectedOptionIndex == _currentQuestion.correctIndex;
    return FadeTransition(
      opacity: _feedbackAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCorrect
              ? _green.withOpacity(0.08)
              : _red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCorrect
                ? _green.withOpacity(0.3)
                : _red.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCorrect
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: isCorrect ? _green : _red,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Correct! 🎉' : 'Not quite.',
                    style: TextStyle(
                      color: isCorrect ? _green : _red,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentQuestion.explanation,
                    style: TextStyle(
                      color: _dark.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Next / finish button ─────────────────────────────────

  Widget _buildNextButton() {
    final isLast = _currentIndex == _totalQuestions - 1;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          isLast ? 'See Results' : 'Next Question →',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RESULT SCREEN
  // ═══════════════════════════════════════════════════════════

  Widget _buildResultScreen() {
    final percentage = (_correctCount / _totalQuestions * 100).round();
    final scoreColor = _passed ? _green : _red;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // Score circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.1),
              border: Border.all(
                color: scoreColor.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_correctCount/$_totalQuestions',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: scoreColor.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Pass / fail message
          Text(
            _passed ? '🎉 Quiz Passed!' : '😅 Keep Practicing!',
            style: const TextStyle(
              color: _dark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _passed
                ? _isPractice
                    ? 'Great work! Keep studying.'
                    : 'Shop items may be unlocked.'
                : _isPractice
                    ? 'Review the lessons and try again.'
                    : 'You\'ll get it next milestone!',
            style: const TextStyle(
              color: _grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),

          // Answer breakdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Answers',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(_totalQuestions, (i) {
                  final q = widget.questions[i];
                  final userAnswer = _userAnswers[i];
                  final wasCorrect = userAnswer == q.correctIndex;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: wasCorrect
                          ? _green.withOpacity(0.06)
                          : _red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: wasCorrect
                            ? _green.withOpacity(0.2)
                            : _red.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          wasCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: wasCorrect ? _green : _red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${i + 1}. ${q.question}',
                                style: const TextStyle(
                                  color: _dark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!wasCorrect) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Correct: ${q.options[q.correctIndex]}',
                                  style: TextStyle(
                                    color: _green.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Back to walking button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _finishQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.directions_walk_rounded, size: 20),
              label: const Text(
                'Back to Walking',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}