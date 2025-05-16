
# FinanzApp - Diseño Visual, Animaciones y Transiciones

## 🎨 Paleta de Colores (Material 3 adaptado)

| Elemento UI               | Color HEX    | Uso                                              |
|---------------------------|--------------|--------------------------------------------------|
| Primary                  | #0D47A1      | Botones, headers, íconos principales              |
| Primary Container        | #5472d3      | Fondos de tarjetas activas, botones destacados    |
| Secondary                | #1565C0      | Acciones secundarias, íconos alternativos         |
| Background               | #F5F5F5      | Fondo de pantallas                               |
| Surface                  | #FFFFFF      | Tarjetas, sheets, contenedores                   |
| Error                    | #D32F2F      | Mensajes de error, validaciones                  |
| Success                  | #388E3C      | Confirmaciones, estados positivos                |
| Outline                  | #BDBDBD      | Bordes, inputs                                   |
| Text Primary             | #212121      | Texto principal                                  |
| Text Secondary           | #616161      | Texto en descripciones, etiquetas                 |
| Text Inverse (On Primary)| #FFFFFF      | Texto sobre colores oscuros                      |

---

## 🧭 Tipografía

Utiliza la tipografía **Google Fonts - Roboto / Roboto Slab** combinadas con jerarquías de Material 3:

- Display Large: 32–40px – headers principales (bold)
- Title Medium: 20–24px – títulos secundarios
- Body Medium: 16px – texto regular, párrafos
- Label Small: 12px – etiquetas, inputs

---

## 🔁 Animaciones de Inicio

### Animación Splash (Rive o flare_flutter)
- Logo animado flotando con fade in + scale in.
- Fondo con transición de color (de blanco a azul suave).
- Carga de elementos secuenciales (nombre, ícono, spinner).
- Duración total: ~3.5 segundos.

```dart
// Ejemplo con Rive
RiveAnimation.asset(
  'assets/animaciones/logo_intro.riv',
  fit: BoxFit.contain,
);
```

---

## 💫 Transiciones Material 3 entre pantallas

### Recomendadas:
- `SharedAxisTransition`: entre pantallas relacionadas (inicio <-> resumen)
- `FadeThroughTransition`: para cambios sin conexión semántica directa
- `FadeScaleTransition`: para modales, diálogos

```dart
// Ejemplo con GoRouter o Navigator
PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
)
```

---

## 🪄 Microinteracciones y efectos UI

- Inputs con `AnimatedContainer` para estados activos/inactivos.
- Botones con `InkRipple` + haptic feedback leve.
- Expansión de tarjetas (`AnimatedSize`).
- Validación de formularios con `Shake` en errores.
- Tooltips suaves al pasar sobre íconos (para accesibilidad).

---

## 🧱 Componentes personalizados recomendados

- `CustomCard` con `Material elevation + rounded corners`.
- `AnimatedFloatingButton` para registrar ingresos/gastos.
- `ExpandableSummaryTile` para categorías.
- `BudgetProgressBar` con animaciones cuando se gasta más del 75%.

---

## 🌈 Modo Oscuro y Adaptabilidad

Implementa `ThemeMode.system` para adaptarse al sistema.

```dart
return MaterialApp(
  theme: lightThemeData,
  darkTheme: darkThemeData,
  themeMode: ThemeMode.system,
);
```

---

## 🎯 Experiencia Final

Una app intuitiva, rápida, visualmente agradable y con detalles cuidados. Cada transición y animación debe reforzar la sensación de orden y control financiero.

**Recuerda:** menos es más. Usa animaciones suaves, no recargues visualmente.

¡A construir una FinanzApp que enamore desde el primer uso! 🚀
