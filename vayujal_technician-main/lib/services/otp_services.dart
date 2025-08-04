import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String customerPhone;
  final VoidCallback onVerificationSuccess;

  const OtpVerificationDialog({
    super.key,
    required this.customerPhone,
    required this.onVerificationSuccess,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final OtpService _otpService = OtpService();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isVerifying = false;
  String? _errorMessage;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Format phone number to E.164 format
    String formattedPhone = _formatPhoneNumber(widget.customerPhone);

    _otpService.sendOTP(
      phoneNumber: formattedPhone,
      onCodeSent: () {
        setState(() {
          _isLoading = false;
          _isOtpSent = true;
          _resendCountdown = 60;
        });
        _startResendCountdown();
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
      onVerificationCompleted: (credential) {
        // Auto-verification (rare case)
        Navigator.of(context).pop();
        widget.onVerificationSuccess();
      },
    );
  }

  // Format phone number to E.164 format
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any existing formatting
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it's a 10-digit Indian number, add +91
    if (cleanNumber.length == 10) {
      return '+91$cleanNumber';
    }
    // If it already has country code but no +, add it
    else if (cleanNumber.length > 10 && !phoneNumber.startsWith('+')) {
      return '+$cleanNumber';
    }
    // If it already has +, return as is
    else if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    }
    
    // Default: assume it's Indian number and add +91
    return '+91$cleanNumber';
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      }
    });
  }

  void _verifyOtp() {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    _otpService.verifyOTP(
      otp: _otpController.text,
      onSuccess: () {
        Navigator.of(context).pop();
        widget.onVerificationSuccess();
      },
      onError: (error) {
        setState(() {
          _isVerifying = false;
          _errorMessage = error;
        });
      },
    );
  }

  void _resendOtp() {
    _otpService.resetVerification();
    _sendOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Customer Verification',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              _isOtpSent
                  ? 'We\'ve sent a 6-digit OTP to'
                  : 'Sending OTP to customer phone number',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatPhoneNumber(widget.customerPhone), // Show formatted number
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Loading or OTP Input
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sending OTP...'),
                  ],
                ),
              )
            else if (_isOtpSent) ...[
              // OTP Input Field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue[600]!),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 6) {
                    // Auto-verify when 6 digits are entered
                    _verifyOtp();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive OTP? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _resendOtp,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            if (_isOtpSent)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class OtpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  void sendOTP({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) {
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        onVerificationCompleted(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        String errorMessage = 'Verification failed';
        if (e.code == 'invalid-phone-number') {
          errorMessage = 'The phone number format is invalid';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many requests. Please try again later';
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
        onError(errorMessage);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void verifyOTP({
    required String otp,
    required VoidCallback onSuccess,
    required Function(String error) onError,
  }) async {
    if (_verificationId == null) {
      onError('No verification ID. Please resend OTP.');
      return;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid OTP or verification failed';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP. Please check and try again';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP has expired. Please request a new one';
      }
      onError(errorMessage);
    } catch (e) {
      onError('Invalid OTP or verification failed.');
    }
  }

  void resetVerification() {
    _verificationId = null;
  }
}