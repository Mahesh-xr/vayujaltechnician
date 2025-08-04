class ValidationUtils {
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    // Check if name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  // Employee ID validation with uniqueness check
  static String? validateEmployeeId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee ID is required';
    }
    if (value.trim().length < 3) {
      return 'Employee ID must be at least 3 characters';
    }
    if (value.trim().length > 20) {
      return 'Employee ID must be less than 20 characters';
    }
    // Allow alphanumeric characters and common separators
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value.trim())) {
      return 'Employee ID can only contain letters, numbers, hyphens, and underscores';
    }
    return null;
  }

  // Mobile number validation
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    
    // Remove any spaces, hyphens, or parentheses
    String cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check for Indian mobile number pattern (with or without country code)
    if (cleanNumber.startsWith('+91')) {
      cleanNumber = cleanNumber.substring(3);
    } else if (cleanNumber.startsWith('91') && cleanNumber.length == 12) {
      cleanNumber = cleanNumber.substring(2);
    }
    
    // Check if it's exactly 10 digits and starts with 6-9
    if (cleanNumber.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanNumber)) {
      return 'Enter a valid 10-digit mobile number starting with 6-9';
    }
    
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    // Basic email regex pattern
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  // Designation validation
  static String? validateDesignation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Designation is required';
    }
    return null;
  }

  // General text field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Password validation (for future use)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Phone number formatter (for display)
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any existing formatting
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Add Indian country code if not present
    if (!cleaned.startsWith('+91') && cleaned.length == 10) {
      cleaned = '+91$cleaned';
    }
    
    // Format as +91 XXXXX XXXXX
    if (cleaned.startsWith('+91') && cleaned.length == 13) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 8)} ${cleaned.substring(8)}';
    }
    
    return phoneNumber; // Return original if formatting fails
  }

  // Check if string contains only numbers
  static bool isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  // Check if string contains only letters
  static bool isAlphabetic(String str) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(str);
  }

  // Check if string is alphanumeric
  static bool isAlphanumeric(String str) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(str);
  }

  // Trim and capitalize first letter of each word
  static String capitalizeWords(String str) {
    return str.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}