import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sound_mode/sound_mode.dart';


class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  ScannerScreenState createState() => ScannerScreenState();
}

class ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController cameraController;
  Set<String> uniqueBarcodes = {}; // Set for unique barcodes
  bool _showFlashOverlay = false; // Controls flash overlay visibility
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    cameraController.start().then((_) {
      _loadZoomLevel(); // Load zoom level from shared preferences
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _saveZoomLevel() async {
    double currentZoom = cameraController.value.zoomScale;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('zoomLevel', currentZoom);
  }

  void _loadZoomLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? zoomLevel = prefs.getDouble('zoomLevel');
    if (zoomLevel != null) {
      cameraController.setZoomScale(zoomLevel);
    }
  }

  void _giveFeedback() async {
    // Flash overlay for visual feedback
    setState(() {
      _showFlashOverlay = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _showFlashOverlay = false;
      });
    });

    RingerModeStatus ringerStatus = await SoundMode.ringerModeStatus;
    bool? hasVibration = await Vibration.hasVibrator();

    // Vibration feedback
    if ((ringerStatus == RingerModeStatus.normal ||
            ringerStatus == RingerModeStatus.vibrate) &&
        hasVibration!) {
      Vibration.vibrate(duration: 50); // Short vibration
    }

    // Sound feedback
    if (ringerStatus == RingerModeStatus.normal) {
      // Get our notification volume
      _audioPlayer.play(AssetSource('beep.mp3'),
          ctx: AudioContext(
              android: AudioContextAndroid(
                  usageType: AndroidUsageType
                      .notification))); // Ensure you have this file in assets
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => cameraController.switchCamera(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              double currentZoom = cameraController.value.zoomScale;
              if (currentZoom <= 1.9) {
                cameraController.setZoomScale(currentZoom + 0.1);
                _saveZoomLevel(); // Save zoom level to shared preferences
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              double currentZoom = cameraController.value.zoomScale;
              if (currentZoom >= 0.1) {
                cameraController.setZoomScale(currentZoom - 0.1);
                _saveZoomLevel(); // Save zoom level to shared preferences
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            scanWindow: Rect.fromLTWH(
              0,
              MediaQuery.of(context).size.height * 0.4,
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.1,
            ),
            overlayBuilder: (context, constraints) {
              return Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.1,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.error, width: 2.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              );
            },
            onDetect: (capture) {
              for (var barcode in capture.barcodes) {
                if (barcode.rawValue != null &&
                    uniqueBarcodes.add(barcode.rawValue!)) {
                  // Only add if unique
                  _giveFeedback(); // Trigger feedback
                  setState(() {}); // Update UI
                }
              }
            },
          ),
          if (_showFlashOverlay)
            Container(
              color: Colors.white.withOpacity(0.5), // Overlay for flash effect
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tap on a barcode to select it:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: uniqueBarcodes.length,
                        itemBuilder: (context, index) {
                          final barcodeValue = uniqueBarcodes.elementAt(index);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              title: Text(
                                barcodeValue,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).pop(barcodeValue);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final String? manualCode = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            String manualInput = '';
                            return AlertDialog(
                              title: const Text('Manual Entry'),
                              content: TextField(
                                autofocus: true,
                                decoration: const InputDecoration(
                                    hintText: 'Enter serial number'),
                                onChanged: (value) {
                                  manualInput = value;
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(manualInput),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );

                        if (manualCode != null && manualCode.isNotEmpty) {
                          setState(() {
                            uniqueBarcodes.add(manualCode); // Add manual entry
                          });
                        }
                      },
                      child: const Text('Enter Manually'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
