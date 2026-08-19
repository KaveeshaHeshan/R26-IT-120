import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/farm.dart';
import '../services/firestore_service.dart';
import '../widgets/hotspot_indicator.dart';
import 'login_screen.dart';
import 'stop_list_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen>
    with SingleTickerProviderStateMixin {

  final FirestoreService _service = FirestoreService();
  StreamSubscription<LatexSession>? _sessionSub;

  String _status = 'idle';
  bool _hasNavigated = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
    // Reset session first so app always starts fresh
    _service.resetSession().then((_) {
      _listenToFirestore();
    });
  }

  void _listenToFirestore() {
    _sessionSub = _service.watchLiveSession().listen((session) {
      if (!mounted) return;
      setState(() {
        _status = session.status;
      });

      if (session.status == 'ready' && !_hasNavigated) {
        _hasNavigated = true;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StopListScreen(farms: session.farms),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  _StatusInfo get _statusInfo {
    switch (_status) {
      case 'uploading':
        return _StatusInfo(
          label: 'Sensor Data Uploading',
          sub: 'IoT readings are being sent via your hotspot...',
          color: AppTheme.accent,
          icon: Icons.cloud_upload_outlined,
        );
      case 'processing':
        return _StatusInfo(
          label: 'Cloud Calculating...',
          sub: 'VFA model is processing the sensor readings',
          color: AppTheme.primaryGlow,
          icon: Icons.memory_outlined,
        );
      case 'ready':
        return _StatusInfo(
          label: 'Results Ready!',
          sub: 'Loading your collection list...',
          color: AppTheme.primary,
          icon: Icons.check_circle_outline,
        );
      default:
        return _StatusInfo(
          label: 'Waiting for Sensors',
          sub: 'Make sure the IoT device is powered on at the farm',
          color: AppTheme.textSecondary,
          icon: Icons.sensors_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 18,
              ),
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
        actions: [
          const HotspotIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                'COLLECTION SESSION',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 36),

              // Animated Pulse Orb
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_status != 'idle')
                          _buildPulseRing(
                            scale: 1.0 + _pulseAnim.value * 0.5,
                            opacity: (1 - _pulseAnim.value) * 0.15,
                            color: info.color,
                            size: 170,
                          ),
                        if (_status != 'idle')
                          _buildPulseRing(
                            scale: 1.0 + _pulseAnim.value * 0.3,
                            opacity: (1 - _pulseAnim.value) * 0.25,
                            color: info.color,
                            size: 140,
                          ),
                        child!,
                      ],
                    );
                  },
                  child: _buildCoreOrb(info),
                ),
              ),

              const SizedBox(height: 36),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  info.label,
                  key: ValueKey(_status),
                  style: GoogleFonts.inter(
                    color: info.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    info.sub,
                    key: ValueKey('${_status}_sub'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              _buildPipelineSteps(),

              const SizedBox(height: 40),

              _buildTestButtons(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoreOrb(_StatusInfo info) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surface,
        border: Border.all(
          color: info.color.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: _status == 'idle'
          ? Icon(info.icon, color: info.color, size: 40)
          : Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      info.color.withOpacity(0.5),
                    ),
                  ),
                ),
                Icon(info.icon, color: info.color, size: 32),
              ],
            ),
    );
  }

  Widget _buildPulseRing({
    required double scale,
    required double opacity,
    required Color color,
    required double size,
  }) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineSteps() {
    final steps = [
      _PipelineStep(
        label: 'Sensor Upload',
        icon: Icons.cloud_upload_outlined,
        isComplete: _status == 'processing' || _status == 'ready',
        isActive: _status == 'uploading',
      ),
      _PipelineStep(
        label: 'VFA Calculation',
        icon: Icons.memory_outlined,
        isComplete: _status == 'ready',
        isActive: _status == 'processing',
      ),
      _PipelineStep(
        label: 'Results Ready',
        icon: Icons.check_circle_outline,
        isComplete: false,
        isActive: _status == 'ready',
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStep(steps[i]),
          if (i < steps.length - 1)
            _buildConnector(isActive: steps[i].isComplete),
        ],
      ],
    );
  }

  Widget _buildStep(_PipelineStep step) {
    final color = step.isActive
        ? AppTheme.accent
        : step.isComplete
            ? AppTheme.primary
            : AppTheme.textMuted;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(step.icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(
            step.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Container(
      width: 28,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 28),
      color: isActive
          ? AppTheme.primary
          : AppTheme.textMuted.withOpacity(0.3),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      children: [
        Text(
          'DEV MODE — TESTING ONLY',
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _hasNavigated = false);
                _service.simulateSensorUpload();
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Simulate Upload'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary, width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _hasNavigated = false);
                _service.resetSession();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(
                  color: AppTheme.textSecondary.withOpacity(0.4),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusInfo {
  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  _StatusInfo({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
  });
}

class _PipelineStep {
  final String label;
  final IconData icon;
  final bool isComplete;
  final bool isActive;
  _PipelineStep({
    required this.label,
    required this.icon,
    required this.isComplete,
    required this.isActive,
  });
}