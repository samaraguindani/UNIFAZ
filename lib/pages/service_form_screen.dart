import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/service_provider.dart';
import '../providers/auth_provider.dart';
import '../models/service.dart';
import '../models/enums.dart';
import '../models/location.dart';
import '../models/time_slot.dart';
import '../models/availability_schedule.dart';
import '../services/location_service.dart';
import '../services/availability_service.dart';
import '../widgets/common_widgets.dart';
// import 'availability_calendar_screen.dart'; // Comentado - modal desabilitado temporariamente

class ServiceFormScreen extends StatefulWidget {
  final Service? service;

  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _contactController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _availabilityController = TextEditingController();
  
  List<TimeSlot> _selectedTimeSlots = [];

  ServiceCategory _selectedCategory = ServiceCategory.outros;
  PricingType _selectedPricingType = PricingType.aCombinar;
  bool _isVoluntary = false;
  
  List<Estado> _states = [];
  List<City> _cities = [];
  Estado? _selectedState;
  City? _selectedCity;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
    
    if (widget.service != null) {
      _populateForm();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _contactController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  void _populateForm() async {
    final service = widget.service!;
    _titleController.text = service.title;
    _descriptionController.text = service.description;
    _valueController.text = service.value?.toString() ?? '';
    _contactController.text = service.contact;
    _selectedCategory = service.category;
    _selectedPricingType = service.pricingType;
    _isVoluntary = service.isVoluntary;
    
    // Carregar horários de disponibilidade do campo do serviço
    // COMENTADO: Não usar mais a tabela service_availability, apenas o campo texto
    /*
    final availabilityService = AvailabilityService();
    final schedule = await availabilityService.getAvailabilityByServiceId(service.id);
    if (schedule != null && schedule.timeSlots.isNotEmpty) {
      // Converter horários para texto legível
      _availabilityController.text = schedule.toDisplayString();
      setState(() {
        _selectedTimeSlots = schedule.timeSlots;
      });
    } else {
      // Fallback para o campo antigo de disponibilidade
      if (service.availability.isNotEmpty) {
        _availabilityController.text = service.availability;
      }
    }
    */
    // Usar apenas o campo availability do serviço
    if (service.availability.isNotEmpty) {
      _availabilityController.text = service.availability;
    }
    
    // Carregar estados
    await _loadStates();
    
    // Encontrar e selecionar o estado
    if (_states.isNotEmpty) {
      final state = _states.firstWhere(
        (s) => s.sigla == service.state,
        orElse: () => _states.first,
      );
      
      setState(() {
        _selectedState = state;
        _stateController.text = state.sigla;
      });
      
      // Carregar cidades do estado
      await _loadCities(state.sigla);
      
      // Encontrar e selecionar a cidade
      if (_cities.isNotEmpty) {
        final city = _cities.firstWhere(
          (c) => c.nome == service.city,
          orElse: () => _cities.first,
        );
        
        setState(() {
          _selectedCity = city;
          _cityController.text = city.nome;
        });
      }
    }
  }

  Future<void> _loadStates() async {
    try {
      final locationService = LocationService();
      final states = await locationService.getStates();
      setState(() {
        _states = states;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar estados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCities(String stateCode) async {
    try {
      final locationService = LocationService();
      final cities = await locationService.getCitiesByStateCode(stateCode);
      setState(() {
        _cities = cities;
        _selectedCity = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar cidades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.service == null ? 'Adicionar Serviço' : 'Editar Serviço'),
        backgroundColor: const Color(0xFF5a7a6a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Serviço',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o título do serviço';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Descrição
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Categoria
              InkWell(
                onTap: () => _showCategoryPicker(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategory?.displayName ?? 'Selecione uma categoria',
                          style: TextStyle(
                            color: _selectedCategory == null ? Colors.grey : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Disponibilidade - Campo de texto manual
              TextFormField(
                controller: _availabilityController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Horários de Disponibilidade',
                  hintText: 'Ex: Segunda a Sexta: 08:00 - 18:00\nSábado: 09:00 - 13:00',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  helperText: 'Descreva seus horários de disponibilidade',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe seus horários de disponibilidade';
                  }
                  return null;
                },
              ),
              
              // CÓDIGO DO MODAL COMENTADO TEMPORARIAMENTE
              /*
              // Disponibilidade - Calendário
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AvailabilityCalendarScreen(
                        initialTimeSlots: _selectedTimeSlots.isNotEmpty 
                            ? _selectedTimeSlots 
                            : null,
                        onSave: (timeSlots) {
                          setState(() {
                            _selectedTimeSlots = timeSlots;
                          });
                        },
                      ),
                    ),
                  );
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Horários de Disponibilidade',
                    border: OutlineInputBorder(),
                    hintText: 'Toque para configurar os horários',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: _selectedTimeSlots.isEmpty
                      ? const Text(
                          'Nenhum horário configurado',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Text(
                          _getAvailabilityDisplayText(),
                          style: const TextStyle(color: Colors.black87),
                        ),
                ),
              ),
              
              if (_selectedTimeSlots.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'Por favor, configure os horários de disponibilidade',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              */
              
              const SizedBox(height: 16),
              
              // Valor
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 50.00',
                  prefixText: 'R\$ ',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tipo de Cobrança
              DropdownButtonFormField<PricingType>(
                value: _selectedPricingType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cobrança',
                  border: OutlineInputBorder(),
                ),
                items: PricingType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPricingType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Trabalho Voluntário
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF87a492)),
                  borderRadius: BorderRadius.circular(8),
                  color: _isVoluntary ? const Color(0xFF87a492).withOpacity(0.1) : Colors.transparent,
                ),
                child: CheckboxListTile(
                  title: const Text(
                    'Trabalho Voluntário',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Marque esta opção se o serviço for oferecido gratuitamente',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isVoluntary,
                  activeColor: const Color(0xFF87a492),
                  onChanged: (bool? value) {
                    setState(() {
                      _isVoluntary = value ?? false;
                      if (_isVoluntary) {
                        _valueController.clear();
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Contato
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contato',
                  border: OutlineInputBorder(),
                  hintText: 'Telefone, WhatsApp ou e-mail',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um contato';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Estado
              DropdownButtonFormField<Estado>(
                value: _states.contains(_selectedState) ? _selectedState : null,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: _states.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    _selectedCity = null;
                    _cities.clear();
                  });
                  if (value != null) {
                    _loadCities(value.sigla);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Cidade
              DropdownButtonFormField<City>(
                value: _cities.contains(_selectedCity) ? _selectedCity : null,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(),
                ),
                items: _cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Botão Salvar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87a492),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const LoadingWidget()
                      : Text(
                          widget.service == null ? 'Criar Serviço' : 'Atualizar Serviço',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF87a492),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selecione uma Categoria',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: ServiceCategory.categoriesByGroup.length,
                    itemBuilder: (context, index) {
                      final entry = ServiceCategory.categoriesByGroup.entries.elementAt(index);
                      final groupName = entry.key;
                      final categories = entry.value;
                      
                      return ExpansionTile(
                        title: Text(
                          groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF5a7a6a),
                          ),
                        ),
                        children: categories.map((category) {
                          return ListTile(
                            title: Text(category.displayName),
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                              Navigator.of(context).pop();
                            },
                            trailing: _selectedCategory == category
                                ? const Icon(Icons.check, color: Color(0xFF87a492))
                                : null,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getAvailabilityDisplayText() {
    if (_selectedTimeSlots.isEmpty) {
      return 'Nenhum horário configurado';
    }
    
    final schedule = AvailabilitySchedule(
      serviceId: '',
      timeSlots: _selectedTimeSlots,
    );
    return schedule.toDisplayString();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione estado e cidade'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validação de disponibilidade agora é feita pelo validator do campo de texto
    // if (_selectedTimeSlots.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Por favor, configure os horários de disponibilidade'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final serviceProvider = context.read<ServiceProvider>();
      
      // Usar o texto do campo de disponibilidade diretamente
      final availabilityText = _availabilityController.text.trim();
      
      // Garantir que o campo não esteja vazio (validação já foi feita pelo validator)
      if (availabilityText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, informe os horários de disponibilidade'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final service = Service(
        id: widget.service?.id ?? '',
        userId: authProvider.currentUser!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        availability: availabilityText, // Texto digitado pelo usuário
        value: _valueController.text.isNotEmpty 
            ? double.tryParse(_valueController.text) 
            : null,
        pricingType: _selectedPricingType,
        contact: _contactController.text.trim(),
        city: _selectedCity!.nome,
        state: _selectedState!.sigla,
        isVoluntary: _isVoluntary,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      String? serviceId;
      Service? createdService;
      
      if (widget.service == null) {
        success = await serviceProvider.createService(service);
        // Buscar o serviço recém-criado
        if (success) {
          await serviceProvider.loadMyServices(authProvider.currentUser!.id);
          final myServices = serviceProvider.myServices;
          if (myServices.isNotEmpty) {
            // Buscar o serviço mais recente com o mesmo título
            createdService = myServices.firstWhere(
              (s) => s.title == service.title && s.userId == service.userId,
              orElse: () => myServices.first,
            );
            serviceId = createdService.id;
          }
        }
      } else {
        serviceId = widget.service!.id;
        success = await serviceProvider.updateService(service);
      }

      // Salvar horários de disponibilidade - COMENTADO: usando apenas texto agora
      // Os horários são salvos no campo 'availability' do serviço como texto
      /*
      if (success && serviceId != null) {
        try {
          final availabilityService = AvailabilityService();
          final availabilitySchedule = AvailabilitySchedule(
            serviceId: serviceId,
            timeSlots: _selectedTimeSlots,
          );
          await availabilityService.createOrUpdateAvailability(availabilitySchedule);
        } catch (e) {
          print('Erro ao salvar horários: $e');
          // Não falha o salvamento do serviço se os horários falharem
        }
      }
      */

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.service == null 
                    ? 'Serviço criado com sucesso!' 
                    : 'Serviço atualizado com sucesso!'
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(serviceProvider.errorMessage ?? 'Erro ao salvar serviço'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao salvar serviço: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar serviço: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
