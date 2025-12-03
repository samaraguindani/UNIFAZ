import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/service.dart';
// import '../models/availability_schedule.dart'; // Comentado - não usar mais
// import '../models/time_slot.dart'; // Comentado - não usar mais
import '../providers/auth_provider.dart';
// import '../services/availability_service.dart'; // Comentado - não usar mais
import 'user_profile_screen.dart';
// import '../widgets/appointment_modal.dart'; // Comentado - agendamento desabilitado temporariamente

class ServiceDetailScreen extends StatefulWidget {
  final Service service;

  const ServiceDetailScreen({
    super.key,
    required this.service,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  // COMENTADO: Não usar mais a tabela service_availability
  // final AvailabilityService _availabilityService = AvailabilityService();
  // AvailabilitySchedule? _availabilitySchedule;
  bool _isLoadingAvailability = false;

  @override
  void initState() {
    super.initState();
    // Não precisa mais carregar da tabela service_availability
    // Usar diretamente o campo availability do serviço
    _isLoadingAvailability = false;
  }

  // COMENTADO: Não usar mais a tabela service_availability
  /*
  Future<void> _loadAvailability() async {
    try {
      final schedule = await _availabilityService
          .getAvailabilityByServiceId(widget.service.id);
      if (mounted) {
        setState(() {
          _availabilitySchedule = schedule;
          _isLoadingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
        });
      }
    }
  }

  String _formatTimeSlots() {
    if (_availabilitySchedule == null ||
        _availabilitySchedule!.timeSlots.isEmpty) {
      return 'Nenhum horário disponível configurado';
    }

    // Agrupa por dia da semana
    final Map<int, List<TimeSlot>> groupedByDay = {};
    for (var slot in _availabilitySchedule!.timeSlots) {
      if (!groupedByDay.containsKey(slot.dayOfWeek)) {
        groupedByDay[slot.dayOfWeek] = [];
      }
      groupedByDay[slot.dayOfWeek]!.add(slot);
    }

    // Ordena os dias
    final sortedDays = groupedByDay.keys.toList()..sort();

    final List<String> parts = [];
    const days = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

    for (var day in sortedDays) {
      final slots = groupedByDay[day]!;
      // Ordena os horários do dia
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      final timeRanges = slots
          .map((slot) => '${slot.startTime} - ${slot.endTime}')
          .join(', ');
      
      parts.add('${days[day]}: $timeRanges');
    }

    return parts.join('\n');
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detalhes do Serviço'),
        backgroundColor: const Color(0xFF5a7a6a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Categoria
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.tag,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.service.category.displayName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Localização
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.locationDot,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.service.city}, ${widget.service.state}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Valor ou Voluntário
                    if (widget.service.isVoluntary)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF87a492),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              FontAwesomeIcons.heart,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'TRABALHO VOLUNTÁRIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFc9a56f).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFc9a56f)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.dollarSign,
                              color: const Color(0xFFc9a56f),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.service.value != null
                                  ? 'R\$ ${widget.service.value!.toStringAsFixed(2)}'
                                  : 'A Combinar',
                              style: const TextStyle(
                                color: Color(0xFFc9a56f),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.service.pricingType.displayName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Descrição
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Descrição',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.service.description,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Horários Disponíveis
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.clock,
                            color: const Color(0xFF87a492),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Horários Disponíveis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isLoadingAvailability
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Text(
                              widget.service.availability.isNotEmpty
                                  ? widget.service.availability
                                  : 'Nenhum horário disponível configurado',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contato
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Contato',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.phone,
                              color: const Color(0xFF87a492),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.service.contact,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botão de agendar (apenas se não for o próprio prestador)
            // COMENTADO TEMPORARIAMENTE - Implementação de agendamento desabilitada
            /*
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isOwner = authProvider.currentUser?.id == widget.service.userId;
                
                if (!isOwner && authProvider.currentUser != null) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => AppointmentModal(
                                service: widget.service,
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text(
                            'Agendar Serviço',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF87a492),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            */
            
            // Botão ver perfil
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: widget.service.userId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text(
                  'Ver Perfil do Prestador',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5a7a6a),
                  side: const BorderSide(color: Color(0xFF5a7a6a), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botão de contato
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Aqui você pode implementar ações como abrir WhatsApp, fazer ligação, etc.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidade de contato será implementada'),
                      backgroundColor: Color(0xFF87a492),
                    ),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text(
                  'Entrar em Contato',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87a492),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informações adicionais
            Card(
              elevation: 1,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.calendar,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Publicado em ${_formatDate(widget.service.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}








