import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:speed_scan/models/equipment_model.dart';

class AddEditScreen extends StatefulWidget {
  final String? serialNumber;
  final Equipment? equipment;

  const AddEditScreen({super.key, this.serialNumber, this.equipment});

  @override
  AddEditScreenState createState() => AddEditScreenState();
}

class AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _locationController =
        TextEditingController(text: widget.equipment?.location ?? '');
    _notesController =
        TextEditingController(text: widget.equipment?.notes ?? '');
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveEquipment() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<Equipment>('equipmentBox');
      if (widget.equipment == null) {
        // Add new equipment
        final newEquipment = Equipment(
          serialNumber: widget.serialNumber ?? '',
          location: _locationController.text,
          notes: _notesController.text,
        );
        await box.add(newEquipment);
      } else {
        // Edit existing equipment
        widget.equipment!
          ..location = _locationController.text
          ..notes = _notesController.text;
        await widget.equipment!.save();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _confirmDelete() async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this entry?'),
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

    if (shouldDelete == true && widget.equipment != null) {
      await widget.equipment!.delete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.equipment == null ? 'Add Equipment' : 'Edit Equipment'),
        actions: [
          if (widget.equipment != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                ),
                initialValue:
                    widget.serialNumber ?? widget.equipment?.serialNumber,
                readOnly: true,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveEquipment,
                child: Text(widget.equipment == null ? 'Add' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
