import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendza/screens/add_expenses_screen.dart';
import 'package:spendza/screens/login_screen.dart';
import 'package:spendza/screens/signup_screen.dart';

void main() {
  testWidgets(
    'AddExpenseScreen renders title, save button, and text input fields',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddExpenseScreen(),
        ),
      );

      // Header and button checks
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Save Expense'), findsOneWidget);

      // Text form fields
      expect(find.byType(TextFormField), findsWidgets);
      expect(
        find.byType(DropdownButtonFormField<String>),
        findsOneWidget,
      );

      // Hint text and icons
      expect(find.text('e.g. Lunch at Olive'), findsOneWidget);
      expect(
        find.byIcon(Icons.calendar_today_outlined),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LoginScreen renders brand elements, inputs, and sign in actions',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Brand and headers
      expect(find.text('Spendza'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(
        find.text('Track Smarter · Spend Wisely'),
        findsOneWidget,
      );

      // Form fields and buttons
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(
        find.text('Explore with Demo Account'),
        findsOneWidget,
      );
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    },
  );

  testWidgets(
    'SignupScreen renders all input fields, terms checkbox, and register action',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Brand and headers
      expect(find.text('Join Spendza'), findsOneWidget);
      expect(find.text('Create an Account'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);

      // Form fields and buttons
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    },
  );
}