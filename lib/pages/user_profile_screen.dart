import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user.dart';
import '../models/rating.dart';
import '../services/auth_service.dart';
import '../providers/rating_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'rating_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  RatingStats? _ratingStats;
  List<Rating> _ratings = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Adiar a chamada de _loadRatings até após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRatings();
    });
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getUserProfile(widget.userId);
      
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar perfil: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRatings() async {
    try {
      final ratingProvider = context.read<RatingProvider>();
      await ratingProvider.loadRatingsByUserId(widget.userId);
      
      if (mounted) {
        setState(() {
          _ratings = ratingProvider.ratings;
          _ratingStats = ratingProvider.stats;
        });
      }
    } catch (e) {
      print('Erro ao carregar avaliações: $e');
    }
  }

  Future<void> _navigateToRatingScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingScreen(
          toUserId: widget.userId,
          toUser: _user,
        ),
      ),
    );

    if (result == true) {
      _loadRatings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: const Color(0xFF5a7a6a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: const Color(0xFFd68a7a),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadUserProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF87a492),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Usuário não encontrado',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card do perfil
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF87a492),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(
                                      FontAwesomeIcons.user,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Nome
                                  Text(
                                    _user!.fullName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  // Avaliação média
                                  if (_ratingStats != null && _ratingStats!.totalRatings > 0) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ...List.generate(5, (index) {
                                          final rating = index + 1;
                                          return Icon(
                                            rating <= _ratingStats!.averageRating.round()
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 20,
                                            color: rating <= _ratingStats!.averageRating.round()
                                                ? Colors.amber
                                                : Colors.grey,
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings})',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Email
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _user!.email,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  if (_user!.city != null && _user!.state != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          FontAwesomeIcons.locationDot,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_user!.city}, ${_user!.state}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Botão de avaliar (se não for o próprio usuário)
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.currentUser != null &&
                                  authProvider.currentUser!.id != widget.userId) {
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: ElevatedButton.icon(
                                      onPressed: _navigateToRatingScreen,
                                      icon: const Icon(Icons.star),
                                      label: const Text('Avaliar Usuário'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF87a492),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Avaliações
                          if (_ratings.isNotEmpty) ...[
                            Card(
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Avaliações',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (_ratingStats != null)
                                          Text(
                                            '${_ratingStats!.totalRatings} avaliações',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ..._ratings.take(5).map((rating) => _buildRatingCard(rating)),
                                    if (_ratings.length > 5)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'E mais ${_ratings.length - 5} avaliações...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Descrição (se existir)
                          if (_user!.description != null && _user!.description!.isNotEmpty) ...[
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sobre',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _user!.description!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Informações de contato
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informações de Contato',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Telefone
                                  _buildInfoRow(
                                    icon: FontAwesomeIcons.phone,
                                    label: 'Telefone',
                                    value: _user!.phone,
                                    color: const Color(0xFF87a492),
                                  ),
                                  
                                  // Email
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    icon: Icons.email,
                                    label: 'Email',
                                    value: _user!.email,
                                    color: const Color(0xFF87a492),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Endereço (se disponível)
                          if (_user!.street != null || _user!.neighborhood != null) ...[
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Localização',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          FontAwesomeIcons.locationDot,
                                          size: 20,
                                          color: const Color(0xFFd4a687),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (_user!.street != null) ...[
                                                Text(
                                                  '${_user!.street}${_user!.number != null ? ", ${_user!.number}" : ""}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (_user!.complement != null && _user!.complement!.isNotEmpty) ...[
                                                Text(
                                                  _user!.complement!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (_user!.neighborhood != null) ...[
                                                Text(
                                                  _user!.neighborhood!,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (_user!.city != null && _user!.state != null) ...[
                                                Text(
                                                  '${_user!.city} - ${_user!.state}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (_user!.cep != null) ...[
                                                Text(
                                                  'CEP: ${_user!.cep}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
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
                                    'Membro desde ${_formatDate(_user!.createdAt)}',
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (index) {
                final starRating = index + 1;
                return Icon(
                  starRating <= rating.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: starRating <= rating.rating ? Colors.amber : Colors.grey,
                );
              }),
              const Spacer(),
              Text(
                _formatDate(rating.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ],
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

