enum LegalConsentSource {
  emailRegistration('email_registration'),
  googleRegistration('google_registration'),
  googleLogin('google_login'),
  login('login');

  const LegalConsentSource(this.value);

  final String value;
}

class LegalConsentAcceptance {
  const LegalConsentAcceptance({
    required this.source,
    required this.localeCode,
  });

  factory LegalConsentAcceptance.emailRegistration({
    required String localeCode,
  }) => LegalConsentAcceptance(
    source: LegalConsentSource.emailRegistration,
    localeCode: localeCode,
  );

  factory LegalConsentAcceptance.googleRegistration({
    required String localeCode,
  }) => LegalConsentAcceptance(
    source: LegalConsentSource.googleRegistration,
    localeCode: localeCode,
  );

  factory LegalConsentAcceptance.googleLogin({required String localeCode}) =>
      LegalConsentAcceptance(
        source: LegalConsentSource.googleLogin,
        localeCode: localeCode,
      );

  factory LegalConsentAcceptance.login({required String localeCode}) =>
      LegalConsentAcceptance(
        source: LegalConsentSource.login,
        localeCode: localeCode,
      );

  static const termsVersion = '2026-07-07';
  static const privacyPolicyVersion = '2026-07-17';
  static const recordId = 'terms-$termsVersion-privacy-$privacyPolicyVersion';

  final LegalConsentSource source;
  final String localeCode;
}
