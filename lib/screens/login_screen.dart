import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/app_state.dart';
import 'main_navigation_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  static const Color navy = Color(0xFF2B2E83);
  static const Color accentPurple = Color(0xFF8A4FE0);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final rememberMe =
          await _secureStorage.read(key: 'remember_me');

      if (rememberMe == 'true') {
        final email =
            await _secureStorage.read(key: 'saved_email');

        final password =
            await _secureStorage.read(key: 'saved_password');

        if (!mounted) return;

        setState(() {
          _emailController.text = email ?? '';
          _passwordController.text = password ?? '';
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignore storage errors and allow normal login.
    }
  }

  Future<void> _saveCredentials(
    String email,
    String password,
  ) async {
    await _secureStorage.write(
      key: 'remember_me',
      value: 'true',
    );

    await _secureStorage.write(
      key: 'saved_email',
      value: email,
    );

    await _secureStorage.write(
      key: 'saved_password',
      value: password,
    );
  }

  Future<void> _clearSavedCredentials() async {
    await _secureStorage.delete(key: 'remember_me');
    await _secureStorage.delete(key: 'saved_email');
    await _secureStorage.delete(key: 'saved_password');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (_rememberMe) {
        await _saveCredentials(email, password);
      } else {
        await _clearSavedCredentials();
      }

      if (!mounted) return;

      final user = credential.user;
      final firebaseName = user?.displayName;

      final name =
          firebaseName != null && firebaseName.isNotEmpty
              ? firebaseName
              : email.split('@').first;

      final formattedName = name.isNotEmpty
          ? name[0].toUpperCase() + name.substring(1)
          : 'User';

      AppState.instance.login(
        name: formattedName,
        email: email,
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, $formattedName!'),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'user-not-found':
          message =
              'No account found with this email address.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message = 'Login failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE0555D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Something went wrong. Please try again.'),
          backgroundColor: Color(0xFFE0555D),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark =
            Theme.of(ctx).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E2138)
                  : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          Colors.grey.withValues(alpha: 0.3),
                      borderRadius:
                          BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      color: navy,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF191C32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the email associated with your Spendza account to receive password reset instructions.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: resetEmailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: navy,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF272A45)
                        : const Color(0xFFF3F4F9),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final email =
                          resetEmailController.text.trim();

                      if (email.isEmpty ||
                          !email.contains('@')) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid email address.',
                            ),
                            backgroundColor:
                                Color(0xFFE0555D),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(
                          email: email,
                        );

                        if (!mounted) return;

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (!mounted) return;

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password reset link sent to $email',
                            ),
                            backgroundColor: navy,
                            behavior:
                                SnackBarBehavior.floating,
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        if (!mounted) return;

                        String message;

                        switch (e.code) {
                          case 'invalid-email':
                            message =
                                'Please enter a valid email address.';
                            break;

                          case 'user-not-found':
                            message =
                                'No account found with this email address.';
                            break;

                          default:
                            message =
                                'Unable to send reset email. Please try again.';
                        }

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor:
                                const Color(0xFFE0555D),
                            behavior:
                                SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? const Color(0xFF1E2138)
        : Colors.white;

    final textColor = isDark
        ? Colors.white
        : const Color(0xFF191C32);

    final subTextColor =
        isDark ? Colors.white60 : Colors.black54;

    final fieldFill = isDark
        ? const Color(0xFF272A45)
        : const Color(0xFFF4F5FA);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // App Brand Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            navy,
                            Color(0xFF4549A8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/spendza_logo.jpeg',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Brand name
                  Center(
                    child: Text(
                      'Spendza',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Tagline
                  Center(
                    child: Text(
                      'Track Smarter · Spend Wisely',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius:
                          BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.04,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // Welcome Section
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Welcome',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to manage your budget & expenses',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Email Field
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller:
                              _emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          decoration:
                              InputDecoration(
                            hintText:
                                'Enter your email',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: subTextColor
                                  .withValues(
                                alpha: 0.6,
                              ),
                            ),
                            prefixIcon:
                                const Icon(
                              Icons.email_outlined,
                              color: navy,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              borderSide:
                                  BorderSide.none,
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              borderSide:
                                  const BorderSide(
                                color: navy,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }

                            if (!value.contains('@') ||
                                !value.contains('.')) {
                              return 'Please enter a valid email address';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Password Field
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller:
                              _passwordController,
                          obscureText:
                              _obscurePassword,
                          autofillHints: const [
                            AutofillHints.password,
                          ],
                          decoration:
                              InputDecoration(
                            hintText:
                                'Enter your password',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: subTextColor
                                  .withValues(
                                alpha: 0.6,
                              ),
                            ),
                            prefixIcon:
                                const Icon(
                              Icons.lock_outline_rounded,
                              color: navy,
                              size: 20,
                            ),
                            suffixIcon:
                                IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                                color:
                                    subTextColor,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              borderSide:
                                  BorderSide.none,
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              borderSide:
                                  const BorderSide(
                                color: navy,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Please enter your password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Remember Me & Forgot Password
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: navy,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          4),
                                ),
                                onChanged: (val) async {
                                  final value =
                                      val ?? false;

                                  setState(() {
                                    _rememberMe = value;
                                  });

                                  if (!value) {
                                    await _clearSavedCredentials();
                                  }
                                },
                              ),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: textColor,
                              ),
                            ),

                            const Spacer(),

                            InkWell(
                              onTap:
                                  _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      accentPurple,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Sign In Button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(
                              colors: [
                                navy,
                                Color(0xFF39469E),
                              ],
                              begin:
                                  Alignment.centerLeft,
                              end:
                                  Alignment.centerRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                                    16),
                            boxShadow: [
                              BoxShadow(
                                color: navy.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                offset:
                                    const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                                  Colors.transparent,
                              disabledBackgroundColor:
                                  Colors.transparent,
                              shadowColor:
                                  Colors.transparent,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        16),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Navigation to Signup
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}