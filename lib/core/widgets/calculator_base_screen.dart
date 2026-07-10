import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../../shared/models/calculation_history.dart';
import '../../shared/providers/history_provider.dart';
import '../../shared/providers/favorites_provider.dart';

abstract class CalculatorBaseScreen extends ConsumerStatefulWidget {
  final String calculatorId;
  final String calculatorName;
  final String category;

  const CalculatorBaseScreen({
    super.key,
    required this.calculatorId,
    required this.calculatorName,
    required this.category,
  });
}

abstract class CalculatorBaseState<T extends CalculatorBaseScreen>
    extends ConsumerState<T> {
  final _uuid = const Uuid();

  bool get hasResult;
  Map<String, dynamic> get currentInputs;
  Map<String, dynamic> get currentResults;
  String get resultSummary;

  void saveToHistory() {
    if (!hasResult) return;
    final history = CalculationHistory(
      id: _uuid.v4(),
      calculatorId: widget.calculatorId,
      calculatorName: widget.calculatorName,
      category: widget.category,
      inputs: currentInputs,
      results: currentResults,
      timestamp: DateTime.now(),
      summary: resultSummary,
    );
    ref.read(historyProvider.notifier).addHistory(history);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to history'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void shareResult() {
    if (!hasResult) return;
    final buffer = StringBuffer();
    buffer.writeln('${widget.calculatorName} - ShyBlack Calculator');
    buffer.writeln('');
    buffer.writeln('Inputs:');
    currentInputs.forEach((k, v) => buffer.writeln('  $k: $v'));
    buffer.writeln('');
    buffer.writeln('Results:');
    currentResults.forEach((k, v) => buffer.writeln('  $k: $v'));
    buffer.writeln('');
    buffer.writeln('Calculated using ShyBlack Financial Calculator');
    Share.share(buffer.toString());
  }

  void copyResult() {
    if (!hasResult) return;
    Clipboard.setData(ClipboardData(text: resultSummary));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget buildCalculatorScaffold({
    required Widget body,
    List<Widget>? actions,
  }) {
    final isFavorite = ref.watch(favoritesProvider).contains(widget.calculatorId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.calculatorName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.category,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.error : AppColors.textHint,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggle(widget.calculatorId);
              HapticFeedback.lightImpact();
            },
          ),
          if (hasResult) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: AppColors.textHint),
              onPressed: copyResult,
              tooltip: 'Copy',
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppColors.textHint),
              onPressed: shareResult,
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_add_rounded, color: AppColors.primary),
              onPressed: saveToHistory,
              tooltip: 'Save',
            ),
          ],
          ...?actions,
        ],
      ),
      body: body,
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
