import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  ScannerScreenState createState() => ScannerScreenState();
}

class ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController cameraController;
  Set<String> uniqueBarcodes = {}; // Set for unique barcodes

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
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
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            scanWindow: Rect.fromLTWH(
              0,
              MediaQuery.of(context).size.height * 0.4, // Adjusted positioning
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.1, // Wide scan window
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
                if (barcode.rawValue != null && uniqueBarcodes.add(barcode.rawValue!)) {
                  // Only add if unique
                  setState(() {}); // Update the UI
                }
              }
            },
          ),
          // Section for detected barcodes with background and label
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.black54, // Semi-transparent background
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
                              color: Colors.black87, // Slightly darker for contrast
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
                                Navigator.of(context).pop(barcodeValue); // Return selected barcode
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