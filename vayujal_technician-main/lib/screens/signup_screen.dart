import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error showing snackbar: $e');
    }
  }

  Future<void> _signUp() async {
    if (!mounted) return;
    
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        _showSnackBar('You must agree to the terms and conditions', backgroundColor: Colors.red);
        return;
      }

      if (mounted) {
        try {
          setState(() => _isLoading = true);
        } catch (e) {
          print('Error setting loading state: $e');
          return;
        }
      }

      try {
        print('=== SIGNUP ATTEMPT ===');
        print('Name: ${_nameController.text.trim()}');
        print('Email: ${_emailController.text.trim()}');

        // ✅ Create user with Firebase Auth
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        print('User created successfully: ${userCredential.user?.uid}');

        // ✅ Update displayName
        await userCredential.user!.updateDisplayName(_nameController.text.trim());
        await userCredential.user!.reload();

        // ✅ Save ONLY basic user info in Firestore (essential fields only)
        // This will indicate a NEW USER who needs profile setup
        await _firestore.collection('technicians').doc(userCredential.user!.uid).set({
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileComplete': false,
          'role': 'tech'
           // Marker for new account
          // Deliberately NOT adding extended fields:
          // - employeeId (will be added in profile setup)
          // - mobileNumber (will be added in profile setup)  
          // - designation (will be added in profile setup)
          // - department (will be added in profile setup)
        });

        print('User document created in Firestore');

        // ✅ Sign out the user immediately after account creation
        // This forces them to go through the login process
        await _auth.signOut();

        _showSnackBar('Account created successfully! Please login to continue.', 
                     backgroundColor: Colors.green);

        // ✅ Navigate back to login screen after successful signup
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          try {
            Navigator.pop(context); // Go back to login screen
          } catch (e) {
            print('Error navigating back: $e');
          }
        }

      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
        
        String errorMessage = 'Account creation failed';
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email address.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Account creation is currently disabled.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection.';
            break;
          default:
            errorMessage = e.message ?? 'Account creation failed. Please try again.';
        }

        _showSnackBar(errorMessage, backgroundColor: Colors.red);
      } catch (e) {
        print('General signup error: $e');
        _showSnackBar('Something went wrong. Please try again.', backgroundColor: Colors.red);
      } finally {
        if (mounted) {
          try {
            setState(() => _isLoading = false);
          } catch (e) {
            print('Error updating loading state: $e');
          }
        }
      }
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    
    try {
      Navigator.pop(context); // Go back to login screen
    } catch (e) {
      print('Error navigating to login: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sign up',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              "assets/images/ayujal_logo.png",
              width: 100,
              height: 100,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create your account',







                
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              _buildLabel('Full Name'),
              _buildTextField(_nameController, 'Enter your full name', false),
              const SizedBox(height: 24),
              _buildLabel('Email Address'),
              _buildTextField(_emailController, 'Enter your email', false, email: true),
              const SizedBox(height: 24),
              _buildLabel('Password'),
              _buildTextField(_passwordController, 'At least 8 characters', true),
              const SizedBox(height: 24),
              _buildTermsCheckbox(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Create account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _navigateToLogin,
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: _isLoading ? Colors.grey : Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, bool obscureText,
      {bool email = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      obscureText: obscureText ? _obscurePassword : false,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: obscureText
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: _isLoading ? null : () {
                  if (mounted) {
                    try {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    } catch (e) {
                      print('Error toggling password visibility: $e');
                    }
                  }
                },
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        if (email) {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'Please enter a valid email address';
          }
        }
        if (obscureText && value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: _isLoading ? null : (value) {
            if (mounted) {
              try {
                setState(() {
                  _agreeToTerms = value ?? false;
                });
              } catch (e) {
                print('Error updating terms checkbox: $e');
              }
            }
          },
          activeColor: Colors.blue,
        ),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.black, fontSize: 14),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'terms of service',
                  style: TextStyle(color: Colors.blue),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'privacy policy',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}