import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';

/// A three-step email update dialog:
///   Step 1 — Re-authenticate (current password)
///   Step 2 — Enter new email
///   Step 3 — Success confirmation
///
/// Usage: `UpdateEmailDialog.show(context);`
class UpdateEmailDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _UpdateEmailDialogWidget(),
    );
  }
}

enum _Step { reauth, newEmail, success }

class _UpdateEmailDialogWidget extends StatefulWidget {
  const _UpdateEmailDialogWidget();

  @override
  State<_UpdateEmailDialogWidget> createState() =>
      _UpdateEmailDialogWidgetState();
}

class _UpdateEmailDialogWidgetState extends State<_UpdateEmailDialogWidget>
    with SingleTickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorText;
  _Step _step = _Step.reauth;
  String _newEmailSent = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _newEmailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _transitionTo(_Step next) {
    setState(() {
      _step = next;
      _errorText = null;
    });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  // ── Step 1: Re-authenticate ───────────────────────────────────────────────
  Future<void> _reauth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _errorText = 'No authenticated user found. Please log in again.');
      return;
    }

    setState(() { _isLoading = true; _errorText = null; });

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);
      if (!mounted) return;
      _transitionTo(_Step.newEmail);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _mapReauthError(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Unexpected error during verification. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step 2: Send verification to new email ────────────────────────────────
  Future<void> _sendVerification() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorText = 'Session expired. Please log in again.');
      return;
    }

    final newEmail = _newEmailCtrl.text.trim();

    if (newEmail == user.email) {
      setState(() => _errorText = 'The new email must be different from your current email.');
      return;
    }

    setState(() { _isLoading = true; _errorText = null; });

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      if (!mounted) return;
      setState(() => _newEmailSent = newEmail);
      _transitionTo(_Step.success);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _mapEmailError(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapReauthError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-mismatch':
        return 'Credential does not match the current user.';
      default:
        return 'Verification failed (code: $code). Please try again.';
    }
  }

  String _mapEmailError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already associated with another account.';
      case 'invalid-email':
        return 'The email address format is not valid.';
      case 'requires-recent-login':
        return 'This action requires a fresh sign-in. Please log out and back in, then try again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return 'Email update failed (code: $code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            width: 460,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F2E) : cs.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.06),
                  blurRadius: 20,
                ),
              ],
            ),
            child: switch (_step) {
              _Step.reauth  => _buildReauthView(cs),
              _Step.newEmail => _buildNewEmailView(cs),
              _Step.success  => _buildSuccessView(cs),
            },
          ),
        ),
      ),
    );
  }

  // ── Progress indicator strip ──────────────────────────────────────────────
  Widget _buildStepStrip(ColorScheme cs) {
    final labels = ['Verify Identity', 'New Email', 'Done'];
    final currentStep = _step.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == currentStep;
          final done   = i < currentStep;
          final color  = done || active
              ? AppColors.primaryBlue
              : cs.onSurfaceVariant.withOpacity(0.25);

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.primaryBlue
                            : active
                                ? AppColors.primaryBlue.withOpacity(0.15)
                                : cs.onSurfaceVariant.withOpacity(0.1),
                        border: Border.all(
                          color: color,
                          width: active ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: active
                                      ? AppColors.primaryBlue
                                      : cs.onSurfaceVariant.withOpacity(0.4),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                        color: active
                            ? AppColors.primaryBlue
                            : cs.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2,
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.primaryBlue
                              : cs.onSurfaceVariant.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1 View ───────────────────────────────────────────────────────────
  Widget _buildReauthView(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepStrip(cs),

            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: AppColors.primaryBlue, size: 28),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Verify Your Identity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'For security, please confirm your current password before changing your email.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_passwordVisible,
              autofocus: true,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
                errorText: _errorText,
                errorMaxLines: 2,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Please enter your current password.'
                  : null,
              onFieldSubmitted: (_) => _reauth(),
            ),
            const SizedBox(height: 28),

            _ActionButton(
              label: 'Verify & Continue',
              isLoading: _isLoading,
              onPressed: _reauth,
            ),
            const SizedBox(height: 12),
            _CancelButton(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  // ── Step 2 View ───────────────────────────────────────────────────────────
  Widget _buildNewEmailView(ColorScheme cs) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepStrip(cs),

            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.alternate_email_rounded,
                    color: AppColors.primaryBlue, size: 28),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Enter New Email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enter the new email you\'d like to use. A verification link will be sent there.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Current email chip
            if (user?.email != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email_outlined,
                          size: 14,
                          color: cs.onSurfaceVariant.withOpacity(0.7)),
                      const SizedBox(width: 7),
                      Text(
                        'Current: ${user!.email}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Icon(Icons.arrow_downward_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant.withOpacity(0.3)),
              ),
              const SizedBox(height: 4),
            ],

            TextFormField(
              controller: _newEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'New Email Address',
                prefixIcon:
                    Icon(Icons.email_outlined, color: cs.onSurfaceVariant),
                errorText: _errorText,
                errorMaxLines: 2,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your new email address.';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _sendVerification(),
            ),
            const SizedBox(height: 28),

            _ActionButton(
              label: 'Send Verification Link',
              isLoading: _isLoading,
              onPressed: _sendVerification,
            ),
            const SizedBox(height: 12),
            _CancelButton(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  // ── Step 3 View ───────────────────────────────────────────────────────────
  Widget _buildSuccessView(ColorScheme cs) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepStrip(cs),

          // Success icon
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF4CAF50),
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 22),

          Text(
            'Verification Link Sent!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // New email chip
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email_outlined,
                      size: 15, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _newEmailSent,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'A verification link has been sent to the address above. '
            'Your email will NOT be updated until you open that email and tap the verification link.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // Security alert notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.security_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF59E0B),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Security alert: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'A notification has also been sent to your current email (${user?.email ?? 'your old address'}) '
                              'to inform you of this change request.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.4),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'Cancel',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
