Firebase setup for Member 1

1. Open Firebase Console and select fixit-home-knd-g05-4e8e6.
2. Build → Authentication → Get started → Sign-in method → Email/Password → Enable → Save.
3. Build → Firestore Database → Create database → choose your region → Production mode.
4. Firestore → Rules: paste firestore.rules and click Publish.
5. Restart the app. An empty connected database shows no providers until someone registers.
6. Home → Join Pro → fill the form/password → continue → Create account and send verification.
7. Open the email link, return to the app, and tap I verified my email — save profile.
8. Return Home, search the new provider name, then restart to confirm it remains.
9. Use the account icon beside Join Pro to sign in or sign out.

Public providers use the Authentication UID as document ID. Phone/email/area live
in the owner-only provider_private collection. Passwords never enter Firestore.
Email verification does not imply identity, insurance, or background verification.
Real SMS, document uploads, payments, and other members' booking/review persistence
are not connected by this Member 1 implementation. Samples are local fallback only.

If saving fails, remain on verification and retry after correcting Firebase setup.
An Auth account may already exist: do not register it again. After an interrupted
registration, sign in first and refill the registration form using the same email.
Writes may complete after a timeout; retries use the same UID to avoid duplicates.

Reference: https://firebase.google.com/docs/auth/flutter/password-auth
