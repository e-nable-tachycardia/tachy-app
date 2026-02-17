//
// HomeScreen.dart
// tachy_app_flutter
//
// Main PPG app UI - migrated from Swift ContentView
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ppg_provider.dart';
import '../widgets/voltage_graph.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<PpgProvider>(
          builder: (context, ppg, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    ppg.connectionStatus,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "PPG Voltage (Last 5 Seconds)",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: VoltageGraph(voltageHistory: ppg.recentVoltageHistory),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Current: ${ppg.ppgVoltage.toStringAsFixed(3)} V",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      Text(
                        "Peaks (>2.8V): ${ppg.peakCount}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "BPM: ${ppg.bpm.toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ppg.isScanning
                            ? null
                            : () => ppg.connectOrDisconnect(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ppg.isConnected ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          ppg.isConnected ? "Disconnect" : "Connect",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
