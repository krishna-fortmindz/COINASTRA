import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../remote/api_client.dart';
import '../end_points.dart';

/// Hanging tab anchored to the right edge of every dashboard screen.
class FeedbackTab extends StatelessWidget {
  const FeedbackTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => _showFeedbackDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withAlpha(210),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withAlpha(90),
                  blurRadius: 14,
                  offset: const Offset(-3, 0),
                ),
              ],
            ),
            child: const RotatedBox(
              quarterTurns: 3,
              child: Text(
                'Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showFeedbackDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Feedback',
    barrierColor: Colors.black.withAlpha(140),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => const _FeedbackDialog(),
  );
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog();

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  int _rating = 0;
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final message = _msgCtrl.text.trim();

    if (email.isEmpty || message.isEmpty || _rating == 0) {
      setState(() => _error = 'Please fill all fields and select a rating.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiClient.instance.post(
        EndPoints.feedback,
        data: {'email': email, 'message': message, 'rating': _rating},
      );
      if (mounted) setState(() { _success = true; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to submit. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: _success ? _SuccessView(onClose: () => Navigator.pop(context)) : _FormBody(
          emailCtrl: _emailCtrl,
          msgCtrl: _msgCtrl,
          rating: _rating,
          loading: _loading,
          error: _error,
          onRating: (r) => setState(() => _rating = r),
          onSubmit: _submit,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController msgCtrl;
  final int rating;
  final bool loading;
  final String? error;
  final ValueChanged<int> onRating;
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  const _FormBody({
    required this.emailCtrl,
    required this.msgCtrl,
    required this.rating,
    required this.loading,
    required this.error,
    required this.onRating,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rate_review_rounded,
                    color: AppColors.brandPurple, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share Feedback',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                    Text('Help us improve Coinastra',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Star rating
          const Text('How would you rate your experience?',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 8),
          _StarRow(rating: rating, onTap: onRating),

          const SizedBox(height: 16),

          // Email field
          _Field(
            controller: emailCtrl,
            label: 'Your email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),

          // Message field
          _Field(
            controller: msgCtrl,
            label: 'Message',
            hint: 'Tell us what you think, report a bug, or suggest a feature…',
            maxLines: 4,
          ),

          if (error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 13, color: AppColors.brandRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(error!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.brandRed)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple.withAlpha(200),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.brandPurple.withAlpha(80),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Submit Feedback',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Star Row ─────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onTap;
  const _StarRow({required this.rating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: () => onTap(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? const Color(0xFFFFB800) : AppColors.textMuted,
              size: 26,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Text Field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppColors.textMuted.withAlpha(120), fontSize: 12),
            filled: true,
            fillColor: AppColors.bgSecondary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: AppColors.brandPurple.withAlpha(150)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Success ─────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.brandGreen, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Thank you!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            "Your feedback has been submitted.\nWe'll use it to make Coinastra better.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onClose,
            child: const Text('Close',
                style: TextStyle(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
