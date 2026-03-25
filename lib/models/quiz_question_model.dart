import 'dart:math';

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options; // always 4 options
  final int correctIndex;
  final String explanation;
  final String categoryId; // 'fundamentals' or 'data_types'

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.categoryId,
  });

  // ─── Question Bank ─────────────────────────────────────────

  static const List<QuizQuestion> _all = [
    // ─── Flutter Fundamentals ─────────────────────────────
    QuizQuestion(
      id: 'q_f1',
      question: 'What programming language does Flutter use?',
      options: ['Java', 'Kotlin', 'Dart', 'Swift'],
      correctIndex: 2,
      explanation: 'Flutter uses Dart, a language developed by Google that is optimized for fast, cross-platform apps.',
      categoryId: 'fundamentals',
    ),
    QuizQuestion(
      id: 'q_f2',
      question: 'What is the base building block of every Flutter UI?',
      options: ['Activity', 'Widget', 'View', 'Component'],
      correctIndex: 1,
      explanation: 'In Flutter, everything is a Widget — text, buttons, layouts, and even the app itself.',
      categoryId: 'fundamentals',
    ),
    QuizQuestion(
      id: 'q_f3',
      question: 'Which widget type can update its UI when data changes?',
      options: ['StatelessWidget', 'ImmutableWidget', 'StatefulWidget', 'DynamicWidget'],
      correctIndex: 2,
      explanation: 'StatefulWidget can call setState() to rebuild the UI when internal state changes.',
      categoryId: 'fundamentals',
    ),
    QuizQuestion(
      id: 'q_f4',
      question: 'What function must you call to trigger a StatefulWidget rebuild?',
      options: ['rebuild()', 'refresh()', 'update()', 'setState()'],
      correctIndex: 3,
      explanation: 'setState() tells Flutter that the widget\'s state has changed and it should rebuild.',
      categoryId: 'fundamentals',
    ),
    QuizQuestion(
      id: 'q_f5',
      question: 'What is the entry point of every Flutter application?',
      options: ['start()', 'init()', 'main()', 'launch()'],
      correctIndex: 2,
      explanation: 'Every Dart and Flutter program starts with the main() function, which calls runApp().',
      categoryId: 'fundamentals',
    ),
    QuizQuestion(
      id: 'q_f6',
      question: 'What does runApp() do in Flutter?',
      options: [
        'Compiles the app',
        'Attaches the root widget to the screen',
        'Connects to a server',
        'Loads assets',
      ],
      correctIndex: 1,
      explanation: 'runApp() takes a root widget and attaches it to the screen, starting the UI render cycle.',
      categoryId: 'fundamentals',
    ),
    QuizQuestion(
      id: 'q_f7',
      question: 'Which of these is a StatelessWidget?',
      options: ['A counter that increments', 'A login form', 'A static text label', 'An animated button'],
      correctIndex: 2,
      explanation: 'A static text label never changes, making it ideal for a StatelessWidget.',
      categoryId: 'fundamentals',
    ),
    QuizQuestion(
      id: 'q_f8',
      question: 'In the Flutter widget tree, MaterialApp is typically the:',
      options: ['Child widget', 'Leaf widget', 'Root widget', 'State widget'],
      correctIndex: 2,
      explanation: 'MaterialApp is usually the root widget that wraps the entire application and provides navigation and theming.',
      categoryId: 'fundamentals',
    ),

    // ─── Flutter Data Types ───────────────────────────────
    QuizQuestion(
      id: 'q_d1',
      question: 'Which Dart type stores whole numbers without decimals?',
      options: ['double', 'num', 'int', 'float'],
      correctIndex: 2,
      explanation: 'int stores whole numbers like 0, 1, 100, and -5. Use it for counts, indexes, and coins.',
      categoryId: 'data_types',
    ),
    QuizQuestion(
      id: 'q_d2',
      question: 'Which Dart type stores numbers with decimal points?',
      options: ['int', 'decimal', 'double', 'float'],
      correctIndex: 2,
      explanation: 'double stores floating-point numbers like 3.14, 1.5, and -0.75.',
      categoryId: 'data_types',
    ),
    QuizQuestion(
      id: 'q_d3',
      question: 'How do you embed a variable inside a Dart String?',
      options: [
        'Using #{variable}',
        'Using \${variable} or \$variable',
        'Using %(variable)',
        'Using {variable}',
      ],
      correctIndex: 1,
      explanation: 'Dart uses \$variable or \${expression} for string interpolation inside strings.',
      categoryId: 'data_types',
    ),
    QuizQuestion(
      id: 'q_d4',
      question: 'What are the only two values a bool can hold?',
      options: ['0 and 1', 'yes and no', 'true and false', 'on and off'],
      correctIndex: 2,
      explanation: 'bool can only be true or false. It is used to control conditions and logical flow.',
      categoryId: 'data_types',
    ),
    QuizQuestion(
      id: 'q_d5',
      question: 'What index does the first item in a Dart List have?',
      options: ['1', '-1', '0', 'First'],
      correctIndex: 2,
      explanation: 'Dart Lists (like most languages) are zero-indexed. The first element is at index 0.',
      categoryId: 'data_types',
    ),
    QuizQuestion(
      id: 'q_d6',
      question: 'Which Dart type stores key-value pairs?',
      options: ['List', 'Set', 'Map', 'Dict'],
      correctIndex: 2,
      explanation: 'Map stores data as key-value pairs, e.g., Map<String, int> scores = {"Alice": 95}.',
      categoryId: 'data_types',
    ),
    QuizQuestion(
      id: 'q_d7',
      question: 'Which keyword creates a variable whose value can NEVER change at runtime?',
      options: ['var', 'let', 'final', 'static'],
      correctIndex: 2,
      explanation: 'final creates a variable that can only be assigned once. const is even stricter — it must be known at compile time.',
      categoryId: 'data_types',
    ),
    QuizQuestion(
      id: 'q_d8',
      question: 'What does "var score = 100;" mean in Dart?',
      options: [
        'score is a const that never changes',
        'Dart infers the type as int, and score can be reassigned',
        'score is nullable',
        'score is a final int',
      ],
      correctIndex: 1,
      explanation: 'var lets Dart infer the type automatically. Since 100 is an int, score is inferred as int and can be reassigned later.',
      categoryId: 'data_types',
    ),
  ];

  /// Returns 5 random questions mixed from both categories
  static List<QuizQuestion> getRandomQuestions({int count = 5}) {
    final shuffled = List<QuizQuestion>.from(_all)..shuffle(Random());
    return shuffled.take(count).toList();
  }

  /// Returns questions filtered by a specific category
  static List<QuizQuestion> getByCategory(String categoryId, {int count = 5}) {
    final filtered = _all.where((q) => q.categoryId == categoryId).toList()
      ..shuffle(Random());
    return filtered.take(count).toList();
  }
}