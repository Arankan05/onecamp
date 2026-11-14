import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import '../../../routes/app_routes.dart';

class DevChatEntryScreen extends StatefulWidget {
  const DevChatEntryScreen({super.key});

  @override
  State<DevChatEntryScreen> createState() => _DevChatEntryScreenState();
}

class _DevChatEntryScreenState extends State<DevChatEntryScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Sign-in failed (${e.code}).');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Sign-in error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Field Validation
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a Display Name for your profile.');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 1. Create Firebase Auth account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception('Firebase Authentication did not return a valid user ID.');
      }

      // 2. Create matching Firestore user profile document required by rules & student search
      // Role is ALWAYS explicitly set to 'student'
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _successMessage = 'Account created successfully! Signed in as $email';
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Registration failed (${e.code}).');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Registration error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('OneCamp Initializing...')),
      );
    }

    return Scaffold(
      backgroundColor: ChatColors.pageBackground,
      appBar: AppBar(
        title: const Text('OneCamp Initializing...', style: ChatTextStyles.appBarTitle),
        backgroundColor: ChatColors.cardBackground,
        elevation: 0,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(ChatDimensions.paddingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Development Banner Card
                Container(
                  padding: const EdgeInsets.all(ChatDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: ChatColors.lightLavender,
                    borderRadius: BorderRadius.circular(ChatDimensions.radiusM),
                    border: Border.all(color: ChatColors.accentLavender),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.developer_mode, color: ChatColors.primaryPurple, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Member 5 Development Entry Portal',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: ChatColors.primaryDarkPurple,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Temporary sign-in portal to test the Chat module independently before complete app integration.',
                        style: TextStyle(fontSize: 12.0, color: ChatColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ChatDimensions.paddingXL),

                if (user != null) ...[
                  // Authenticated State View
                  Container(
                    padding: const EdgeInsets.all(ChatDimensions.paddingL),
                    decoration: ChatDecorations.cardDecoration,
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: ChatColors.primaryPurple,
                          child: Icon(Icons.person, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Signed in as:',
                          style: ChatTextStyles.chatTileSubtitle,
                        ),
                        Text(
                          user.email ?? user.uid,
                          style: ChatTextStyles.chatTileTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UID: ${user.uid}',
                          style: const TextStyle(fontSize: 11, color: ChatColors.textLight),
                        ),
                        if (_successMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: ChatColors.onlineGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: ChatDimensions.paddingXL),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.chatList);
                    },
                    icon: const Icon(Icons.forum_rounded),
                    label: const Text(
                      'Open Chat Module',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: ChatDimensions.paddingL),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ChatDimensions.radiusM),
                      ),
                    ),
                  ),
                  const SizedBox(height: ChatDimensions.paddingM),

                  OutlinedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: ChatDimensions.paddingM),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ] else ...[
                  // Unauthenticated State: Sign In vs Registration View
                  Container(
                    padding: const EdgeInsets.all(ChatDimensions.paddingL),
                    decoration: ChatDecorations.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isRegisterMode
                              ? 'Register New Student Account'
                              : 'Sign In with Firebase Test Account',
                          style: ChatTextStyles.chatTileTitle,
                        ),
                        const SizedBox(height: ChatDimensions.paddingM),

                        if (_isRegisterMode) ...[
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: ChatDecorations.inputDecoration('Display Name (e.g. Jane Doe)'),
                          ),
                          const SizedBox(height: ChatDimensions.paddingM),
                        ],

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: ChatDecorations.inputDecoration('Email Address'),
                        ),
                        const SizedBox(height: ChatDimensions.paddingM),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: ChatDecorations.inputDecoration('Password (min 6 characters)'),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: ChatDimensions.paddingM),
                          Container(
                            padding: const EdgeInsets.all(ChatDimensions.paddingM),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(ChatDimensions.radiusS),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: ChatDimensions.paddingL),

                        if (_isLoading)
                          const Center(child: CircularProgressIndicator(color: ChatColors.primaryPurple))
                        else ...[
                          ElevatedButton(
                            onPressed: _isRegisterMode ? _handleRegister : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ChatColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: ChatDimensions.paddingM),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ChatDimensions.radiusM),
                              ),
                            ),
                            child: Text(
                              _isRegisterMode ? 'Create Account' : 'Sign In',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: ChatDimensions.paddingS),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isRegisterMode
                                  ? 'Already have an account? Sign In'
                                  : 'Need a test account? Register New Test Account',
                              style: const TextStyle(color: ChatColors.primaryDarkPurple),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
