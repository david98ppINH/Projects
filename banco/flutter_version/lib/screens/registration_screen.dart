import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _scrollController = ScrollController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final hasFocus = _nameFocusNode.hasFocus || _emailFocusNode.hasFocus;
    if (_isKeyboardVisible != hasFocus) {
      setState(() {
        _isKeyboardVisible = hasFocus;
      });
    }

    if (_emailFocusNode.hasFocus) _scheduleEmailScroll();
  }

  void _scheduleEmailScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFormBottom();
    });
    Future<void>.delayed(
      const Duration(milliseconds: 260),
      _scrollToFormBottom,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 520),
      _scrollToFormBottom,
    );
  }

  Future<void> _scrollToFormBottom() async {
    if (!mounted ||
        !_emailFocusNode.hasFocus ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target = position.maxScrollExtent;
    if (target <= position.minScrollExtent) return;

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _submitForm() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
      });

      String docId = 'lead_${DateTime.now().millisecondsSinceEpoch}';

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

      unawaited(_saveLeadInBackground(lead));

      if (mounted) {
        widget.onRegister(lead);
      }
    }
  }

  Future<void> _saveLeadInBackground(PlayerLead lead) async {
    try {
      await FirebaseFirestore.instance
          .collection('jugadores')
          .doc(lead.id)
          .set({
            'nombre': lead.firstName,
            'correo': lead.email,
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Firebase save error: $e');
    }

    try {
      await LocalStorageService().saveLead(lead);
    } catch (e) {
      debugPrint('Local save error: $e');
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.removeListener(_onFocusChange);
    _nameController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: BdaColors.sipyBackground,
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -110,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: BdaColors.sipySoftGrey.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -170,
              left: -110,
              child: Container(
                width: 620,
                height: 620,
                decoration: BoxDecoration(
                  color: BdaColors.sipyBlue.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 72,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: BdaColors.sipyHeaderBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: BdaColors.sipyInputBorder.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        BdaAssets.sippyLogo,
                        width: 94,
                        height: 47,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  const Text(
                    'MUNDIAL FAN FEST',
                    style: TextStyle(
                      fontFamily: BdaFonts.gotham,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: BdaColors.sipyBlue,
                      letterSpacing: -2.8,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Registra tus datos, juega y gana',
                    style: TextStyle(
                      fontFamily: BdaFonts.gotham,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: BdaColors.sipyBodyText,
                      height: 1.3,
                    ),
                  ),

                  Expanded(
                    flex: 7,
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                42,
                                46,
                                42,
                                62,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: const Border(
                                  top: BorderSide(
                                    color: BdaColors.sipyGreen,
                                    width: 5,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: BdaColors.sipyShadowBlue.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: -10,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFieldLabel('NOMBRE'),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _nameController,
                                      focusNode: _nameFocusNode,
                                      hintText: 'Nombre',
                                      icon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Por favor ingresa tu nombre';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    _buildFieldLabel('CORREO ELECTRÓNICO'),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      hintText: 'Correo Electrónico',
                                      icon: Icons.mail_outline,
                                      keyboardType: TextInputType.emailAddress,
                                      onTap: _scheduleEmailScroll,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Por favor ingresa tu correo';
                                        }
                                        if (!RegExp(
                                          r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                        ).hasMatch(value)) {
                                          return 'Ingresa un correo válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 40),
                                    SizedBox(
                                      height: 70,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: BdaColors.sipyGreen,
                                          disabledBackgroundColor: BdaColors
                                              .sipyGreen
                                              .withValues(alpha: 0.65),
                                          foregroundColor: BdaColors.sipyBlue,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              35,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: BdaColors
                                                              .sipyBlue,
                                                          strokeWidth: 3,
                                                        ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'CARGANDO...',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          BdaFonts.gotham,
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: BdaColors.sipyBlue,
                                                      letterSpacing: -1.2,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'JUGAR',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          BdaFonts.gotham,
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: BdaColors.sipyBlue,
                                                      letterSpacing: -1.6,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'AHORA',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          BdaFonts.gotham,
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: BdaColors.sipyBlue,
                                                      letterSpacing: -1.6,
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: _isKeyboardVisible ? 320.0 : 0.0,
                              curve: Curves.easeOut,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: BdaFonts.gotham,
          color: BdaColors.sipyMutedText,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.2,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onTap: onTap,
      style: const TextStyle(
        fontFamily: BdaFonts.gotham,
        color: BdaColors.sipyBodyText,
        fontSize: 22,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: BdaColors.sipyInputFill,
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: BdaFonts.gotham,
          color: BdaColors.sipyHintText,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: BdaColors.sipyBlue, size: 28),
        prefixIconConstraints: const BoxConstraints(minWidth: 64),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BdaColors.sipyInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BdaColors.sipyInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BdaColors.sipyBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BdaColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BdaColors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
