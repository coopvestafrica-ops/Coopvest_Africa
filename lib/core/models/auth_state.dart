enum AuthState {
  initial,
  authenticating,
  authenticated,
  error,
  unauthenticated,
  biometricRequired,
  mfaRequired,
  sessionExpired,
  accountLocked,
  verificationRequired,
}
