import 'package:flutter/material.dart';
import '../models/time_slot.dart';
import '../models/availability_schedule.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  final List<TimeSlot>? initialTimeSlots;
  final Function(List<TimeSlot>) onSave;

  const AvailabilityCalendarScreen({
    super.key,
    this.initialTimeSlots,
    required this.onSave,
  });

  @override
  State<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends State<AvailabilityCalendarScreen> {
  final Map<int, List<TimeSlot>> _schedule = {};
  final Map<String, List<TimeSlot>> _presets = AvailabilityPresets.allPresets;
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
  }

  void _initializeSchedule() {
    if (widget.initialTimeSlots != null && widget.initialTimeSlots!.isNotEmpty) {
      for (var slot in widget.initialTimeSlots!) {
        if (!_schedule.containsKey(slot.dayOfWeek)) {
          _schedule[slot.dayOfWeek] = [];
        }
        _schedule[slot.dayOfWeek]!.add(slot);
      }
    }
  }

  List<TimeSlot> _getAllTimeSlots() {
    final List<TimeSlot> allSlots = [];
    _schedule.forEach((day, slots) {
      allSlots.addAll(slots);
    });
    return allSlots;
  }

  void _applyPreset(String presetName) {
    setState(() {
      _selectedPreset = presetName;
      _schedule.clear();
      final presetSlots = _presets[presetName]!;
      for (var slot in presetSlots) {
        if (!_schedule.containsKey(slot.dayOfWeek)) {
          _schedule[slot.dayOfWeek] = [];
        }
        _schedule[slot.dayOfWeek]!.add(slot);
      }
    });
  }

  void _addTimeSlot(int dayOfWeek) {
    setState(() {
      if (!_schedule.containsKey(dayOfWeek)) {
        _schedule[dayOfWeek] = [];
      }
      _schedule[dayOfWeek]!.add(TimeSlot(
        dayOfWeek: dayOfWeek,
        startTime: '08:00',
        endTime: '18:00',
      ));
    });
  }

  void _removeTimeSlot(int dayOfWeek, int index) {
    setState(() {
      if (_schedule.containsKey(dayOfWeek)) {
        _schedule[dayOfWeek]!.removeAt(index);
        if (_schedule[dayOfWeek]!.isEmpty) {
          _schedule.remove(dayOfWeek);
        }
      }
    });
  }

  void _updateTimeSlot(int dayOfWeek, int index, TimeSlot updatedSlot) {
    setState(() {
      if (_schedule.containsKey(dayOfWeek) &&
          index < _schedule[dayOfWeek]!.length) {
        _schedule[dayOfWeek]![index] = updatedSlot;
      }
    });
  }

  Future<void> _selectTime(
      BuildContext context, TimeSlot slot, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? TimeOfDay(
              hour: int.parse(slot.startTime.split(':')[0]),
              minute: int.parse(slot.startTime.split(':')[1]),
            )
          : TimeOfDay(
              hour: int.parse(slot.endTime.split(':')[0]),
              minute: int.parse(slot.endTime.split(':')[1]),
            ),
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final updatedSlot = isStartTime
          ? slot.copyWith(startTime: timeString)
          : slot.copyWith(endTime: timeString);

      // Encontrar o índice do slot
      final daySlots = _schedule[slot.dayOfWeek] ?? [];
      final index = daySlots.indexOf(slot);
      if (index != -1) {
        _updateTimeSlot(slot.dayOfWeek, index, updatedSlot);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Configurar Horários'),
        backgroundColor: const Color(0xFF5a7a6a),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onSave(_getAllTimeSlots());
              Navigator.pop(context);
            },
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Seção de Presets
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Presets Rápidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5a7a6a),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.keys.map((presetName) {
                    final isSelected = _selectedPreset == presetName;
                    return FilterChip(
                      label: Text(presetName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _applyPreset(presetName);
                        } else {
                          setState(() {
                            _selectedPreset = null;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF87a492),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de dias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                final dayOfWeek = index;
                final dayName = days[dayOfWeek];
                final daySlots = _schedule[dayOfWeek] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      dayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: daySlots.isEmpty
                        ? const Text(
                            'Nenhum horário definido',
                            style: TextStyle(color: Colors.grey),
                          )
                        : Text(
                            daySlots
                                .map((s) => '${s.startTime} - ${s.endTime}')
                                .join(', '),
                            style: const TextStyle(color: Color(0xFF5a7a6a)),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF87a492)),
                          onPressed: () => _addTimeSlot(dayOfWeek),
                          tooltip: 'Adicionar horário',
                        ),
                        if (daySlots.isNotEmpty)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    children: daySlots.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Toque no botão + para adicionar um horário',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ]
                        : daySlots.asMap().entries.map((entry) {
                            final slotIndex = entry.key;
                            final slot = entry.value;
                            return ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _selectTime(context, slot, true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFF87a492)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time,
                                                size: 18,
                                                color: Color(0xFF87a492)),
                                            const SizedBox(width: 8),
                                            Text(
                                              slot.startTime,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('até'),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _selectTime(context, slot, false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFF87a492)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time,
                                                size: 18,
                                                color: Color(0xFF87a492)),
                                            const SizedBox(width: 8),
                                            Text(
                                              slot.endTime,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _removeTimeSlot(dayOfWeek, slotIndex),
                                    tooltip: 'Remover horário',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

