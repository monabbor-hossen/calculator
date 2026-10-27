import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/number_formatter.dart';
import '../data/history_db.dart';
import '../data/tip_calculation_model.dart';
import '../widgets/neumorphic_icon_button.dart';

class TipHistoryScreen extends StatefulWidget {
  const TipHistoryScreen({super.key});

  @override
  State<TipHistoryScreen> createState() => _TipHistoryScreenState();
}

class _TipHistoryScreenState extends State<TipHistoryScreen> {
  late Future<List<TipCalculation>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = HistoryDb.instance.getAllTipHistory();
    });
  }

  Future<void> _deleteItem(TipCalculation item) async {
    if (item.id == null) return;
    await HistoryDb.instance.deleteTipCalculation(item.id!);
    _loadHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kBtnBase,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Deleted split for ${item.currency}${NumberFormatter.formatCurrency(item.perPerson)}',
          style: const TextStyle(color: kTextPrimary),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: kOrange,
          onPressed: () async {
            await HistoryDb.instance.insertTipCalculation(item);
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
          'Clear Split History?',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will permanently delete all saved tip & split bill records.',
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
      await HistoryDb.instance.clearAllTipHistory();
      _loadHistory();
    }
  }

  void _copyBreakdown(TipCalculation item) {
    final text = 'Bill: ${item.currency}${NumberFormatter.formatCurrency(item.bill)}\n'
        'Tip (${item.tipPercent.toInt()}%): ${item.currency}${NumberFormatter.formatCurrency(item.tipAmount)}\n'
        'Total: ${item.currency}${NumberFormatter.formatCurrency(item.total)}\n'
        'Split: ${item.people} ${item.people == 1 ? "Person" : "People"}\n'
        'Each Pays: ${item.currency}${NumberFormatter.formatCurrency(item.perPerson)}';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kBtnBase,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('Breakdown copied to clipboard', style: TextStyle(color: kTextPrimary)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      NeumorphicIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Tip & Split History',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      NeumorphicIconButton(
                        icon: Icons.delete_sweep_rounded,
                        color: kOrange,
                        tooltip: 'Clear All History',
                        onTap: _clearAll,
                      ),
                    ],
                  ),
                ),

                // History List
                Expanded(
                  child: FutureBuilder<List<TipCalculation>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: kOrange),
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildHistoryCard(item);
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

  Widget _buildHistoryCard(TipCalculation item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBtnBase,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: kShadowLight,
            offset: Offset(-2.5, -2.5),
            blurRadius: 5,
          ),
          BoxShadow(
            color: kShadowDark,
            offset: Offset(2.5, 2.5),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: kTextSecondary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.formatTimestamp(item.timestamp),
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _deleteItem(item),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, color: kTextSecondary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main "Each Pays" highlight
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EACH PAYS',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.currency} ${NumberFormatter.formatCurrency(item.perPerson)}',
                    style: const TextStyle(
                      color: kOrange,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                ),
                child: Text(
                  '${item.people} ${item.people == 1 ? "Person" : "People"}',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2C2C2C), height: 1),
          const SizedBox(height: 10),

          // Details grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailColumn('BILL', '${item.currency} ${NumberFormatter.formatCurrency(item.bill)}'),
              _buildDetailColumn(
                'TIP (${item.tipPercent.toInt()}%)',
                '${item.currency} ${NumberFormatter.formatCurrency(item.tipAmount)}',
              ),
              _buildDetailColumn('TOTAL', '${item.currency} ${NumberFormatter.formatCurrency(item.total)}'),
            ],
          ),
          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              // Copy button
              Expanded(
                child: GestureDetector(
                  onTap: () => _copyBreakdown(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, color: kTextSecondary, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Copy Summary',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Restore button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: kOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kOrange.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restore_rounded, color: kOrange, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Load Split',
                          style: TextStyle(
                            color: kOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: kBtnBase,
              shape: BoxShape.circle,
              boxShadow: [
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
            child: const Icon(
              Icons.receipt_long_rounded,
              color: kTextSecondary,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Bill Splits Yet',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Saved tip and split calculations will appear here.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
