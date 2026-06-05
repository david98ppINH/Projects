import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Registrar la vista HTML para HubSpot
      ui_web.platformViewRegistry.registerViewFactory(
        'hubspot-form-view',
        (int viewId) {
          final element = html.DivElement()
            ..id = 'hubspot-form-container'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.overflowY = 'auto';

          // Inicializar el formulario con un leve delay tras montarse el elemento
          Future.delayed(const Duration(milliseconds: 150), () {
            js.context.callMethod('initHubspotForm', ['hubspot-form-container']);
          });

          return element;
        },
      );

      // Listener global de JavaScript para recibir el lead desde HubSpot
      js.context['onHubspotSubmitted'] = (String jsonStr) {
        final data = jsonDecode(jsonStr);
        final lead = PlayerLead(
          id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
          firstName: data['firstName'] ?? 'Jugador',
          lastName: data['lastName'] ?? '',
          email: data['email'] ?? '',
          identificacion: data['identificacion'] ?? '0000000000',
          score: 0,
          gameType: '',
          timestamp: DateTime.now().toIso8601String(),
        );

        LocalStorageService().saveLead(lead).then((_) {
          if (mounted) {
            widget.onRegister(lead);
          }
        });
      };
    } else {
      // Configuración de WebView para Android/iOS
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              // Prevenir redirecciones externas (ej. a la web del banco) para no salirse del quiosco
              if (!request.url.startsWith('about:blank') && !request.url.startsWith('data:')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..addJavaScriptChannel(
          'HubspotChannel',
          onMessageReceived: (JavaScriptMessage message) {
            final data = jsonDecode(message.message);
            final lead = PlayerLead(
              id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
              firstName: data['firstName'] ?? 'Jugador',
              lastName: data['lastName'] ?? '',
              email: data['email'] ?? '',
              identificacion: data['identificacion'] ?? '0000000000',
              score: 0,
              gameType: '',
              timestamp: DateTime.now().toIso8601String(),
            );

            LocalStorageService().saveLead(lead).then((_) {
              if (mounted) {
                widget.onRegister(lead);
              }
            });
          },
        )
        ..loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script charset="utf-8" type="text/javascript" src="https://js.hsforms.net/forms/embed/v2.js"></script>
  <style>
    body {
      margin: 0;
      padding: 10px;
      background-color: white;
      font-family: sans-serif;
    }
  </style>
</head>
<body>
  <div id="hubspot-form-container"></div>
  <script>
    if (window.hbspt) {
      window.hbspt.forms.create({
        portalId: "41516556",
        formId: "ad6aa7df-8392-4808-8864-e905be4582d3",
        region: "na1",
        target: '#hubspot-form-container',
        inlineMessage: "Gracias por registrarte."
      });
    }

    window.addEventListener('message', function(event) {
      if (event.data.type === 'hsFormCallback' && event.data.eventName === 'onFormSubmitted') {
        const submissionData = event.data.data;
        let email = "";
        let firstName = "";
        let lastName = "";
        let identificacion = "";

        if (submissionData) {
          if (Array.isArray(submissionData)) {
            submissionData.forEach(function(field) {
              var name = (field.name || '').toLowerCase();
              var val = field.value || '';
              
              if (name === 'email' || name === 'correo' || name === 'mail') {
                email = val;
              } else if (name === 'firstname' || name === 'first_name' || name === 'nombre' || name === 'nombres' || name === 'name') {
                firstName = val;
              } else if (name === 'lastname' || name === 'last_name' || name === 'apellido' || name === 'apellidos') {
                lastName = val;
              } else if (name === 'cedula' || name === 'identificacion' || name === 'num_cedula' || name === 'identificación' || name === 'documento' || name === 'id') {
                identificacion = val;
              }
            });
          } else {
            const vals = submissionData.submissionValues || submissionData;
            if (vals && typeof vals === 'object') {
              email = vals.email || vals.correo || vals.mail || email;
              firstName = vals.firstname || vals.first_name || vals.firstName || vals.nombre || vals.nombres || vals.name || firstName;
              lastName = vals.lastname || vals.last_name || vals.lastName || vals.apellido || vals.apellidos || lastName;
              identificacion = vals.identificacion || vals.cedula || vals.num_cedula || vals.identificación || vals.documento || vals.id || identificacion;
            }
          }
        }

        const leadData = JSON.stringify({
          firstName: firstName || 'Jugador',
          lastName: lastName || '',
          email: email || '',
          identificacion: identificacion || '0000000000'
        });

        if (window.HubspotChannel) {
          window.HubspotChannel.postMessage(leadData);
        }
      }
    });
  </script>
</body>
</html>
''');
    }
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
                        child: kIsWeb
                            ? const SizedBox(
                                width: double.infinity,
                                height: 460,
                                child: HtmlElementView(
                                  viewType: 'hubspot-form-view',
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 460,
                                child: WebViewWidget(
                                  controller: _webViewController!,
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
