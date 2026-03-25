// GrowStep AR — Widget Tests
//
// NOTE: MyApp requires DatabaseService, StorageService, and AuthService
// to be initialised before pumping. These tests use setUp() to mock the
// minimum required state, and test individual screens in isolation where
// full initialisation is not practical in a widget test environment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growstep/features/auth/login_screen.dart';
import 'package:growstep/features/quiz/quiz_screen.dart';
import 'package:growstep/models/quiz_question_model.dart';

void main() {
  // ─── LoginScreen ────────────────────────────────────────────

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders GrowStep AR title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.text('GrowStep '), findsOneWidget);
      expect(find.text('AR'), findsOneWidget);
    });

    testWidgets('shows error when login tapped with empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Tap the login button without filling anything in
      await tester.tap(find.text("Let's Play  →"));
      await tester.pump();

      // Validation errors should appear
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address'), 'notanemail');
      await tester.tap(find.text("Let's Play  →"));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error for password shorter than 6 characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address'), 'test@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(find.text("Let's Play  →"));
      await tester.pump();

      expect(find.text('Minimum 6 characters'), findsOneWidget);
    });
  });

  // ─── QuizScreen ─────────────────────────────────────────────

  group('QuizScreen', () {
    // Fixed questions so tests are deterministic
    final testQuestions = [
      const QuizQuestion(
        id: 'test_q1',
        question: 'What language does Flutter use?',
        options: ['Java', 'Swift', 'Dart', 'Kotlin'],
        correctIndex: 2,
        explanation: 'Flutter uses Dart.',
        categoryId: 'fundamentals',
      ),
      const QuizQuestion(
        id: 'test_q2',
        question: 'What stores whole numbers in Dart?',
        options: ['double', 'int', 'String', 'bool'],
        correctIndex: 1,
        explanation: 'int stores whole numbers.',
        categoryId: 'data_types',
      ),
    ];

    testWidgets('renders first question text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: testQuestions, milestoneNumber: 1),
        ),
      );

      expect(find.text('What language does Flutter use?'), findsOneWidget);
    });

    testWidgets('renders all 4 answer options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: testQuestions, milestoneNumber: 1),
        ),
      );

      expect(find.text('Java'), findsOneWidget);
      expect(find.text('Swift'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Kotlin'), findsOneWidget);
    });

    testWidgets('shows correct feedback after selecting right answer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: testQuestions, milestoneNumber: 1),
        ),
      );

      await tester.tap(find.text('Dart'));
      await tester.pumpAndSettle();

      expect(find.text('Correct! 🎉'), findsOneWidget);
    });

    testWidgets('shows incorrect feedback after selecting wrong answer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: testQuestions, milestoneNumber: 1),
        ),
      );

      await tester.tap(find.text('Java'));
      await tester.pumpAndSettle();

      expect(find.text('Not quite.'), findsOneWidget);
    });

    testWidgets('shows Practice badge for milestoneNumber 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: testQuestions, milestoneNumber: 0),
        ),
      );

      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('shows milestone badge for milestoneNumber > 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: testQuestions, milestoneNumber: 2),
        ),
      );

      expect(find.text('Milestone #2'), findsOneWidget);
    });

    testWidgets('progress shows correct question count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(questions: testQuestions, milestoneNumber: 1),
        ),
      );

      expect(find.text('1 of 2'), findsOneWidget);
    });
  });
}
