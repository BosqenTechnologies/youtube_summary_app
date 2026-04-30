/// Maps raw Supabase/network error messages to clean,
/// user-readable strings that make sense to non-technical users.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String map(String rawMessage) {
    final msg = rawMessage.toLowerCase().trim();

    // ── OTP Errors ────────────────────────────────────────────────────────────
    if (msg.contains('invalid') && (msg.contains('otp') || msg.contains('token'))) {
      return 'The code you entered is incorrect. Please check and try again.';
    }
    if (msg.contains('expired') || msg.contains('otp expired')) {
      return 'This code has expired. Please request a new one.';
    }
    if (msg.contains('already used') || msg.contains('token has been used')) {
      return 'This code has already been used. Please request a new one.';
    }

    // ── Email Errors ──────────────────────────────────────────────────────────
    if (msg.contains('invalid email') || msg.contains('email is invalid')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Your email is not verified. Please check your inbox.';
    }
    if (msg.contains('user not found') || msg.contains('no user found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('email address not authorized') || msg.contains('not authorized')) {
      return 'This email address is not allowed to sign in.';
    }

    // ── Rate Limit Errors ─────────────────────────────────────────────────────
    if (msg.contains('rate limit') || msg.contains('too many requests') || msg.contains('429')) {
      return 'Too many attempts. Please wait a minute before trying again.';
    }
    if (msg.contains('email rate limit exceeded') || msg.contains('for security purposes')) {
      return 'Too many sign-in requests. Please wait 60 seconds before requesting a new code.';
    }
    if (msg.contains('request this after')) {
      return 'Please wait before requesting another code.';
    }

    // ── Network / Connectivity Errors ─────────────────────────────────────────
    if (msg.contains('network') || msg.contains('connection') ||
        msg.contains('socket') || msg.contains('timeout') ||
        msg.contains('unreachable')) {
      return 'Connection problem. Please check your internet and try again.';
    }
    if (msg.contains('failed host lookup') || msg.contains('dns')) {
      return 'Unable to reach the server. Please check your connection.';
    }

    // ── Session / Auth State Errors ───────────────────────────────────────────
    if (msg.contains('session expired') || msg.contains('session not found')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (msg.contains('refresh token') || msg.contains('token expired')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (msg.contains('not authenticated') || msg.contains('unauthorized')) {
      return 'You are not signed in. Please sign in to continue.';
    }

    // ── Signup / Account Errors ───────────────────────────────────────────────
    if (msg.contains('signup') && msg.contains('disabled')) {
      return 'New sign-ups are currently disabled. Please contact support.';
    }
    if (msg.contains('weak password') || msg.contains('password should be')) {
      return 'Password is too weak. Please choose a stronger password.';
    }
    if (msg.contains('same password') || msg.contains('different from the old')) {
      return 'New password must be different from your current password.';
    }

    // ── Server Errors ─────────────────────────────────────────────────────────
    if (msg.contains('500') || msg.contains('internal server') || msg.contains('server error')) {
      return 'Something went wrong on our end. Please try again in a moment.';
    }
    if (msg.contains('503') || msg.contains('service unavailable')) {
      return 'Service is temporarily unavailable. Please try again shortly.';
    }

    // ── Fallback ──────────────────────────────────────────────────────────────
    // If none of the above matched, return a clean generic message
    // Never show raw error messages to users
    return 'Something went wrong. Please try again.';
  }
}