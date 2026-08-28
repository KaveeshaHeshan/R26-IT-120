import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/collection_stop.dart';
import '../services/firestore_service.dart';
import '../widgets/hotspot_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_queue_service.dart';

class VerifyScreen extends StatefulWidget {
  final CollectionStop farm;
  final int stopNumber;

  const VerifyScreen({super.key, required this.farm, required this.stopNumber});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _actualAmmoniaController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool? _followedStandardAmmoniaRatio;
  bool _isSigned = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _volumeController.dispose();
    _actualAmmoniaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Get farmer initials for avatar
  String get _initials {
    final parts = widget.farm.farmerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  double? get _recommendedAmmonia {
    final double? volume = double.tryParse(_volumeController.text.trim());
    if (volume == null || !volume.isFinite || volume <= 0) return null;
    return volume * 0.03;
  }

  Future<void> _submitCollection() async {
    final double? volume = double.tryParse(_volumeController.text.trim());

    if (volume == null || !volume.isFinite || volume <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid collected volume',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.riskHigh,
        ),
      );
      return;
    }

    if (_followedStandardAmmoniaRatio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please confirm whether the recommended ammonia amount was added',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.riskMedium,
        ),
      );
      return;
    }

    final double recommendedAmmonia = volume * 0.03;
    final double? actualAmmonia = _followedStandardAmmoniaRatio!
        ? recommendedAmmonia
        : double.tryParse(_actualAmmoniaController.text.trim());
    if (actualAmmonia == null || !actualAmmonia.isFinite || actualAmmonia < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the actual ammonia amount used',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.riskHigh,
        ),
      );
      return;
    }

    if (!_isSigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign the collection record',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.riskMedium,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool savedOnline = false;
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (isOnline) {
        try {
          await FirestoreService().saveCollection(
            farmId: widget.farm.farmerId,
            farmerName: widget.farm.farmerName,
            spoilageScore: widget.farm.spoilageScore,
            vfaResult: widget.farm.vfaResult,
            grade: widget.farm.grade,
            riskLevel: widget.farm.riskLevel,
            volume: volume,
            recommendedAmmoniaL: recommendedAmmonia,
            actualAmmoniaL: actualAmmonia,
            followedStandardAmmoniaRatio: _followedStandardAmmoniaRatio!,
            notes: _notesController.text.trim(),
          );
          savedOnline = true;
        } catch (_) {
          savedOnline = false;
        }
      }

      if (!savedOnline) {
        await OfflineQueueService().addPendingCollection(
          farmId: widget.farm.farmerId,
          farmerName: widget.farm.farmerName,
          spoilageScore: widget.farm.spoilageScore,
          vfaResult: widget.farm.vfaResult,
          grade: widget.farm.grade,
          riskLevel: widget.farm.riskLevel,
          volume: volume,
          recommendedAmmoniaL: recommendedAmmonia,
          actualAmmoniaL: actualAmmonia,
          followedStandardAmmoniaRatio: _followedStandardAmmoniaRatio!,
          notes: _notesController.text.trim(),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save the collection: $error',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.riskHigh,
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (savedOnline ? AppTheme.success : AppTheme.riskMedium)
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                savedOnline
                    ? Icons.check_circle_outline
                    : Icons.cloud_off_outlined,
                color: savedOnline ? AppTheme.success : AppTheme.riskMedium,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              savedOnline ? 'Collection Confirmed!' : 'Saved Offline',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              savedOnline
                  ? '${widget.farm.farmerName} — ${_volumeController.text}L recorded'
                  : '${widget.farm.farmerName} — ${_volumeController.text}L queued.\nWill sync when connection is back.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Back to Stop List',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = AppTheme.riskColor(widget.farm.riskLevel);
    final riskLabel = AppTheme.riskLabel(widget.farm.riskLevel);
    final isHighRisk = widget.farm.riskLevel == 'high';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'LatexGuard',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: const [HotspotIndicator(), SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(
              'COLLECTION VERIFICATION',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // ── Farmer + Grade Card ───────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Risk color bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: riskColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        // Farmer info row
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accent,
                                border: Border.all(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _initials,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.farm.farmerName,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Farm ID: ${widget.farm.farmerId} — Stop ${widget.stopNumber}',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24, color: AppTheme.divider),

                        // Grade + VFA row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Grade
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // Em dash until a sensor reading grades it.
                                  widget.farm.grade ?? '—',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: riskColor,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  'Final Grade',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: riskColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: riskColor),
                                  ),
                                  child: Text(
                                    riskLabel,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: riskColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Sensor VFA when available, otherwise the
                            // predicted spoilage score. These are different
                            // measurements, so the label always says which.
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.farm.hasSensorReading
                                      ? widget.farm.vfaResult!.toStringAsFixed(2)
                                      : widget.farm.spoilageScore
                                          .toStringAsFixed(0),
                                  style: GoogleFonts.jetBrainsMono(
                                    color: riskColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  widget.farm.hasSensorReading
                                      ? 'VFA Result'
                                      : 'Spoilage Risk',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.farm.hasSensorReading
                                      ? 'Threshold: 0.85'
                                      : 'Predicted — no sensor reading',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 24, color: AppTheme.divider),

                        // Stats grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatPill(
                                label: 'pH Level',
                                value: '6.8',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatPill(
                                label: 'Temperature',
                                value: '28°C',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatPill(label: 'DRC', value: '35%'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Warning Box (only for high risk) ──────────
            if (isHighRisk)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.riskHigh.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.riskHigh.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: AppTheme.riskHigh,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'High VFA detected — prioritize factory delivery immediately',
                        style: GoogleFonts.inter(
                          color: AppTheme.riskHigh,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (isHighRisk) const SizedBox(height: 12),

            // ── Collection Details Card ───────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLLECTION DETAILS',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Volume input
                  TextField(
                    controller: _volumeController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Collected volume (litres)',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.water_drop_outlined,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (_recommendedAmmonia != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        'Recommended ammonia: ${_recommendedAmmonia!.toStringAsFixed(2)} L (3 L per 100 L latex)',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Did you add the recommended ammonia amount?',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Yes'),
                            selected: _followedStandardAmmoniaRatio == true,
                            onSelected: (_) => setState(
                              () => _followedStandardAmmoniaRatio = true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('No'),
                            selected: _followedStandardAmmoniaRatio == false,
                            onSelected: (_) => setState(
                              () => _followedStandardAmmoniaRatio = false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_followedStandardAmmoniaRatio == false) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _actualAmmoniaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Actual ammonia added (litres)',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.science_outlined,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.divider,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.divider,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],

                  // Notes input
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Supervisor notes (optional)',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.note_outlined,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),

                  const Divider(height: 24, color: AppTheme.divider),

                  // Digital Signature
                  Text(
                    'DIGITAL SIGNATURE',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      setState(() => _isSigned = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Collection record signed ✓',
                            style: GoogleFonts.inter(),
                          ),
                          backgroundColor: AppTheme.success,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isSigned
                            ? AppTheme.success.withOpacity(0.08)
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSigned
                              ? AppTheme.success
                              : AppTheme.divider,
                          width: _isSigned ? 1.5 : 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: _isSigned
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.success,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Signed successfully',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.textMuted,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to sign collection record',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Submit Button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitCollection,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Confirm Collection',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
