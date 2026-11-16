// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';
import '../widgets/event_location_input.dart';

/// Screen for creating a new event or editing an existing event.
///
/// Features:
/// - Full manual text entry for Title, Description, Category, DateTime, and Venue Name.
/// - Integrated "Use Current Location" GPS action via [EventLocationInput].
/// - Preserves previously saved GPS coordinates when editing an existing event.
/// - Allows explicit clearing of coordinates while keeping venue name intact.
class CreateEventScreen extends StatefulWidget {
  final EventModel? eventToEdit;
  final EventController? controller;

  const CreateEventScreen({
    super.key,
    this.eventToEdit,
    this.controller,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late final EventController _controller;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = const [
    'General',
    'Academic',
    'Sports',
    'Cultural',
    'Workshop',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? EventController();

    if (widget.eventToEdit != null) {
      _controller.initForEdit(widget.eventToEdit!);
    } else {
      _controller.initForCreate();
    }

    _titleController = TextEditingController(text: _controller.title);
    _descriptionController =
        TextEditingController(text: _controller.description);
    _locationController =
        TextEditingController(text: _controller.locationName);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    // Only dispose controller if created internally
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await _controller.saveEvent();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventToEdit != null
                ? 'Event updated successfully!'
                : 'Event created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(result);
      } else {
        final event = await EventRepository().getEvent(result);
        if (event != null && mounted) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.eventDetails,
            arguments: event,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _controller.isEditing ? 'Edit Event' : 'Create Event',
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    hintText: 'e.g., Annual Tech Symposium',
                    prefixIcon: Icon(Icons.title),
                  ),
                  onChanged: (val) => _controller.setTitle(val),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an event title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _categories.contains(_controller.category)
                      ? _controller.category
                      : _categories.first,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _controller.setCategory(val);
                  },
                ),
                const SizedBox(height: 16),

                // Date & Time Display / Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Event Date & Time'),
                  subtitle: Text(_controller.dateTime.toString().split('.')[0]),
                  trailing: TextButton(
                    child: const Text('Change'),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _controller.dateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate == null) return;
                      if (!context.mounted) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay.fromDateTime(_controller.dateTime),
                      );
                      if (pickedTime != null) {
                        _controller.setDateTime(DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide details about the event...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  onChanged: (val) => _controller.setDescription(val),
                ),
                const SizedBox(height: 20),

                // Location Section with GPS Integration
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Location Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                EventLocationInput(
                  controller: _controller,
                  locationTextController: _locationController,
                ),
                const SizedBox(height: 20),
                const Divider(),

                // Save Error Banner
                if (_controller.saveErrorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _controller.saveErrorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Submit Button
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('submit_event_button'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _controller.isSaving ? null : _submit,
                  child: _controller.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _controller.isEditing
                              ? 'Update Event'
                              : 'Create Event',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
