# FinanzApp - MVP, Roadmap y Plan de Escalabilidad

## ✨ Visión General
Una app móvil desarrollada en Flutter (Material 3), pensada para ayudar a los usuarios en Colombia a tomar control de sus finanzas personales, reducir gastos innecesarios, promover el ahorro y desarrollar una cultura financiera sana. Su evolución está diseñada en etapas, desde un MVP gratuito con monetización vía anuncios, hasta versiones premium y profesionales con análisis financiero potenciado por IA.

---

## 🧭 Roadmap General de Desarrollo

### Fase 1: MVP (Versión Gratuita con anuncios)
- Registro de gastos e ingresos hormiga.
- Categorías con íconos/emoticones.
- Tarjetas de resumen de balance.
- Historial de transacciones.
- Presupuestos fijos mensuales.
- Informes básicos (Balance, estadísticas, categoría).
- Exportación local a Excel.
- Publicidad: banner fijo + anuncios recompensados para exportar informes.
- SQLite como base de datos local.
- Interfaz Material 3 con animaciones suaves.
- Notificaciones básicas (ahorro, pagos mensuales).
- Login (Firebase Auth básico, correo y Google).

### Fase 2: Versión Pro (USD 5 mensual)
- Todo lo anterior +
- Notificaciones inteligentes.
- Personalización avanzada de categorías.
- Widget de ingreso rápido en home (texto o voz).
- Asistente financiero por IA (chatbot).
- Análisis avanzado de patrones de gasto.
- Consejos personalizados.
- Proyecciones y provisiones automáticas.
- Notificaciones inteligentes basadas en IA.
- Herramientas de optimización tributaria (deducciones, tips legales).
- Integración futura con APIs bancarias (actualización futura).

---

## 📱 Pantallas Principales del MVP

### 1. Balance
- Tarjeta superior con balance (COP), ingresos y gastos.
- 2 botones: Registrar ingreso / gasto.
  - Formulario: Descripción, monto, categoría (emoticón), auto-fecha.
- Historial reciente (expandible, ordenado por fecha).

### 2. Budget (Presupuesto)
- Botones ingreso/gasto (fijo).
  - Mismo formulario que Balance.
  - Categorías mensuales (distintas a gastos hormiga).
- Control y seguimiento de presupuestos mensuales.

### 3. Reports (Informes)
- Tarjeta 1: Balance (fijo + hormiga).
- Tarjeta 2: Estadísticas (expandible)
  - Día con más gastos.
  - Promedio diario.
  - Ahorro potencial (regla 50/30/20).
- Tarjeta 3: Gastos por categoría (con porcentajes y detalles).
- Botón de exportar Excel (local o nube si es Pro).

### 4. Summary (Resumen)
- Tarjetas mensuales (expandibles):
  - Transacciones por mes.
  - Iconos por categoría.
  - Solo mes actual es editable.
  - Edición con restricciones por mes.

### 5. Autenticación / Login
- Pantalla de bienvenida (Splash + animación de carga con `Rive` o `flare_flutter`).
- Login por correo y Google.
- Registro básico con nombre, país, ciudad.

### 6. Chat (Premium/Pro)
- Chat embebido en la app.
- Fase Premium: respuestas automáticas.
- Fase Pro: integración con IA financiera.

---

## 💸 Monetización
- Publicidad:
  - Banner permanente (AdMob).
  - Anuncios recompensados en la pantalla informes - reports.
- Suscripciones mensuales:
  - Pro: USD 5/mes

| Funcionalidad                    | Gratuito | Pro |
|----------------------------------|----------|-----|
| Registro ingresos/gastos         | ✅       | ✅  |
| Presupuesto fijo                 | ✅       | ✅  |
| Informes básicos                 | ✅       | ✅  |
| Exportar Excel (local)           | ✅       | ✅  |
| Login + sincronización Firebase  | ✅       | ✅  |
| Widget en home (texto/voz)       | ❌       | ✅  |
| Chat financiero IA               | ❌       | ✅  |
| Notificaciones IA avanzadas      | ❌       | ✅  |
| Optimización tributaria          | ❌       | ✅  |
| Integración bancaria             | ❌       | 🔜  |

---

## 🧱 Estructura del Proyecto y Buenas Prácticas

### Estructura actual Flutter
```
lib/
├── main.dart
├── core/
│   ├── utils/
│   │   ├── extensions/
│   │   └── helpers/
│   ├── domain/
│   │   └── models/
│   ├── data/
│   │   ├── repositories/
│   │   └── datasources/
│   ├── theme/
│   │   └── app_theme.dart
│   ├── presentation/
│   │   ├── widgets/
│   │   └── screens/
│   └── services/ [Futuro]
│       ├── analytics_service.dart
│       └── notification_service.dart
├── features/
│   ├── balance/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── domain/
│   ├── budget/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── domain/
│   ├── reports/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── domain/
│   ├── summary/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── domain/
│   └── auth/ [Futuro]
│       ├── presentation/
│       └── domain/
└── config/ [Futuro]
    ├── router.dart
    └── providers.dart

assets/
├── images/
├── icons/
└── animations/ [Futuro]
```

### Notas sobre la estructura:
- Las carpetas marcadas con [Futuro] son para implementación posterior
- La estructura actual sigue un patrón de Clean Architecture modificado
- Los modelos y repositorios están centralizados en core
- Cada feature mantiene su propia capa de presentación y dominio
- Los widgets compartidos están en core/presentation/widgets

### Buenas prácticas
- **State management**: Riverpod.
- **Animaciones suaves**: Flutter Animate + Material 3 transitions.
- **Animación de inicio**: Rive para splash personalizado.
- **SQL**: Abstracción con `drift`.
- **Arquitectura limpia** (clean architecture): separación clara entre UI, lógica de negocio y datos.
- **Notificaciones**: uso de `flutter_local_notifications` + calendario interno para recordatorios.
- **AdMob**: manejar por entorno (solo producción).
- **Suscripciones**: uso de `in_app_purchase` + validación en servidor (Firebase Functions).

---

## 🔍 IA Financiera (versión Pro)
- Análisis de patrones de gastos.
- Reglas básicas (50/30/20, ahorro por porcentaje).
- Chat tipo WhatsApp que analiza y responde sobre decisiones financieras.
- Asistente IA con rutinas:
  - Revisión semanal.
  - Consejo mensual.
  - Alertas en tiempo real (gasto elevado, oportunidad de ahorro).
- Integración con GPT para análisis financiero personalizado.

---

## 📦 Consideraciones para Escalabilidad
- Separar lógica y UI desde el MVP.
- Usar control de versiones en Firestore desde el inicio.
- Preparar entorno multi-idioma aunque solo se empiece en español.
- Modularizar funciones premium/pro desde el principio (flags).
- Implementar analíticas para ver el uso real por pantalla.
- Plan de pruebas con integración continua y testing automatizado.

---

## ✅ Recomendación General
Sí, estás siguiendo el camino correcto. Tienes una idea clara, útil, bien definida y con espacio para escalar. Con un MVP funcional, con buena experiencia de usuario y aprovechando Flutter + SQLite, puedes lanzar rápido y empezar a monetizar.

Cuando crees que está listo para implementar la IA o escalar a más países, ya habrás aprendido mucho de tus usuarios reales.

¡Vamos con toda! 💪
