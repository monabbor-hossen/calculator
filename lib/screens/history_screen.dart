import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/number_formatter.dart';
import '../data/calculation_model.dart';
import '../data/history_db.dart';
import '../widgets/neumorphic_icon_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Calculation>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = HistoryDb.instance.getAllHistory();
    });
  }

  Future<void> _deleteItem(Calculation item) async {
    if (item.id == null) return;
    await HistoryDb.instance.deleteCalculation(item.id!);
    _loadHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kBtnBase,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Deleted ${item.result}',
          style: const TextStyle(color: kTextPrimary),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: kOrange,
          onPressed: () async {
            await HistoryDb.instance.insertCalculation(item.expression, item.result);
            _loadHistory();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBtnBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear History?',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will permanently delete all saved calculation history.',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: kOrange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HistoryDb.instance.clearAllHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // ── Top Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Back button
                      NeumorphicIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: 'Back to calculator',
                        size: 44,
                        iconSize: 20,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'History',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Clear All button
                      FutureBuilder<List<Calculation>>(
                        future: _historyFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return NeumorphicIconButton(
                            icon: Icons.delete_sweep_rounded,
                            color: kOrange,
                            tooltip: 'Clear All',
                            size: 44,
                            iconSize: 20,
                            onTap: _clearAll,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── History List ────────────────────────────────────────
                Expanded(
                  child: FutureBuilder<List<Calculation>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: kOrange),
                        );
                      }

                      final list = snapshot.data ?? [];
                      if (list.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return Dismissible(
                            key: ValueKey(item.id ?? '${item.expression}_${item.timestamp.millisecondsSinceEpoch}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _deleteItem(item),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            ),
                            child: _buildHistoryCard(item),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Calculation item) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Tap to load result into calculator
            HapticFeedback.selectionClick();
            Navigator.pop(context, item.result);
          },
          onLongPress: () {
            // Copy full equation
            final fullEquation = '${item.expression} ${item.result}';
            Clipboard.setData(ClipboardData(text: fullEquation));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: kBtnBase,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: Text(
                  'Copied "$fullEquation" to clipboard',
                  style: const TextStyle(color: kTextPrimary),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: kBtnBase,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: kShadowLight,
                  offset: Offset(-3, -3),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: kShadowDark,
                  offset: Offset(3, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timestamp & action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatRelative(item.timestamp),
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Row(
                      children: [
                        // Copy result button
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: item.result));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: kBtnBase,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: Text(
                                  'Copied ${item.result} to clipboard',
                                  style: const TextStyle(color: kTextPrimary),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Tooltip(
                            message: 'Copy result',
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.copy_rounded,
                                color: kTextSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        GestureDetector(
                          onTap: () => _deleteItem(item),
                          child: const Tooltip(
                            message: 'Delete',
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close_rounded,
                                color: kTextSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Expression
                Text(
                  NumberFormatter.formatExpression(item.expression),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                // Result
                Text(
                  NumberFormatter.addCommas(item.result),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kOrange,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: kBtnBase,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kShadowLight,
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: kShadowDark,
                  offset: Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              color: kTextSecondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No History Yet',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completed calculations will appear here',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
