//
// bluetooth_service.dart
// tachy_app_flutter
//
// BLE communication with Arduino Nano PPG - migrated from Swift
//

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConnectionService {
  // UUIDs matching Arduino code
  static const String serviceUuid = "12345678-1234-5678-1234-56789abcdef0";
  static const String characteristicUuid = "12345678-1234-5678-1234-56789abcdef1";
  static const String deviceName = "NanoPPG";

  StreamSubscription? _scanSubscription;
  StreamSubscription? _characteristicSubscription;
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;

  final Function(String) onStatusChanged;
  final Function(bool) onConnectionChanged;
  final Function(double) onVoltageReceived;

  BleConnectionService({
    required this.onStatusChanged,
    required this.onConnectionChanged,
    required this.onVoltageReceived,
  });

  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null;

  Future<void> startScanning() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      onStatusChanged("Bluetooth is off");
      return;
    }

    _isScanning = true;
    onStatusChanged("Scanning for $deviceName...");
    onConnectionChanged(false);

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          final name = result.device.advName.isEmpty
              ? result.device.platformName
              : result.device.advName;
          final isOurDevice = (name.isNotEmpty && name.contains("NanoPPG")) ||
              name == deviceName;

          if (isOurDevice) {
            await stopScanning();
            _connectedDevice = result.device;
            onStatusChanged("Connecting to ${name.isEmpty ? deviceName : name}...");
            await _connectAndSetup(result.device);
            return;
          }
        }
      });

      // Timeout: stop scan after 15 seconds if not connected
      Future.delayed(const Duration(seconds: 15), () async {
        if (_isScanning && !isConnected) {
          await stopScanning();
          onStatusChanged("Device not found. Make sure NanoPPG is powered on.");
        }
      });
    } catch (e) {
      _isScanning = false;
      onStatusChanged("Scan error: $e");
    }
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> _connectAndSetup(BluetoothDevice device) async {
    try {
      await device.connect();
      onConnectionChanged(true);
      onStatusChanged("Connected");

      final services = await device.discoverServices();
      final serviceGuid = Guid(serviceUuid);
      final charGuid = Guid(characteristicUuid);

      for (final service in services) {
        if (service.serviceUuid == serviceGuid) {
          for (final char in service.characteristics) {
            if (char.uuid == charGuid) {
              await char.setNotifyValue(true);
              onStatusChanged("Receiving data...");
              _listenToCharacteristic(char);
              return;
            }
          }
        }
      }
      onStatusChanged("PPG service not found");
    } catch (e) {
      onConnectionChanged(false);
      onStatusChanged("Connection failed: $e");
    }
  }

  void _listenToCharacteristic(BluetoothCharacteristic characteristic) {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = characteristic.lastValueStream.listen((value) {
      if (value.length >= 4) {
        final bytes = Uint8List.fromList(value);
        final voltage = ByteData.sublistView(bytes)
            .getFloat32(0, Endian.little)
            .toDouble();
        onVoltageReceived(voltage);
      }
    });
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _characteristicSubscription?.cancel();
      _characteristicSubscription = null;
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      onConnectionChanged(false);
      onStatusChanged("Disconnected");
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _characteristicSubscription?.cancel();
    disconnect();
  }
}
