//
// PpgProvider.dart
// tachy_app_flutter
//
// State management + signal processing (peak detection, BPM) - migrated from Swift
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/bluetooth_service.dart' as ble;

class VoltageDataPoint {
  final DateTime time;
  final double voltage;

  VoltageDataPoint(this.time, this.voltage);
}

class PpgProvider with ChangeNotifier {
  static const int _maxHistoryCount = 500;
  static const Duration _timeWindow = Duration(seconds: 5);
  static const double _peakThreshold = 2.8;
  static const Duration _minPeakInterval = Duration(milliseconds: 300);
  static const int _maxPeakTimestamps = 10;

  ble.BleConnectionService? _bluetoothService;
  StreamSubscription? _connectionSubscription;

  bool _isScanning = false;
  bool _isConnected = false;
  String _connectionStatus = "Disconnected";
  double _ppgVoltage = 0.0;
  final List<VoltageDataPoint> _voltageHistory = [];
  int _peakCount = 0;
  double _bpm = 0.0;

  double _previousVoltage = 0.0;
  DateTime? _lastPeakTime;
  final List<DateTime> _peakTimestamps = [];

  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  double get ppgVoltage => _ppgVoltage;
  List<VoltageDataPoint> get voltageHistory => List.unmodifiable(_voltageHistory);
  int get peakCount => _peakCount;
  double get bpm => _bpm;

  List<VoltageDataPoint> get recentVoltageHistory {
    if (_voltageHistory.isEmpty) return [];
    final cutoffTime = DateTime.now().subtract(_timeWindow);
    return _voltageHistory
        .where((p) => p.time.isAfter(cutoffTime))
        .toList();
  }

  PpgProvider() {
    _initBluetooth();
  }

  void _initBluetooth() {
    _bluetoothService = ble.BleConnectionService(
      onStatusChanged: (status) {
        _connectionStatus = status;
        if (status.startsWith("Connecting") ||
            status == "Connected" ||
            status == "Receiving data..." ||
            status.startsWith("Device not found")) {
          _isScanning = false;
        }
        notifyListeners();
      },
      onConnectionChanged: (connected) {
        _isConnected = connected;
        if (!connected) {
          _resetOnDisconnect();
        }
        notifyListeners();
      },
      onVoltageReceived: _handleVoltage,
    );
  }

  void _resetOnDisconnect() {
    _ppgVoltage = 0.0;
    _voltageHistory.clear();
    _peakCount = 0;
    _bpm = 0.0;
    _previousVoltage = 0.0;
    _lastPeakTime = null;
    _peakTimestamps.clear();
  }

  void _handleVoltage(double voltage) {
    final currentTime = DateTime.now();
    _ppgVoltage = voltage;

    // Peak detection: voltage crosses above threshold
    if (_previousVoltage < _peakThreshold && voltage >= _peakThreshold) {
      if (_lastPeakTime != null) {
        final timeSinceLastPeak = currentTime.difference(_lastPeakTime!);
        if (timeSinceLastPeak >= _minPeakInterval) {
          _peakCount++;
          _lastPeakTime = currentTime;
          _peakTimestamps.add(currentTime);
          if (_peakTimestamps.length > _maxPeakTimestamps) {
            _peakTimestamps.removeAt(0);
          }
          _calculateBPM();
        }
      } else {
        _peakCount++;
        _lastPeakTime = currentTime;
        _peakTimestamps.add(currentTime);
      }
    }

    _previousVoltage = voltage;

    _voltageHistory.add(VoltageDataPoint(currentTime, voltage));
    if (_voltageHistory.length > _maxHistoryCount) {
      _voltageHistory.removeRange(
        0,
        _voltageHistory.length - _maxHistoryCount,
      );
    }

    notifyListeners();
  }

  void _calculateBPM() {
    if (_peakTimestamps.length < 2) {
      _bpm = 0.0;
      return;
    }

    final intervals = <double>[];
    for (int i = 1; i < _peakTimestamps.length; i++) {
      final interval =
          _peakTimestamps[i].difference(_peakTimestamps[i - 1]).inMilliseconds /
              1000.0;
      intervals.add(interval);
    }

    final averageInterval =
        intervals.reduce((a, b) => a + b) / intervals.length;
    _bpm = averageInterval > 0 ? 60.0 / averageInterval : 0.0;
  }

  Future<void> startScanning() async {
    _isScanning = true;
    notifyListeners();
    await _bluetoothService?.startScanning();
    _isScanning = _bluetoothService?.isScanning ?? false;
    notifyListeners();
  }

  Future<void> stopScanning() async {
    await _bluetoothService?.stopScanning();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _bluetoothService?.disconnect();
    _isConnected = false;
    _isScanning = false;
    _resetOnDisconnect();
    notifyListeners();
  }

  Future<void> connectOrDisconnect() async {
    if (_isConnected) {
      await disconnect();
    } else {
      await startScanning();
    }
  }

  @override
  void dispose() {
    _bluetoothService?.dispose();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
