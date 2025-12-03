import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rating_provider.dart';
import '../providers/auth_provider.dart';
import '../models/rating.dart';
import '../models/user.dart';

class RatingScreen extends StatefulWidget {
  final String toUserId;
  final User? toUser;
  final String? serviceId;
  final String? requestId;

  const RatingScreen({
    super.key,
    required this.toUserId,
    this.toUser,
    this.serviceId,
    this.requestId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  Rating? _existingRating;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRating() async {
    final authProvider = context.read<AuthProvider>();
    final ratingProvider = context.read<RatingProvider>();

    if (authProvider.currentUser != null) {
      final existing = await ratingProvider.getExistingRating(
        fromUserId: authProvider.currentUser!.id,
        toUserId: widget.toUserId,
        serviceId: widget.serviceId,
        requestId: widget.requestId,
      );

      if (existing != null && mounted) {
        setState(() {
          _existingRating = existing;
          _selectedRating = existing.rating;
          _commentController.text = existing.comment ?? '';
        });
      }
    }
  }

  Future<void> _saveRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma nota'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final ratingProvider = context.read<RatingProvider>();

      if (authProvider.currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final rating = Rating(
        id: _existingRating?.id ?? '',
        fromUserId: authProvider.currentUser!.id,
        toUserId: widget.toUserId,
        serviceId: widget.serviceId,
        requestId: widget.requestId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        createdAt: _existingRating?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_existingRating != null) {
        success = await ratingProvider.updateRating(rating);
      } else {
        success = await ratingProvider.createRating(rating);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _existingRating != null
                    ? 'Avaliação atualizada com sucesso!'
                    : 'Avaliação enviada com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ratingProvider.errorMessage ?? 'Erro ao salvar avaliação',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar avaliação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_existingRating != null ? 'Editar Avaliação' : 'Avaliar'),
        backgroundColor: const Color(0xFF5a7a6a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informações do usuário
            if (widget.toUser != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF87a492),
                        child: Text(
                          widget.toUser!.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.toUser!.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.toUser!.city != null &&
                                widget.toUser!.state != null)
                              Text(
                                '${widget.toUser!.city}, ${widget.toUser!.state}',
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

            const SizedBox(height: 24),

            // Seleção de nota
            const Text(
              'Selecione uma nota',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5a7a6a),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      rating <= _selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      size: 50,
                      color: rating <= _selectedRating
                          ? Colors.amber
                          : Colors.grey,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Comentário
            const Text(
              'Comentário (opcional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5a7a6a),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Deixe um comentário sobre sua experiência...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // Botão Salvar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87a492),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _existingRating != null
                            ? 'Atualizar Avaliação'
                            : 'Enviar Avaliação',
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
    );
  }
}






