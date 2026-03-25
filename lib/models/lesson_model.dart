import 'package:flutter/material.dart';

class LessonTopic {
  final String id;
  final String title;
  final String content;
  final String? codeSnippet;

  const LessonTopic({
    required this.id,
    required this.title,
    required this.content,
    this.codeSnippet,
  });
}

class LessonCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<LessonTopic> topics;

  const LessonCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.topics,
  });

  static const List<LessonCategory> all = [
    LessonCategory(
      id: 'fundamentals',
      title: 'Flutter Fundamentals',
      subtitle: 'Core concepts every Flutter developer needs',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF00E5A0),
      topics: [
        LessonTopic(
          id: 'what_is_flutter',
          title: 'What is Flutter?',
          content:
              'Flutter is an open-source UI toolkit created by Google. It lets you build '
              'beautiful, natively compiled applications for mobile, web, and desktop from '
              'a single codebase. Flutter uses the Dart programming language and provides '
              'its own rendering engine, making apps look consistent across all platforms.',
        ),
        LessonTopic(
          id: 'widgets',
          title: 'Everything is a Widget',
          content:
              'In Flutter, almost everything is a widget — buttons, text, images, layouts, '
              'and even the app itself. Widgets describe what the UI should look like given '
              'the current configuration and state. They are the building blocks of a Flutter app.',
          codeSnippet:
              'Text("Hello, Flutter!")\n'
              'Icon(Icons.star)\n'
              'ElevatedButton(onPressed: () {}, child: Text("Click me"))',
        ),
        LessonTopic(
          id: 'stateless_stateful',
          title: 'StatelessWidget vs StatefulWidget',
          content:
              'A StatelessWidget never changes after it is built — it is immutable. '
              'Use it for UI that depends only on its constructor arguments.\n\n'
              'A StatefulWidget can rebuild itself when its internal state changes. '
              'Call setState() inside the widget to trigger a rebuild with updated values.',
          codeSnippet:
              '// Stateless — no changing data\n'
              'class MyLabel extends StatelessWidget {\n'
              '  Widget build(BuildContext context) {\n'
              '    return Text("I never change");\n'
              '  }\n'
              '}\n\n'
              '// Stateful — data can change\n'
              'class Counter extends StatefulWidget { ... }\n'
              'class _CounterState extends State<Counter> {\n'
              '  int count = 0;\n'
              '  void increment() => setState(() => count++);\n'
              '}',
        ),
        LessonTopic(
          id: 'widget_tree',
          title: 'The Widget Tree',
          content:
              'Flutter apps are built as a tree of widgets. Each widget has a parent '
              'and can have children. The root is usually MaterialApp or CupertinoApp. '
              'Understanding the widget tree helps you structure layouts and pass data '
              'down through constructor arguments.',
          codeSnippet:
              'MaterialApp\n'
              '  └── Scaffold\n'
              '       ├── AppBar(title: Text("GrowStep"))\n'
              '       └── Column\n'
              '            ├── Text("Hello!")\n'
              '            └── ElevatedButton(...)',
        ),
        LessonTopic(
          id: 'main_function',
          title: 'The main() Entry Point',
          content:
              'Every Flutter app starts with a main() function. This is the entry point '
              'that Dart calls when your app launches. Inside main(), you call runApp() '
              'and pass it your root widget to start rendering the UI.',
          codeSnippet:
              'void main() {\n'
              '  runApp(const MyApp());\n'
              '}\n\n'
              'class MyApp extends StatelessWidget {\n'
              '  Widget build(BuildContext context) {\n'
              '    return MaterialApp(home: HomeScreen());\n'
              '  }\n'
              '}',
        ),
      ],
    ),
    LessonCategory(
      id: 'data_types',
      title: 'Flutter Data Types',
      subtitle: 'Learn Dart\'s built-in types used in Flutter',
      icon: Icons.data_object_rounded,
      color: Color(0xFF00B4D8),
      topics: [
        LessonTopic(
          id: 'int_double',
          title: 'int and double',
          content:
              'int holds whole numbers with no decimal point.\n'
              'double holds numbers with a decimal point (floating-point).\n\n'
              'Use int for counts, steps, and coins. Use double for distances, '
              'percentages, and precise calculations.',
          codeSnippet:
              'int steps = 1000;\n'
              'int coins = 5;\n\n'
              'double distance = 1.5; // 1.5 km\n'
              'double progress = 0.75; // 75%',
        ),
        LessonTopic(
          id: 'string',
          title: 'String',
          content:
              'A String holds text data. In Dart, Strings are immutable — you cannot '
              'change individual characters. You can create them with single or double '
              'quotes. String interpolation lets you embed variables directly inside strings.',
          codeSnippet:
              'String name = "GrowStep";\n'
              'String greeting = \'Hello, \$name!\';\n'
              '// Output: Hello, GrowStep!\n\n'
              'String multi = """\n'
              '  This spans\n'
              '  multiple lines\n'
              '""";',
        ),
        LessonTopic(
          id: 'bool',
          title: 'bool',
          content:
              'A bool holds either true or false. Use booleans to control logic, '
              'toggle features, or track whether something has happened (e.g., '
              'whether an item is purchased or a quiz has been completed).',
          codeSnippet:
              'bool isLoggedIn = true;\n'
              'bool hasSelectedAvatar = false;\n\n'
              'if (isLoggedIn) {\n'
              '  print("Welcome back!");\n'
              '}',
        ),
        LessonTopic(
          id: 'list',
          title: 'List',
          content:
              'A List is an ordered collection of items. All items must be of the same '
              'type (or use List<dynamic> for mixed). Lists are zero-indexed — the first '
              'item is at index 0. You can add, remove, and access items by index.',
          codeSnippet:
              'List<String> avatars = ["Oakley", "Sunny", "Sparky", "Misty"];\n'
              'print(avatars[0]); // Oakley\n'
              'print(avatars.length); // 4\n\n'
              'avatars.add("Nova");\n'
              'avatars.remove("Sparky");\n',
        ),
        LessonTopic(
          id: 'map',
          title: 'Map',
          content:
              'A Map stores data as key-value pairs. Keys must be unique. '
              'Maps are useful for storing structured data where you want to '
              'look things up by name rather than position.',
          codeSnippet:
              'Map<String, int> stats = {\n'
              '  "speed": 90,\n'
              '  "stamina": 75,\n'
              '};\n\n'
              'print(stats["speed"]); // 90\n'
              'stats["endurance"] = 60; // add new key\n',
        ),
        LessonTopic(
          id: 'var_final_const',
          title: 'var, final, and const',
          content:
              'var — Dart infers the type automatically. The value can change later.\n\n'
              'final — The variable can only be set once. Useful for values known at runtime.\n\n'
              'const — A compile-time constant. The value must be known before the app runs '
              'and never changes. More efficient than final for UI constants.',
          codeSnippet:
              'var score = 100;      // can change\n'
              'score = 200;          // OK\n\n'
              'final String userId = generateId(); // set once\n\n'
              'const Color green = Color(0xFF00E5A0); // compile-time\n',
        ),
      ],
    ),
  ];
}