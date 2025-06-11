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
- Publicidad: banner fijo + intersticiales.
- SQLite como base de datos local.

---

## 📱 Pantallas Principales del MVP

### 1. Balance
- Tarjeta superior con Saldo dispobible, ingresos, gastos y saldo inicial(el sobrante de Presupuesto).
- 2 botones: Registrar ingreso / gasto.
  - Formulario: Descripción, monto, categoría (emoticón), auto-fecha.
- Historial reciente (expandible, ordenado por fecha).

### 2. Budget (Presupuesto)
- Tarjeta superios con Saldo disponible para gastos hormiga, ingresos fijos y gastos fijos.
- Botones ingreso/gasto (fijo).
  - Mismo formulario que Balance.
  - Categorías mensuales (distintas a gastos hormiga).
- Control y seguimiento de presupuesto, este se guarda y aparece de forma mensual

### 3. Reports (Informes)
- Tarjeta 1: Balance (fijo + hormiga).
- Tarjeta 2: Estadísticas (expandible)
  - Promedio diario.
  - Regla 50%(Necesidades Basicas)/30%(Gastos Personales)/20%(Ahorro e inversion).
  - Analisis de gasto hormiga.
- Tarjeta 3: Gastos por categoría (con porcentajes y detalles).

### 4. Summary (Resumen)
- Tarjetas mensuales (expandibles):
  - Transacciones por mes.
  - Iconos por categoría.
  - Boton exportar

---

## 💸 Monetización
- Publicidad:
  - Banner permanente (AdMob).
  - Anuncios recompensados en la pantalla informes - reports.
- Suscripciones mensuales:
  - Pro: USD 2.5/mes (revisar despues)

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
- Chat tipo WhatsApp que analiza y responde sobre decisiones financieras.
- IA que permita conocer los impuestos que debe pagar y como optimizarlos. Colombia.
---
  
## 🎯 Funcionalidades Post-Producción

### 1. Funcionalidad de Ahorro
**Complejidad**: Media-Baja
**Tiempo estimado**: 3-4 días

#### Implementación necesaria:
1. **Nuevo modelo para Ahorro**:
   - Monto objetivo
   - Monto actual
   - Tipo de ahorro (emergencia, inversión)
   - Fecha objetivo
   - Estado del ahorro

2. **Modificación regla 50/30/20**:
   - Subdivisión del 20%:
     • Ahorro (10%)
     • Inversión (10%)
   - Tracking del progreso

3. **Nueva sección en Reports**:
   - Tarjeta "Ahorro e Inversión"
   - Gráfico de progreso
   - Estadísticas de cumplimiento

### 2. Funcionalidad de Deudas
**Complejidad**: Media
**Tiempo estimado**: 4-5 días

#### Implementación necesaria:
1. **Nuevo modelo para Deudas**:
   - Monto total de la deuda
   - Tasa de interés
   - Plazo
   - Cuota mensual
   - Estado de la deuda
   - Historial de pagos

2. **Integración con regla 50/30/20**:
   - Deudas dentro del 20%
   - Priorización automática
   - Calculadora de capacidad de pago

3. **Nueva sección en Reports**:
   - Tarjeta "Gestión de Deudas"
   - Plan de pagos
   - Proyección de liberación

#### Notas de implementación:
- Mantener consistencia con UI actual
- Reutilizar widgets existentes
- Agregar validaciones de porcentajes
- Incluir tooltips explicativos
- Implementar en orden: Ahorro → Deudas

---

## 📦 Consideraciones para Escalabilidad
- Separar lógica y UI desde el MVP.
- Usar control de versiones en Firestore desde el inicio.
- Preparar entorno multi-idioma aunque solo se empiece en español.
- Modularizar funciones premium/pro desde el principio (flags).
- Implementar analíticas para ver el uso real por pantalla.
- Plan de pruebas con integración continua y testing automatizado.

---