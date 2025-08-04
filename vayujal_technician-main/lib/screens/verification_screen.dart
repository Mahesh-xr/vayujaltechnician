import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _seconds = 300; // 5 minutes
  String _generatedOtp = "";
  bool _isOtpExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOtpToEmail();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_seconds > 0) {
        try {
          setState(() => _seconds--);
        } catch (e) {
          print('Error updating timer: $e');
          timer.cancel();
        }
      } else {
        try {
          setState(() => _isOtpExpired = true);
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP expired. Please request a new one.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print('Error handling timer expiration: $e');
          timer.cancel();
        }
      }
    });
  }

  String _generateOtp() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  Future<void> _sendOtpToEmail() async {
    final otp = _generateOtp();
    _generatedOtp = otp;

    const serviceId = 'service_mwtxf9o';
    const templateId = 'template_3pq0msb';
    const userId = 'x5vuY_1gi-Fynu--j';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'email': widget.email,
            'otp': otp,
          },
        }),
      );

      if (response.statusCode == 200) {
        print("OTP sent to ${widget.email}");
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('OTP sent to ${widget.email}'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            print('Error showing success snackbar: $e');
          }
        }
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      print("Failed to send OTP: $e");
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send OTP to ${widget.email}'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          print('Error showing error snackbar: $e');
        }
      }
    }
  }

  Future<void> _resendOtp() async {
    if (mounted) {
      try {
        setState(() {
          _seconds = 300;
          _isOtpExpired = false;
        });
      } catch (e) {
        print('Error updating resend state: $e');
        return;
      }
    }

    for (var controller in _controllers) {
      controller.clear();
    }

    _startTimer();
    await _sendOtpToEmail();
  }

  Future<void> verifyOtp() async {
    if (_isOtpExpired) {
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP has expired. Please request a new one.'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          print('Error showing expired OTP snackbar: $e');
        }
      }
      return;
    }

    final enteredOtp = _controllers.map((controller) => controller.text).join();
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a complete OTP.')),
      );
      return;
    }

    if (enteredOtp == _generatedOtp) {
      _timer?.cancel();

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Reset Email Sent'),
            content: Text(
                'A password reset email has been sent to ${widget.email}. Please check your inbox.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.pop(context); // go back to login screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect OTP entered'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'OTP Verification',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check your Email',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We have sent an OTP to ${widget.email}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 40),
            const Text(
              'Enter code:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: _isOtpExpired ? Colors.red[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    enabled: !_isOtpExpired,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isOtpExpired ? Colors.red : Colors.black,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _isOtpExpired
                    ? 'OTP Expired'
                    : '[${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}]',
                style: TextStyle(
                  fontSize: 16,
                  color: _isOtpExpired ? Colors.red : Colors.black,
                  fontWeight:
                      _isOtpExpired ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isOtpExpired)
              Center(
                child: TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isOtpExpired ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOtpExpired ? Colors.grey : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify & Reset Password',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _verifyOtp() async {
  if (_isOtpExpired) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP has expired. Please request a new one.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final enteredOtp = _controllers.map((controller) => controller.text).join();
  if (enteredOtp.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a complete OTP.')),
    );
    return;
  }

  if (enteredOtp == _generatedOtp) {
    _timer?.cancel();

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Directly send password reset email
      // Firebase will handle whether the user exists or not
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Reset Email Sent'),
          content: Text(
              'If an account with ${widget.email} exists, a password reset email has been sent. Please check your inbox and spam folder.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.pop(context); // go back to login screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incorrect OTP entered'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

}
