import 'package:flutter/material.dart';
import '../models/player_lead.dart';
import '../services/local_storage_service.dart';
import '../theme/bda_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationScreen extends StatefulWidget {
  final Function(PlayerLead) onRegister;

  const RegistrationScreen({super.key, required this.onRegister});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _submitForm() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String docId = 'lead_${DateTime.now().millisecondsSinceEpoch}';
      
      try {
        final docRef = await FirebaseFirestore.instance.collection('jugadores').add({
          'nombre': _nameController.text.trim(),
          'correo': _emailController.text.trim(),
          'fechaRegistro': FieldValue.serverTimestamp(),
        });
        docId = docRef.id;
      } catch (e) {
        debugPrint('Firebase save error: $e');
      }

      final lead = PlayerLead(
        id: docId,
        firstName: _nameController.text.trim(),
        lastName: '',
        email: _emailController.text.trim(),
        identificacion: '0000000000',
        score: 0,
        gameType: '',
        timestamp: DateTime.now().toIso8601String(),
      );

      LocalStorageService().saveLead(lead).then((_) {
        if (mounted) {
          widget.onRegister(lead);
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BdaColors.lightBackground, BdaColors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: BdaColors.gold.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: BdaColors.navy.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Cabecera / Logotipo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: BdaColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BdaColors.lightGrey),
                    boxShadow: [
                      BoxShadow(
                        color: BdaColors.navy.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Assistant',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(text: 'BANCO DEL ', style: TextStyle(color: BdaColors.navy)),
                        TextSpan(text: 'AUSTRO', style: TextStyle(color: BdaColors.red)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MUNDIAL FAN FEST',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: BdaColors.navy,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registra tus datos, juega y gana',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                
                // Formulario
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: BdaColors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: const Border(
                            top: BorderSide(color: BdaColors.red, width: 6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: BdaColors.navy.withOpacity(0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre',
                                  labelStyle: const TextStyle(color: BdaColors.navy),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: BdaColors.navy, width: 2),
                                  ),
                                  prefixIcon: const Icon(Icons.person, color: BdaColors.navy),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu nombre';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Correo Electrónico',
                                  labelStyle: const TextStyle(color: BdaColors.navy),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: BdaColors.navy, width: 2),
                                  ),
                                  prefixIcon: const Icon(Icons.email, color: BdaColors.navy),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu correo';
                                  }
                                  if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: BdaColors.navy,
                                    disabledBackgroundColor: BdaColors.navy.withOpacity(0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: _isLoading ? 0 : 5,
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'CARGANDO...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'JUGAR AHORA',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
