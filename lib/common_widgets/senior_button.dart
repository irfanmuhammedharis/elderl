import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Senior-friendly large button widget with industrial design
class SeniorButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final bool useGradient;
  final Gradient? gradient;
  final double? width;

  const SeniorButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.useGradient = true,
    this.gradient,
    this.width,
  });

  @override
  State<SeniorButton> createState() => _SeniorButtonState();
}

class _SeniorButtonState extends State<SeniorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = widget.backgroundColor ?? AppTheme.primaryColor;
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(vertical: 18, horizontal: 24);

    final isEmergency = effectiveBackgroundColor == AppTheme.emergencyColor;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          width: widget.width,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? null
                : (widget.useGradient
                    ? (widget.gradient ??
                        (isEmergency
                            ? AppTheme.emergencyGradient
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  effectiveBackgroundColor,
                                  effectiveBackgroundColor.withOpacity(0.85),
                                ],
                              )))
                    : null),
            color: widget.isLoading
                ? effectiveBackgroundColor.withOpacity(0.6)
                : (!widget.useGradient ? effectiveBackgroundColor : null),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: widget.isLoading || widget.onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: effectiveBackgroundColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: effectivePadding,
                child: widget.isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 28,
                              color: widget.textColor ?? Colors.white,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: widget.textColor ?? Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
