import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final Color? valueColor;
  final String? subtitle;

  const ResultCard({
    super.key,
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? AppColors.primary : AppColors.textHint,
              fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: valueColor ??
                  (isHighlighted ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ResultSummaryCard extends StatelessWidget {
  final List<ResultItem> items;
  final String? title;
  final VoidCallback? onCopy;

  const ResultSummaryCard({
    super.key,
    required this.items,
    this.title,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (onCopy != null)
                    GestureDetector(
                      onTap: onCopy,
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          Divider(
            height: 1,
            color: AppColors.border,
            indent: title != null ? 0 : 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items
                  .map((item) => _buildRow(item, isLast: item == items.last))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ResultItem item, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                color: item.isHighlighted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: item.isHighlighted
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            item.value,
            style: TextStyle(
              fontSize: item.isHighlighted ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: item.color ??
                  (item.isHighlighted
                      ? AppColors.primary
                      : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultItem {
  final String label;
  final String value;
  final bool isHighlighted;
  final Color? color;

  const ResultItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.color,
  });
}

class AnimatedResultValue extends StatefulWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;

  const AnimatedResultValue({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
  });

  @override
  State<AnimatedResultValue> createState() => _AnimatedResultValueState();
}

class _AnimatedResultValueState extends State<AnimatedResultValue>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedResultValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          Clipboard.setData(ClipboardData(
            text: widget.formatter(widget.value),
          ));
        },
        child: Text(
          widget.formatter(_animation.value),
          style: widget.style ??
              const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
      ),
    );
  }
}

class CopyableResult extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const CopyableResult({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.selectionClick();
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: valueStyle ??
                      const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.copy_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
