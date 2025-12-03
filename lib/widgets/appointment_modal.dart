import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../models/service.dart';
import '../models/time_slot.dart';
import '../models/availability_schedule.dart';
import '../models/appointment.dart';
import '../models/notification.dart';
import '../services/availability_service.dart';
import '../services/appointment_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

class AppointmentModal extends StatefulWidget {
  final Service service;

  const AppointmentModal({
    super.key,
    required this.service,
  });

  @override
  State<AppointmentModal> createState() => _AppointmentModalState();
}

class _AppointmentModalState extends State<AppointmentModal> {
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  final NotificationService _notificationService = NotificationService();

  DateTime _selectedDate = DateTime.now();
  AvailabilitySchedule? _availabilitySchedule;
  List<Appointment> _existingAppointments = [];
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadData();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('pt_BR', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
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
      final schedule = await _availabilityService
          .getAvailabilityByServiceId(widget.service.id);

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

    final weekday = _selectedDate.weekday;
    final dayOfWeek = weekday == 7 ? 0 : weekday;
    final daySlots = _availabilitySchedule!.timeSlots
        .where((slot) => slot.dayOfWeek == dayOfWeek)
        .toList();

    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final bookedAppointments = _existingAppointments
        .where((apt) =>
            apt.appointmentDate.toIso8601String().split('T')[0] == dateStr &&
            apt.status != AppointmentStatus.cancelled &&
            apt.status != AppointmentStatus.completed)
        .toList();

    final available = daySlots.where((slot) {
      for (var apt in bookedAppointments) {
        if (_timesOverlap(slot.startTime, slot.endTime, apt.startTime, apt.endTime)) {
          return false;
        }
      }
      return true;
    }).toList();

    setState(() {
      _availableSlots = available;
      _selectedSlot = null;
    });
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

      // Criar agendamento como pendente
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

      final createdAppointment = await _appointmentService.createAppointment(appointment);

      // Criar notificação para o prestador
      final dateFormat = _localeInitialized
          ? DateFormat('dd/MM/yyyy', 'pt_BR')
          : DateFormat('dd/MM/yyyy');
      final notification = AppNotification(
        id: '',
        userId: widget.service.userId,
        fromUserId: authProvider.currentUser!.id,
        type: NotificationType.appointmentRequest,
        title: 'Nova Solicitação de Agendamento',
        message:
            '${authProvider.currentUser!.fullName} solicitou um agendamento para ${dateFormat.format(_selectedDate)} às ${_selectedSlot!.startTime}',
        appointmentId: createdAppointment.id,
        serviceId: widget.service.id,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _notificationService.createNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação de agendamento enviada! Aguarde a aprovação do prestador.'),
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            : _availabilitySchedule == null ||
                    _availabilitySchedule!.timeSlots.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
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
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cabeçalho
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5a7a6a),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Agendar Serviço',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // Conteúdo
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5a7a6a),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _selectedDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now()
                                                .add(const Duration(days: 90)),
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
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: const Color(0xFF87a492)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _localeInitialized
                                                    ? DateFormat('EEEE, dd/MM/yyyy', 'pt_BR')
                                                        .format(_selectedDate)
                                                    : DateFormat('EEEE, dd/MM/yyyy')
                                                        .format(_selectedDate),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today,
                                                  size: 20,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5a7a6a),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_availableSlots.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            'Nenhum horário disponível para esta data',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
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
                                                    horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF87a492)
                                                      : Colors.white,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? const Color(0xFF87a492)
                                                        : Colors.grey[300]!,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                    fontSize: 12,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5a7a6a),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _notesController,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Adicione alguma observação...',
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
                            ],
                          ),
                        ),
                      ),

                      // Botões
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSaving || _selectedSlot == null
                                    ? null
                                    : _createAppointment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF87a492),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text('Solicitar Agendamento'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

