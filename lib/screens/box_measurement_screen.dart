import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../data/box_measurement_model.dart';
import '../data/history_db.dart';
import 'box_history_screen.dart';

class BoxMeasurementScreen extends StatefulWidget {
  final String? initialValue;
  const BoxMeasurementScreen({super.key, this.initialValue});

  @override
  State<BoxMeasurementScreen> createState() => _BoxMeasurementScreenState();
}

class _BoxMeasurementScreenState extends State<BoxMeasurementScreen> {
  double _length = 40.0;
  double _width = 25.0;
  double _height = 20.0;
  String _unit = 'cm'; // cm, m, mm, in, ft, yd

  // 3D rotation angles & zoom
  double _rotY = -0.65; // around Y axis
  double _rotX = 0.45;  // around X axis
  double _zoom = 1.0;   // 0.4x to 2.5x
  double _baseZoom = 1.0;

  final List<String> _units = ['cm', 'm', 'mm', 'in', 'ft', 'yd'];

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Shoebox', 'l': 33.0, 'w': 20.0, 'h': 12.0, 'unit': 'cm'},
    {'name': 'Small Parcel', 'l': 20.0, 'w': 15.0, 'h': 10.0, 'unit': 'cm'},
    {'name': 'Medium Box', 'l': 35.0, 'w': 25.0, 'h': 20.0, 'unit': 'cm'},
    {'name': 'Large Box', 'l': 50.0, 'w': 40.0, 'h': 30.0, 'unit': 'cm'},
    {'name': 'Cube 30cm', 'l': 30.0, 'w': 30.0, 'h': 30.0, 'unit': 'cm'},
    {'name': 'Pallet Size', 'l': 120.0, 'w': 80.0, 'h': 140.0, 'unit': 'cm'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      final v = double.tryParse(widget.initialValue!);
      if (v != null && v > 0) {
        _length = v;
      }
    }
  }

  // ── Unit Conversions ────────────────────────────────────────────────────────
  double _toMeters(double val, String unit) {
    switch (unit) {
      case 'm':  return val;
      case 'cm': return val * 0.01;
      case 'mm': return val * 0.001;
      case 'in': return val * 0.0254;
      case 'ft': return val * 0.3048;
      case 'yd': return val * 0.9144;
      default:   return val * 0.01;
    }
  }

  double get _lengthInMeters => _toMeters(_length, _unit);
  double get _widthInMeters  => _toMeters(_width, _unit);
  double get _heightInMeters => _toMeters(_height, _unit);

  // Volume in m³
  double get _volumeInMeters3 =>
      _lengthInMeters * _widthInMeters * _heightInMeters;

  // Surface Area in m²
  double get _surfaceAreaInMeters2 =>
      2 * ((_lengthInMeters * _widthInMeters) +
          (_lengthInMeters * _heightInMeters) +
          (_widthInMeters * _heightInMeters));

  // Space Diagonal in meters
  double get _diagonalInMeters => math.sqrt(
      (_lengthInMeters * _lengthInMeters) +
      (_widthInMeters * _widthInMeters) +
      (_heightInMeters * _heightInMeters));

  // Volumetric weight (Air freight divisor 5000 in cm)
  double get _volumetricWeightKg {
    final lCm = _lengthInMeters * 100;
    final wCm = _widthInMeters * 100;
    final hCm = _heightInMeters * 100;
    return (lCm * wCm * hCm) / 5000;
  }

  String _fmt(double v, [int decimals = 2]) {
    if (v.abs() >= 1000000) return v.toStringAsExponential(2);
    if (v == v.truncateToDouble() && decimals <= 2) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(decimals).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _applyPreset(Map<String, dynamic> p) {
    HapticFeedback.lightImpact();
    setState(() {
      _length = p['l'] as double;
      _width  = p['w'] as double;
      _height = p['h'] as double;
      _unit   = p['unit'] as String;
    });
  }

  void _showDimensionEditor(String dimensionName, double currentVal, ValueChanged<double> onSubmitted) {
    final controller = TextEditingController(text: currentVal.toStringAsFixed(currentVal.truncateToDouble() == currentVal ? 0 : 2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBtnBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter $dimensionName ($_unit)',
          style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: kTextPrimary, fontSize: 20),
          decoration: InputDecoration(
            suffixText: _unit,
            suffixStyle: const TextStyle(color: kOrange, fontSize: 16),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0) {
                onSubmitted(parsed);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyAllSpecs() {
    final vLiters = _volumeInMeters3 * 1000;
    final vCm3 = _volumeInMeters3 * 1000000;
    final vFt3 = _volumeInMeters3 / (0.3048 * 0.3048 * 0.3048);
    final text = '3D Box Measurements:\n'
        '• Dimensions: $_length × $_width × $_height $_unit\n'
        '• Volume: ${_fmt(vLiters, 2)} L (${_fmt(_volumeInMeters3, 4)} m³ / ${_fmt(vCm3, 0)} cm³ / ${_fmt(vFt3, 2)} ft³)\n'
        '• Surface Area: ${_fmt(_surfaceAreaInMeters2 * 10000, 1)} cm² (${_fmt(_surfaceAreaInMeters2, 3)} m²)\n'
        '• Diagonal: ${_fmt(_diagonalInMeters * 100, 1)} cm\n'
        '• Volumetric Wt: ${_fmt(_volumetricWeightKg, 2)} kg (air freight)';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kBtnBase,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('Box measurements & specs copied!', style: TextStyle(color: kTextPrimary)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _saveToHistory() async {
    String suggestedName = 'Box ${_fmt(_length)}×${_fmt(_width)}×${_fmt(_height)} $_unit';
    for (final p in _presets) {
      if (_length == p['l'] && _width == p['w'] && _height == p['h'] && _unit == p['unit']) {
        suggestedName = p['name'] as String;
        break;
      }
    }

    final nameController = TextEditingController(text: suggestedName);

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBtnBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: kOrange, size: 22),
            SizedBox(width: 10),
            Text('Save Box to History', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a label for this 3D box measurement:', style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: kTextPrimary, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: kOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_fmt(_length)} × ${_fmt(_width)} × ${_fmt(_height)} $_unit • ${_fmt(_volumeInMeters3 * 1000, 2)} L',
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(
              ctx,
              nameController.text.trim().isEmpty ? suggestedName : nameController.text.trim(),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != null && confirmed.isNotEmpty) {
      final measurement = BoxMeasurement(
        title: confirmed,
        length: _length,
        width: _width,
        height: _height,
        unit: _unit,
        volumeLiters: _volumeInMeters3 * 1000,
        volumeM3: _volumeInMeters3,
        surfaceAreaCm2: _surfaceAreaInMeters2 * 10000,
        volumetricWeightKg: _volumetricWeightKg,
      );

      await HistoryDb.instance.insertBoxMeasurement(measurement);
      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kBtnBase,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Saved "$confirmed" to box history', style: const TextStyle(color: kTextPrimary)),
            action: SnackBarAction(
              label: 'View History',
              textColor: kOrange,
              onPressed: _openHistory,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.push<BoxMeasurement>(
      context,
      MaterialPageRoute(builder: (_) => const BoxHistoryScreen()),
    );

    if (selected != null && mounted) {
      setState(() {
        _length = selected.length;
        _width = selected.width;
        _height = selected.height;
        _unit = selected.unit;
      });
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kBtnBase,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Loaded "${selected.title}" (${_fmt(selected.length)}×${_fmt(selected.width)}×${_fmt(selected.height)} ${selected.unit})',
            style: const TextStyle(color: kTextPrimary),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                // ── Top Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      _buildHeaderBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '3D Box Measurement',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // History
                      _buildHeaderBtn(
                        icon: Icons.history_rounded,
                        tooltip: 'Box History',
                        onTap: _openHistory,
                      ),
                      const SizedBox(width: 8),
                      // Reset view
                      _buildHeaderBtn(
                        icon: Icons.restart_alt_rounded,
                        tooltip: 'Reset 3D View & Zoom',
                        onTap: () {
                          setState(() {
                            _rotX = 0.45;
                            _rotY = -0.65;
                            _zoom = 1.0;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Copy specs
                      _buildHeaderBtn(
                        icon: Icons.copy_rounded,
                        tooltip: 'Copy Specs',
                        onTap: _copyAllSpecs,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    children: [
                      // ── 3D Interactive Canvas ───────────────────────────
                      _buildInteractive3DCanvas(),
                      const SizedBox(height: 14),

                      // ── Presets Chips ───────────────────────────────────
                      _buildPresetsRow(),
                      const SizedBox(height: 14),

                      // ── Dimension Controls (L, W, H & Unit) ─────────────
                      _buildDimensionsInputCard(),
                      const SizedBox(height: 14),

                      // ── Calculations & Conversion Results ───────────────
                      _buildCalculationResultsCard(),
                      const SizedBox(height: 14),

                      // ── Bottom Action: Save to History & Use in Calculator ──
                      _buildBottomActionButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _zoomIn() {
    HapticFeedback.lightImpact();
    setState(() {
      _zoom = (_zoom + 0.15).clamp(0.4, 2.5);
    });
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    setState(() {
      _zoom = (_zoom - 0.15).clamp(0.4, 2.5);
    });
  }

  void _resetZoom() {
    HapticFeedback.lightImpact();
    setState(() {
      _zoom = 1.0;
    });
  }

  // ── 3D Box Interactive Canvas ──────────────────────────────────────────────
  Widget _buildInteractive3DCanvas() {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: kBtnBase,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: kShadowLight, offset: Offset(-2.5, -2.5), blurRadius: 5),
          BoxShadow(color: kShadowDark, offset: Offset(2.5, 2.5), blurRadius: 5),
        ],
      ),
      child: Stack(
        children: [
          // Drag to rotate, pinch to zoom gesture area & mouse wheel scroll zoom
          Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                setState(() {
                  if (event.scrollDelta.dy < 0) {
                    _zoom = (_zoom + 0.1).clamp(0.4, 2.5);
                  } else if (event.scrollDelta.dy > 0) {
                    _zoom = (_zoom - 0.1).clamp(0.4, 2.5);
                  }
                });
              }
            },
            child: GestureDetector(
              onScaleStart: (details) {
                _baseZoom = _zoom;
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Pinch to zoom with 2 fingers or significant scale change
                  if (details.pointerCount > 1 || (details.scale - 1.0).abs() > 0.03) {
                    _zoom = (_baseZoom * details.scale).clamp(0.4, 2.5);
                  }
                  // Spin/pan
                  _rotY += details.focalPointDelta.dx * 0.012;
                  _rotX -= details.focalPointDelta.dy * 0.012;
                  _rotX = _rotX.clamp(-1.2, 1.2);
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  size: const Size(double.infinity, 230),
                  painter: _Box3DPainter(
                    length: _length,
                    width: _width,
                    height: _height,
                    unit: _unit,
                    rotX: _rotX,
                    rotY: _rotY,
                    zoom: _zoom,
                  ),
                ),
              ),
            ),
          ),

          // Top left 3D badge & gesture hint
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.threed_rotation_rounded, color: kOrange, size: 14),
                  SizedBox(width: 4),
                  Text('Spin & Zoom', style: TextStyle(color: kTextSecondary, fontSize: 11)),
                ],
              ),
            ),
          ),

          // Top right dedicated Zoom Controls toolbar
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF191919).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF333333)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildZoomIconBtn(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zoom Out',
                    onTap: _zoomOut,
                  ),
                  GestureDetector(
                    onTap: _resetZoom,
                    child: Tooltip(
                      message: 'Reset Zoom (100%)',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        color: Colors.transparent,
                        child: Text(
                          '${(_zoom * 100).round()}%',
                          style: const TextStyle(
                            color: kOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildZoomIconBtn(
                    icon: Icons.add_rounded,
                    tooltip: 'Zoom In',
                    onTap: _zoomIn,
                  ),
                ],
              ),
            ),
          ),

          // Bottom right quick orientation tags
          Positioned(
            bottom: 10,
            right: 12,
            child: Row(
              children: [
                _buildQuickAngleBtn('Iso', -0.65, 0.45),
                const SizedBox(width: 6),
                _buildQuickAngleBtn('Top', 0.0, 1.35),
                const SizedBox(width: 6),
                _buildQuickAngleBtn('Front', 0.0, 0.0),
                const SizedBox(width: 6),
                _buildQuickAngleBtn('Fit', -0.65, 0.45, resetZoom: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Icon(icon, color: kTextPrimary, size: 16),
        ),
      ),
    );
  }

  Widget _buildQuickAngleBtn(String label, double y, double x, {bool resetZoom = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _rotY = y;
          _rotX = x;
          if (resetZoom) _zoom = 1.0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ── Presets Row ────────────────────────────────────────────────────────────
  Widget _buildPresetsRow() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = _presets[i];
          final isCurrent = _length == p['l'] && _width == p['w'] && _height == p['h'] && _unit == p['unit'];
          return GestureDetector(
            onTap: () => _applyPreset(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent ? kOrange : kBtnBase,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: kShadowLight, offset: Offset(-1.5, -1.5), blurRadius: 3),
                  BoxShadow(color: kShadowDark, offset: Offset(1.5, 1.5), blurRadius: 3),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                p['name'] as String,
                style: TextStyle(
                  color: isCurrent ? Colors.white : kTextPrimary,
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dimension Inputs Card (L, W, H & Unit) ──────────────────────────────────
  Widget _buildDimensionsInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBtnBase,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: kShadowLight, offset: Offset(-2.5, -2.5), blurRadius: 5),
          BoxShadow(color: kShadowDark, offset: Offset(2.5, 2.5), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Unit Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BOX DIMENSIONS',
                style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1),
              ),
              // Unit switcher chip
              _buildUnitSelector(),
            ],
          ),
          const SizedBox(height: 12),

          // Length Row
          _buildDimensionRow(
            label: 'Length (L)',
            color: const Color(0xFF4A90E2),
            value: _length,
            onDecrement: () {
              if (_length > 1) setState(() => _length = math.max(0.5, _length - 1));
            },
            onIncrement: () {
              setState(() => _length += 1);
            },
            onTapValue: () => _showDimensionEditor('Length', _length, (v) => setState(() => _length = v)),
          ),
          const Divider(color: Color(0xFF2C2C2C), height: 16),

          // Width Row
          _buildDimensionRow(
            label: 'Width (W)',
            color: const Color(0xFF50E3C2),
            value: _width,
            onDecrement: () {
              if (_width > 1) setState(() => _width = math.max(0.5, _width - 1));
            },
            onIncrement: () {
              setState(() => _width += 1);
            },
            onTapValue: () => _showDimensionEditor('Width', _width, (v) => setState(() => _width = v)),
          ),
          const Divider(color: Color(0xFF2C2C2C), height: 16),

          // Height Row
          _buildDimensionRow(
            label: 'Height (H)',
            color: kOrange,
            value: _height,
            onDecrement: () {
              if (_height > 1) setState(() => _height = math.max(0.5, _height - 1));
            },
            onIncrement: () {
              setState(() => _height += 1);
            },
            onTapValue: () => _showDimensionEditor('Height', _height, (v) => setState(() => _height = v)),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionRow({
    required String label,
    required Color color,
    required double value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onTapValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        Row(
          children: [
            _buildStepperBtn(icon: Icons.remove, onTap: onDecrement),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onTapValue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Text(
                  '${_fmt(value)} $_unit',
                  style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildStepperBtn(icon: Icons.add, color: color, onTap: onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperBtn({required IconData icon, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Icon(icon, color: color ?? kTextSecondary, size: 16),
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kOrange.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unit,
          dropdownColor: kBtnBase,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: kOrange, size: 18),
          isDense: true,
          style: const TextStyle(color: kOrange, fontSize: 13, fontWeight: FontWeight.bold),
          items: _units.map((u) {
            return DropdownMenuItem<String>(
              value: u,
              child: Text(u, style: const TextStyle(color: kTextPrimary)),
            );
          }).toList(),
          onChanged: (newUnit) {
            if (newUnit != null) {
              setState(() => _unit = newUnit);
            }
          },
        ),
      ),
    );
  }

  // ── Calculations & Conversion Results Card ─────────────────────────────────
  Widget _buildCalculationResultsCard() {
    final vLiters = _volumeInMeters3 * 1000;
    final vCm3 = _volumeInMeters3 * 1000000;
    final vFt3 = _volumeInMeters3 / (0.3048 * 0.3048 * 0.3048);
    final vGal = _volumeInMeters3 * 264.172;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBtnBase,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: kShadowLight, offset: Offset(-2.5, -2.5), blurRadius: 5),
          BoxShadow(color: kShadowDark, offset: Offset(2.5, 2.5), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Volume Highlight
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL VOLUME',
                      style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_fmt(vLiters, 2)} Liters',
                        style: const TextStyle(color: kOrange, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Text(
                  '${_fmt(_volumeInMeters3, 4)} m³',
                  style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2C2C2C), height: 1),
          const SizedBox(height: 12),

          // Multi-Unit Volume Conversions
          const Text(
            'VOLUME CONVERSIONS',
            style: TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.9),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Cubic Cm', '${_fmt(vCm3, 0)} cm³')),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Cubic Feet', '${_fmt(vFt3, 2)} ft³')),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Gallons (US)', '${_fmt(vGal, 2)} gal')),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2C2C2C), height: 1),
          const SizedBox(height: 12),

          // Surface Area & Diagonal & Volumetric Weight
          const Text(
            'SURFACE & SHIPPING SPECS',
            style: TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.9),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Surface Area',
                  '${_fmt(_surfaceAreaInMeters2 * 10000, 1)} cm²',
                  sub: '${_fmt(_surfaceAreaInMeters2, 3)} m²',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  '3D Diagonal',
                  '${_fmt(_diagonalInMeters * 100, 1)} cm',
                  sub: '${_fmt(_diagonalInMeters / 0.0254, 1)} in',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Vol. Wt (/5000)',
                  '${_fmt(_volumetricWeightKg, 2)} kg',
                  sub: '${_fmt(_volumetricWeightKg * 2.20462, 2)} lb',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, {String? sub}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kTextSecondary, fontSize: 9.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(sub, style: const TextStyle(color: kTextSecondary, fontSize: 9)),
          ],
        ],
      ),
    );
  }

  // ── Bottom Action Buttons ──────────────────────────────────────────────────
  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: _saveToHistory,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: kBtnBase,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kOrange.withValues(alpha: 0.5), width: 1.2),
              boxShadow: const [
                BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
                BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
              ],
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_add_rounded, color: kOrange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Box to History',
                  style: TextStyle(
                    color: kOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildUseInCalculatorButton(),
      ],
    );
  }

  // ── Use in Calculator Button ───────────────────────────────────────────────
  Widget _buildUseInCalculatorButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context, _fmt(_volumeInMeters3 * 1000, 2));
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: kOrange,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kOrange.withValues(alpha: 0.35),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Use Volume in Calculator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBtn({required IconData icon, required VoidCallback onTap, String? tooltip}) {
    Widget btn = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: kBtnBase,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: kShadowLight, offset: Offset(-2, -2), blurRadius: 4),
            BoxShadow(color: kShadowDark, offset: Offset(2, 2), blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: kTextPrimary, size: 18),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }
}

// ── 3D Box Custom Painter ───────────────────────────────────────────────────
class _Box3DPainter extends CustomPainter {
  final double length;
  final double width;
  final double height;
  final String unit;
  final double rotX;
  final double rotY;
  final double zoom;

  _Box3DPainter({
    required this.length,
    required this.width,
    required this.height,
    required this.unit,
    required this.rotX,
    required this.rotY,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);

    // Normalize proportions: clamp aspect ratio so extreme boxes still render nicely
    final maxD = math.max(length, math.max(width, height));
    final safeMax = maxD <= 0 ? 1.0 : maxD;

    final scaleFactor = 105.0 / safeMax;
    final halfL = ((length * scaleFactor).clamp(18.0, 115.0)) * zoom;
    final halfW = ((width * scaleFactor).clamp(18.0, 115.0)) * zoom;
    final halfH = ((height * scaleFactor).clamp(18.0, 115.0)) * zoom;

    // 8 3D vertices of cuboid centered at origin
    final rawVertices = [
      [-halfL, -halfH, -halfW], // 0: Front top left
      [ halfL, -halfH, -halfW], // 1: Front top right
      [ halfL,  halfH, -halfW], // 2: Front bottom right
      [-halfL,  halfH, -halfW], // 3: Front bottom left
      [-halfL, -halfH,  halfW], // 4: Back top left
      [ halfL, -halfH,  halfW], // 5: Back top right
      [ halfL,  halfH,  halfW], // 6: Back bottom right
      [-halfL,  halfH,  halfW], // 7: Back bottom left
    ];

    // Rotate and Project to 2D
    final projected = <Offset>[];
    final rotatedZ = <double>[];

    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);

    for (final v in rawVertices) {
      final x = v[0];
      final y = v[1];
      final z = v[2];

      // Rotate around Y
      final x1 = x * cosY + z * sinY;
      final z1 = -x * sinY + z * cosY;

      // Rotate around X
      final y2 = y * cosX - z1 * sinX;
      final z2 = y * sinX + z1 * cosX;

      // Perspective projection
      const distance = 420.0;
      final f = distance / (distance + z2);
      projected.add(Offset(center.dx + x1 * f, center.dy + y2 * f));
      rotatedZ.add(z2);
    }

    // Ground shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + halfH * 0.95), width: halfL * 2.1, height: halfW * 1.1),
      shadowPaint,
    );

    // Define 6 faces by vertex indices
    final faces = [
      {'idx': [0, 1, 2, 3], 'name': 'front'},
      {'idx': [5, 4, 7, 6], 'name': 'back'},
      {'idx': [4, 5, 1, 0], 'name': 'top'},
      {'idx': [3, 2, 6, 7], 'name': 'bottom'},
      {'idx': [4, 0, 3, 7], 'name': 'left'},
      {'idx': [1, 5, 6, 2], 'name': 'right'},
    ];

    // Compute average Z for depth sorting (Painter's algorithm: draw farthest first)
    for (final f in faces) {
      final idxs = f['idx'] as List<int>;
      final avgZ = (rotatedZ[idxs[0]] + rotatedZ[idxs[1]] + rotatedZ[idxs[2]] + rotatedZ[idxs[3]]) / 4.0;
      f['avgZ'] = avgZ;
    }

    faces.sort((a, b) => (b['avgZ'] as double).compareTo(a['avgZ'] as double));

    // Paints
    final edgePaint = Paint()
      ..color = kOrange.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final innerEdgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw faces
    for (final f in faces) {
      final idxs = f['idx'] as List<int>;
      final name = f['name'] as String;

      final p0 = projected[idxs[0]];
      final p1 = projected[idxs[1]];
      final p2 = projected[idxs[2]];
      final p3 = projected[idxs[3]];

      // Cross product for back-face culling / lighting intensity
      final cross = (p1.dx - p0.dx) * (p2.dy - p0.dy) - (p1.dy - p0.dy) * (p2.dx - p0.dx);
      final isFacingCamera = cross > 0;

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();

      if (isFacingCamera) {
        Color faceColor;
        switch (name) {
          case 'top':
            faceColor = const Color(0xFF383838); // Highlighted top face
          case 'front':
            faceColor = const Color(0xFF2C2C2C); // Medium front face
          case 'right':
            faceColor = const Color(0xFF222222); // Shaded right face
          case 'left':
            faceColor = const Color(0xFF242424);
          default:
            faceColor = const Color(0xFF1E1E1E);
        }

        final fillPaint = Paint()..color = faceColor;
        canvas.drawPath(path, fillPaint);

        // Subtle gradient highlight
        final highlightPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kOrange.withValues(alpha: name == 'top' ? 0.18 : 0.08),
              Colors.transparent,
            ],
          ).createShader(path.getBounds());
        canvas.drawPath(path, highlightPaint);

        canvas.drawPath(path, edgePaint);
      } else {
        // Hidden / back faces drawn faint
        canvas.drawPath(path, innerEdgePaint);
      }
    }

    // Draw Dimension Labels along edges
    _drawDimensionLabel(canvas, projected[3], projected[2], 'L: ${length.toStringAsFixed(0)} $unit', const Color(0xFF4A90E2));
    _drawDimensionLabel(canvas, projected[2], projected[6], 'W: ${width.toStringAsFixed(0)} $unit', const Color(0xFF50E3C2));
    _drawDimensionLabel(canvas, projected[1], projected[2], 'H: ${height.toStringAsFixed(0)} $unit', kOrange);
  }

  void _drawDimensionLabel(Canvas canvas, Offset pA, Offset pB, String text, Color color) {
    final mid = Offset((pA.dx + pB.dx) / 2, (pA.dy + pB.dy) / 2);
    final fontSize = (10.0 * zoom.clamp(0.8, 1.25)).clamp(9.0, 13.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withValues(alpha: 0.65),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _Box3DPainter old) {
    return old.length != length ||
        old.width != width ||
        old.height != height ||
        old.unit != unit ||
        old.rotX != rotX ||
        old.rotY != rotY ||
        old.zoom != zoom;
  }
}
