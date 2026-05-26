import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/event_calendar/event_calendar_models.dart';

class EventForm extends StatefulWidget {
  const EventForm({
    super.key,
    required this.onSubmit,
    this.initial,
    this.members = const [],
    this.submitLabel = 'Save event',
  });

  final CalendarEventItem? initial;
  final List<(int id, String name)> members;
  final Future<void> Function(CalendarEventItem item) onSubmit;
  final String submitLabel;

  @override
  State<EventForm> createState() => EventFormState();
}

class EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _remarks;
  DateTime _date = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  EventStatus _status = EventStatus.upcoming;
  int? _assignedMemberId;
  bool _saving = false;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _location = TextEditingController(text: i?.location ?? '');
    _description = TextEditingController(text: i?.description ?? '');
    _remarks = TextEditingController(text: i?.adminRemarks ?? '');
    if (i != null) {
      _date = i.eventDate;
      _startTime = i.startTime;
      _endTime = i.endTime;
      _status = i.status;
      _assignedMemberId = i.assignedMemberId;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _timeError = null;
      });
    }
  }

  bool _validateTimes() {
    if (_startTime != null && _endTime != null) {
      final s = _startTime!.hour * 60 + _startTime!.minute;
      final e = _endTime!.hour * 60 + _endTime!.minute;
      if (s >= e) {
        _timeError = 'Start time must be before end time';
        return false;
      }
    }
    _timeError = null;
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_validateTimes()) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    try {
      final item = CalendarEventItem(
        id: widget.initial?.id ?? 0,
        title: _title.text.trim(),
        eventDate: _date,
        startTime: _startTime,
        endTime: _endTime,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        status: _status,
        assignedMemberId: _assignedMemberId,
        assignedMemberName: widget.members
            .where((m) => m.$1 == _assignedMemberId)
            .map((m) => m.$2)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null),
        documentationRequestId: widget.initial?.documentationRequestId,
        adminRemarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
      );
      await widget.onSubmit(item);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Event title *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Event title is required' : null,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date *'),
            subtitle: Text(
              '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
            ),
            trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start time'),
                  subtitle: Text(_startTime?.format(context) ?? 'Not set'),
                  onTap: () => _pickTime(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End time'),
                  subtitle: Text(_endTime?.format(context) ?? 'Not set'),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          if (_timeError != null)
            Text(_timeError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'Recommended — e.g. Main Gymnasium',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EventStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: EventStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(eventStatusLabel(s))))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          if (widget.members.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _assignedMemberId,
              decoration: const InputDecoration(labelText: 'Assigned member / team'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...widget.members.map((m) => DropdownMenuItem(value: m.$1, child: Text(m.$2))),
              ],
              onChanged: (v) => setState(() => _assignedMemberId = v),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _remarks,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Admin remarks'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
