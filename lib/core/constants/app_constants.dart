import 'package:flutter/material.dart';

class AppConstants {
  // App info
  static const String appName = 'Linkzy';
  static const String appTagline = 'Connect. Chat. Link.';
  static const String appVersion = '1.4.0';
  
  // Error messages
  static const String errorEmptyFields = 'Please fill in all fields';
  static const String errorInvalidEmail = 'Please enter a valid email address';
  static const String errorPasswordLength = 'Password must be at least 6 characters';
  static const String errorPasswordMatch = 'Passwords do not match';
  static const String errorUsernameLength = 'Username must be at least 3 characters';
  static const String errorUsernameExists = 'Username already exists';
  static const String errorNetworkConnection = 'Network connection error';
  static const String errorAuthFailed = 'Authentication failed';
  static const String errorSomethingWrong = 'Something went wrong';
  
  // Success messages
  static const String successRegistration = 'Account created successfully';
  static const String successLogin = 'Login successful';
  static const String successPasswordReset = 'Password reset email sent';
  static const String successMessageSent = 'Message sent';
  
  // Button texts
  static const String buttonLogin = 'LOGIN';
  static const String buttonSignUp = 'SIGN UP';
  static const String buttonForgotPassword = 'RESET PASSWORD';
  static const String buttonSend = 'SEND';
  static const String buttonSave = 'SAVE';
  static const String buttonCancel = 'CANCEL';
  static const String buttonLogout = 'LOGOUT';
} 