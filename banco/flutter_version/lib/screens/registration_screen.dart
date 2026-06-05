import 'package:flutter/material.dart';
import '../models/player_lead.dart';
import '../services/local_storage_service.dart';
import '../theme/bda_theme.dart';

class RegistrationScreen extends StatefulWidget {
  final Function(PlayerLead) onRegister;

  const RegistrationScreen({super.key, required this.onRegister});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simular un pequeño retardo de procesamiento local (a nivel de experiencia de usuario)
    await Future.delayed(const Duration(milliseconds: 600));

    final lead = PlayerLead(
      id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      identificacion: _idController.text.trim(),
      score: 0,
      gameType: '',
      timestamp: DateTime.now().toIso8601String(),
    );

    // Guardar en el servicio local
    await LocalStorageService().saveLead(lead);

    setState(() {
      _isLoading = false;
    });

    widget.onRegister(lead);
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
          // Fondo decorativo con siluetas deportivas abstractas o líneas
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
                    text: TextSpan(
                      style: const TextStyle(
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
                
                // Formulario posicionado ergonómicamente en la mitad/inferior del canvas
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
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'REGISTRO DE JUGADOR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: BdaColors.navy,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Nombres
                              TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombres',
                                  prefixIcon: Icon(Icons.person, color: BdaColors.navy),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa tus nombres' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Apellidos
                              TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Apellidos',
                                  prefixIcon: Icon(Icons.person_outline, color: BdaColors.navy),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa tus apellidos' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Cédula / Identificación
                              TextFormField(
                                controller: _idController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cédula / Identificación',
                                  prefixIcon: Icon(Icons.badge, color: BdaColors.navy),
                                  hintText: 'Ej. 0102030405',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Ingresa tu identificación';
                                  }
                                  if (val.trim().length < 8) {
                                    return 'Identificación inválida';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Correo Electrónico
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo Electrónico',
                                  prefixIcon: Icon(Icons.email, color: BdaColors.navy),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Ingresa tu correo';
                                  }
                                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegex.hasMatch(val.trim())) {
                                    return 'Correo electrónico no válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              
                              // Botón de Enviar (Grande y táctil)
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: BdaColors.redGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BdaColors.red.withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text(
                                          'EMPEZAR A JUGAR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            letterSpacing: 1,
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
