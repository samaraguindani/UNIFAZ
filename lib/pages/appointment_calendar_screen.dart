import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service.dart';
import '../models/time_slot.dart';
import '../models/availability_schedule.dart';
import '../models/appointment.dart';
import '../services/availability_service.dart';
import '../services/appointment_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AppointmentCalendarScreen extends StatefulWidget {
  final Service service;

  const AppointmentCalendarScreen({
    super.key,
    required this.service,
  });

  @override
  State<AppointmentCalendarScreen> createState() =>
      _AppointmentCalendarScreenState();
}

class _AppointmentCalendarScreenState extends State<AppointmentCalendarScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();

  DateTime _selectedDate = DateTime.now();
  AvailabilitySchedule? _availabilitySchedule;
  List<Appointment> _existingAppointments = [];
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar horários de disponibilidade
      final schedule =
          await _availabilityService.getAvailabilityByServiceId(widget.service.id);
      
      // Carregar agendamentos existentes
      final startDate = DateTime.now().subtract(const Duration(days: 7));
      final endDate = DateTime.now().add(const Duration(days: 60));
      final appointments = await _appointmentService.getAppointmentsByDateRange(
        serviceId: widget.service.id,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _availabilitySchedule = schedule;
          _existingAppointments = appointments;
          _isLoading = false;
        });
        _updateAvailableSlots();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateAvailableSlots() {
    if (_availabilitySchedule == null) {
      setState(() {
        _availableSlots = [];
      });
      return;
    }

    // Converter weekday (1=Segunda, 7=Domingo) para (0=Domingo, 6=Sábado)
    // DateTime.weekday: 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sáb, 7=Dom
    // TimeSlot.dayOfWeek: 0=Dom, 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sáb
    final weekday = _selectedDate.weekday;
    final dayOfWeek = weekday == 7 ? 0 : weekday;
    final daySlots = _availabilitySchedule!.timeSlots
        .where((slot) => slot.dayOfWeek == dayOfWeek)
        .toList();

    // Filtrar slots com conflitos de horário
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final bookedAppointments = _existingAppointments
        .where((apt) =>
            apt.appointmentDate.toIso8601String().split('T')[0] == dateStr &&
            apt.status != AppointmentStatus.cancelled &&
            apt.status != AppointmentStatus.completed)
        .toList();

    final available = daySlots.where((slot) {
      // Verificar se há sobreposição com algum agendamento existente
      for (var apt in bookedAppointments) {
        if (_timesOverlap(slot.startTime, slot.endTime, apt.startTime, apt.endTime)) {
          return false; // Há conflito
        }
      }
      return true; // Sem conflitos
    }).toList();

    setState(() {
      _availableSlots = available;
      _selectedSlot = null;
    });
  }

  Future<void> _createAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um horário'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar disponibilidade novamente
    final isAvailable = await _appointmentService.checkTimeSlotAvailable(
      serviceId: widget.service.id,
      date: _selectedDate,
      startTime: _selectedSlot!.startTime,
      endTime: _selectedSlot!.endTime,
    );

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este horário não está mais disponível'),
          backgroundColor: Colors.red,
        ),
      );
      await _loadData();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final appointment = Appointment(
        id: '',
        serviceId: widget.service.id,
        clientId: authProvider.currentUser!.id,
        providerId: widget.service.userId,
        appointmentDate: _selectedDate,
        startTime: _selectedSlot!.startTime,
        endTime: _selectedSlot!.endTime,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _appointmentService.createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar agendamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Agendar Serviço'),
        backgroundColor: const Color(0xFF5a7a6a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availabilitySchedule == null || _availabilitySchedule!.timeSlots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum horário de disponibilidade configurado',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Seletor de data
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selecione a Data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5a7a6a),
                                ),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                    locale: const Locale('pt', 'BR'),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = picked;
                                    });
                                    _updateAvailableSlots();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF87a492)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, dd/MM/yyyy', 'pt_BR')
                                            .format(_selectedDate),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today,
                                          color: Color(0xFF87a492)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Horários disponíveis
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Horários Disponíveis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5a7a6a),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_availableSlots.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Nenhum horário disponível para esta data',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _availableSlots.map((slot) {
                                    final isSelected = _selectedSlot == slot;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedSlot = slot;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF87a492)
                                              : Colors.white,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF87a492)
                                                : Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${slot.startTime} - ${slot.endTime}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Observações
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Observações (opcional)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5a7a6a),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Adicione alguma observação sobre o agendamento...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botão de agendar
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving || _selectedSlot == null
                              ? null
                              : _createAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF87a492),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Confirmar Agendamento',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                      ),
                ),
    );
  }

  bool _timesOverlap(String start1, String end1, String start2, String end2) {
    final s1 = _timeToMinutes(start1);
    final e1 = _timeToMinutes(end1);
    final s2 = _timeToMinutes(start2);
    final e2 = _timeToMinutes(end2);

    return s1 < e2 && e1 > s2;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

