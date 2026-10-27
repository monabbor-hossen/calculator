import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/number_formatter.dart';
import '../data/box_measurement_model.dart';
import '../data/history_db.dart';
import '../widgets/neumorphic_icon_button.dart';

class BoxHistoryScreen extends StatefulWidget {
  const BoxHistoryScreen({super.key});

  @override
  State<BoxHistoryScreen> createState() => _BoxHistoryScreenState();
}

class _BoxHistoryScreenState extends State<BoxHistoryScreen> {
  late Future<List<BoxMeasurement>> _historyFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = HistoryDb.instance.getAllBoxHistory();
    });
  }

  Future<void> _deleteItem(BoxMeasurement item) async {
    if (item.id == null) return;
    await HistoryDb.instance.deleteBoxMeasurement(item.id!);
    _loadHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kBtnBase,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Deleted "${item.title}"',
          style: const TextStyle(color: kTextPrimary),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: kOrange,
          onPressed: () async {
            await HistoryDb.instance.insertBoxMeasurement(item);
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
          'Clear Box History?',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will permanently delete all saved 3D box measurement records.',
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
      await HistoryDb.instance.clearAllBoxHistory();
      _loadHistory();
    }
  }

  String _fmt(double v, [int decimals = 2]) => NumberFormatter.format(v, decimals);

  String _formatTimestamp(DateTime dt) => DateFormatter.formatTimestamp(dt);

  void _copySpecs(BoxMeasurement item) {
    final text = '3D Box Measurement: ${item.title}\n'
        '• Dimensions: ${_fmt(item.length)} × ${_fmt(item.width)} × ${_fmt(item.height)} ${item.unit}\n'
        '• Volume: ${_fmt(item.volumeLiters, 2)} L (${_fmt(item.volumeM3, 4)} m³)\n'
        '• Surface Area: ${_fmt(item.surfaceAreaCm2, 1)} cm²\n'
        '• Volumetric Weight: ${_fmt(item.volumetricWeightKg, 2)} kg';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kBtnBase,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('Box specs copied to clipboard', style: TextStyle(color: kTextPrimary)),
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
                      const Expanded(
                        child: Text(
                          'Box History',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeumorphicIconButton(
                        icon: Icons.delete_sweep_rounded,
                        color: kOrange,
                        tooltip: 'Clear All History',
                        onTap: _clearAll,
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kBtnBase,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: kShadowLight, offset: Offset(-1.5, -1.5), blurRadius: 3),
                        BoxShadow(color: kShadowDark, offset: Offset(1.5, 1.5), blurRadius: 3),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: kTextPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search saved boxes...',
                        hintStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: kTextSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: kTextSecondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // History List
                Expanded(
                  child: FutureBuilder<List<BoxMeasurement>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kOrange));
                      }

                      final items = snapshot.data ?? [];
                      final filtered = _searchQuery.isEmpty
                          ? items
                          : items.where((b) {
                              return b.title.toLowerCase().contains(_searchQuery) ||
                                  '${b.length}x${b.width}x${b.height}'.contains(_searchQuery) ||
                                  b.unit.toLowerCase().contains(_searchQuery);
                            }).toList();

                      if (filtered.isEmpty) {
                        return _buildEmptyState(items.isEmpty);
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildBoxCard(item);
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

  Widget _buildBoxCard(BoxMeasurement item) {
    return Container(
      decoration: BoxDecoration(
        color: kBtnBase,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
          BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, item);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title, 3D Icon, Date & Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: const Icon(Icons.view_in_ar_rounded, color: kOrange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(item.timestamp),
                            style: const TextStyle(color: kTextSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: kTextSecondary, size: 18),
                      tooltip: 'Copy Specs',
                      onPressed: () => _copySpecs(item),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE57373), size: 18),
                      tooltip: 'Delete',
                      onPressed: () => _deleteItem(item),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2C2C2C), height: 1),
                const SizedBox(height: 10),

                // Dimensions Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.straighten_rounded, color: kOrange, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_fmt(item.length)} × ${_fmt(item.width)} × ${_fmt(item.height)} ${item.unit}',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Volume',
                        value: '${_fmt(item.volumeLiters, 2)} L',
                        sub: '${_fmt(item.volumeM3, 4)} m³',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Surface Area',
                        value: '${_fmt(item.surfaceAreaCm2, 1)} cm²',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Vol. Weight',
                        value: '${_fmt(item.volumetricWeightKg, 2)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tap to load hint
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to view in 3D',
                      style: TextStyle(color: kOrange, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, color: kOrange, size: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value, String? sub}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 9.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(sub, style: const TextStyle(color: kTextSecondary, fontSize: 9)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool trulyEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: kBtnBase,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
                BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
              ],
            ),
            child: const Icon(Icons.view_in_ar_rounded, color: kTextSecondary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            trulyEmpty ? 'No Box History Yet' : 'No matching boxes found',
            style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            trulyEmpty
                ? 'Save 3D boxes from the measurement page\nto quickly view and reload them here.'
                : 'Try searching with a different dimension or title.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
