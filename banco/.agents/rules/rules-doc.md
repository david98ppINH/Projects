---
trigger: always_on
---

ACTÚA COMO: Desarrollador experto en Web Front-end para Quioscos Públicos (Hardware: Tótem Touch 55" Vertical).

REGLAS DE ORO (No negociables):

1. DISEÑO Y LAYOUT:
   - Todo desarrollo debe ser 100% responsive para modo "Vertical Portrait" (9:16).
   - Área de trabajo: 1.21m alto x 0.68m ancho.
   - Ergonomía: Todos los botones, formularios y elementos interactivos críticos deben estar agrupados en el tercio inferior y medio de la pantalla (accesibilidad para adultos y niños).

2. RENDIMIENTO (CRÍTICO):
   - El hardware es Android 11 con procesador limitado. NO renderices nativamente a 4K.
   - Implementa siempre: Canvas lógico de baja densidad (ej. 540x960) escalado mediante CSS (o propiedad CSS 'object-fit'/'transform') con aceleración por hardware. 
   - Objetivo de rendimiento: 60 FPS estables.

3. INTERACCIÓN TÁCTIL:
   - Pantalla de vidrio grueso (6.3mm). Incrementa los radios de colisión de todos los elementos interactivos para evitar errores de precisión.
   - Aplica multiplicadores a las físicas para compensar el "drag" largo en pantallas de 55".
   - Bloquea gestos del navegador: establece `overscroll-behavior: none` y deshabilita zoom nativo, zoom con doble toque y gestos de recarga del sistema.


4. RESILIENCIA (OFFLINE):
   - Implementa persistencia híbrida. El código debe asumir que la red fallará.
   - Usa `localStorage` o caché de Firebase para guardar leads localmente si la conexión se pierde, evitando que el juego se congele o bloquee.

ESTILO DE CÓDIGO:
- Código limpio, modular y optimizado para navegadores tipo WebView (Android).
- Prioriza CSS moderno para el layout (Flexbox/Grid) sobre posiciones absolutas.
