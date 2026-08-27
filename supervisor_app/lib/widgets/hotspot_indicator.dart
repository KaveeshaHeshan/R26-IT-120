import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/app_theme.dart';
import '../services/offline_queue_service.dart';

class HotspotIndicator extends StatefulWidget {
  const HotspotIndicator({super.key});

  @override
  State<HotspotIndicator> createState() => _HotspotIndicatorState();
}

class _HotspotIndicatorState extends State<HotspotIndicator> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

void _updateStatus(List<ConnectivityResult> results) {
  if (!mounted) return;
  final wasConnected = _isConnected;
  final nowConnected = results.any((r) =>
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet);

  setState(() {
    _isConnected = nowConnected;
  });

  if (!wasConnected && nowConnected) {
    OfflineQueueService().syncPending();
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isConnected
            ? AppTheme.primary.withOpacity(0.15)
            : AppTheme.riskHigh.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isConnected ? AppTheme.primary : AppTheme.riskHigh,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingDot(
            color: _isConnected ? AppTheme.primary : AppTheme.riskHigh,
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected ? 'Hotspot ON' : 'No Signal',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isConnected ? AppTheme.primary : AppTheme.riskHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}