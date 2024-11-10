import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speed_scan/models/equipment_model.dart';
import 'package:speed_scan/screens/scanner_screen.dart';
import 'package:speed_scan/screens/add_edit_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late Box<Equipment> _equipmentBox;
  String _appVersion = 'Version loading...';

  @override
  void initState() {
    super.initState();
    _equipmentBox = Hive.box<Equipment>('equipmentBox');

    // Fetch and store app version info in initState
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion =
          'Version ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _clearAllEntries() async {
    await _equipmentBox.clear();
    setState(() {});
  }

  void _deleteEntry(int index) async {
    await _equipmentBox.deleteAt(index);
    setState(() {});
  }

  Future<void> _shareEntries() async {
    if (_equipmentBox.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Share as Plain Text'),
                onTap: () async {
                  await _generateAndShareFile('plain_text');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Share as CSV'),
                onTap: () async {
                  await _generateAndShareFile('csv');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Share as TSV'),
                onTap: () async {
                  await _generateAndShareFile('tsv');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _generateAndShareFile(String format) async {
    final List<String> entries = _equipmentBox.values.map((equipment) {
      return '${equipment.serialNumber},${equipment.location},${equipment.notes}';
    }).toList();

    final Directory tempDir = await getTemporaryDirectory();
    File file;
    String mimeType;

    switch (format) {
      case 'csv':
        final String csvData =
            'Serial Number,Location,Notes\n${entries.join('\n')}';
        file = File('${tempDir.path}/scanned_equipment.csv');
        await file.writeAsString(csvData);
        mimeType = 'text/csv';
        break;
      case 'tsv':
        final String tsvData =
            'Serial Number\tLocation\tNotes\n${entries.join('\n').replaceAll(',', '\t')}';
        file = File('${tempDir.path}/scanned_equipment.tsv');
        await file.writeAsString(tsvData);
        mimeType = 'text/tab-separated-values';
        break;
      case 'plain_text':
      default:
        final String plainTextData = entries.join('\n');
        file = File('${tempDir.path}/scanned_equipment.txt');
        await file.writeAsString(plainTextData);
        mimeType = 'text/plain';
        break;
    }

    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)],
        subject: 'Scanned Equipment List');

    // Clean up the file after sharing
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final shouldClear = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text(
                        'Are you sure you want to delete all entries?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete All'),
                      ),
                    ],
                  );
                },
              );

              if (shouldClear == true) {
                await _clearAllEntries();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareEntries,
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Speed Scan',
                applicationVersion: _appVersion,
                applicationLegalese: '© 2024 Creative Technology Services',
                children: [
                  const SizedBox(height: 8),
                  const Text('Speed Scan is a simple equipment scanning app.'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      Uri url = Uri.parse("https://nvcreativetechnology.com");

                      if (!await launchUrl(url)) {
                        throw 'Could not launch $url';
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Visit our website',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _equipmentBox.listenable(),
        builder: (context, Box<Equipment> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No scanned equipment yet!'),
            );
          } else {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                final equipment = box.getAt(index);
                return Dismissible(
                  key: Key(equipment?.serialNumber ?? ''),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text(
                              'Are you sure you want to delete this entry?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _deleteEntry(index);
                  },
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(equipment?.serialNumber ?? ''),
                    subtitle: Text('Location: ${equipment?.location ?? 'N/A'}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AddEditScreen(equipment: equipment),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final String? scannedCode = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ScannerScreen(),
            ),
          );

          if (scannedCode != null) {
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AddEditScreen(serialNumber: scannedCode),
                ),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
