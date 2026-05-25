import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      
      if (message.contains('email not confirm')) {
        return "Please verify your email address before logging in. Check your inbox for the confirmation link.";
      } else if (message.contains('invalid login credentials')) {
        return "Incorrect email or password. Please try again.";
      } else if (message.contains('user already registered')) {
        return "This email is already registered. Please log in instead.";
      } else if (message.contains('password should be at least')) {
        return "Password is too weak. Please use a stronger password.";
      } else if (message.contains('rate limit')) {
        return "Too many requests. Please try again later.";
      }
      
      return error.message; 
    }

    if (error is PostgrestException) {
      if (error.code == '42501') {
        return "You don't have permission to save this. Please make sure you are logged in correctly.";
      }
      if (error.code == '23503') {
        return "Your profile information is missing. Please try logging out and back in, or contact support.";
      }
      return "Database error: ${error.message}";
    }

    if (error is StorageException) {
      final message = error.message.toLowerCase();
      if (message.contains('row-level security') || message.contains('violates row-level security')) {
        return "Permission denied: Please check your Supabase Storage policies for the bucket. You might need to allow 'INSERT' and 'UPDATE' for authenticated users.";
      }
      if (message.contains('bucket not found')) {
        return "Configuration error: Storage bucket not found. Please contact support.";
      }
      if (message.contains('owner only')) {
        return "Permission denied: You can only manage your own files.";
      }
      if (message.contains('object not found')) {
        return "Storage error: The file was not found.";
      }
      return "Storage error: ${error.message}";
    }

    if (error is Exception) {
      final str = error.toString();
      if (str.contains('bro!')) {
        return str.replaceFirst('Exception: ', '').replaceFirst('SystemException: ', '').replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '');
      }
    }
    
    // For debugging other errors in dev
    print("DEBUG: Unexpected error type: ${error.runtimeType}, message: $error");

    return "An unexpected error occurred. Please try again. (Type: ${error.runtimeType})";
  }
}
