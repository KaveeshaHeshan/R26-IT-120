import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'farmer_settings.dart';
import 'farmer_theme.dart';

/// Small "online / offline" chip shown in the farmer app header.
/// Field data collection often happens with a poor signal, so
/// farmers get a constant, unobtrusive reminder of sync status.
class FarmerConnectivityChip extends StatefulWidget {
  const FarmerConnectivityChip({super.key});

  @override
  State<FarmerConnectivityChip> createState() => _FarmerConnectivityChipState();
}

class _FarmerConnectivityChipState extends State<FarmerConnectivityChip> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _checkConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (!mounted) return;

    setState(() {
      _isConnected = results.any(
        (ConnectivityResult r) =>
            r == ConnectivityResult.mobile || r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;
    final Color color = _isConnected ? p.success : p.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected ? settings.t('Online', 'සබැඳි') : settings.t('Offline', 'නොබැඳි'),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
