
# FinanzApp - Lógica de Funcionamiento

## 🔄 Flujo General de la Aplicación

1. **Inicio (Splash + Login)**
   - Al abrir la app:
     - Se muestra animación de inicio (Rive).
     - Se consulta el estado de autenticación (Firebase Auth).
     - Si está autenticado, se redirige al Home.
     - Si no, se muestra pantalla de Login (correo/Google).

2. **Home (Inicio)**
   - Muestra:
     - Tarjeta resumen de balance actual.
     - Botones de ingreso/gasto hormiga.
     - Historial de últimas transacciones (SQLite).
   - Acciones:
     - Registro de nueva transacción.
     - Llamado al módulo de categorías.
     - Guardado local en SQLite.
     - Si es Premium: sincronización con Firestore.

3. **Presupuestos Fijos**
   - Registro de ingresos/gastos fijos (mensuales).
   - Solo edita el mes actual.
   - Datos se almacenan en tabla local.
   - Si es Premium: sincroniza con la nube.

4. **Resumen**
   - Consulta a la base de datos local agrupada por mes.
   - Muestra íconos por categoría.
   - Permite visualizar y editar registros del mes actual.

5. **Informes**
   - Cálculo local del balance (ingresos - gastos).
   - Estadísticas: promedio diario, ahorro potencial, categorías.
   - Exportación a Excel local (gratuito).
   - Si es Premium: exportar a Drive.

6. **Widget (Premium/Pro)**
   - Permite ingreso rápido de gasto o ingreso.
   - Funciona como acceso directo al formulario.
   - Si el usuario no tiene acceso: muestra mensaje de upgrade.

7. **Notificaciones**
   - Basado en lógica de fechas próximas o gastos altos.
   - Se programan localmente (`flutter_local_notifications`).
   - En versiones Pro, se activa IA para análisis de comportamiento.

8. **Chat (Premium/Pro)**
   - Premium: respuestas automatizadas con lógica de preguntas frecuentes.
   - Pro: Chat IA con análisis personalizado de finanzas del usuario.
   - Interfaz de chat se guarda localmente con histórico cifrado.

9. **Sincronización con la nube (Premium/Pro)**
   - Cada vez que se guarda un nuevo ingreso/gasto:
     - Se verifica si es usuario premium.
     - Se hace push a Firestore (con validación y seguridad).
   - Firestore replica en tiempo real si hay conexión.

10. **Modo sin conexión**
   - Siempre guarda localmente primero (offline first).
   - Sincroniza cuando detecta conexión (versión premium/pro).

---

## 📊 Lógica de Datos

### Entidades principales:
- `Transaccion`
  - id, tipo (ingreso/gasto), valor, fecha, categoría, descripción.
- `Presupuesto`
  - id, tipo, valor, categoría, mes, año.
- `Usuario`
  - id, nombre, correo, ciudad, tipo_suscripción.

### Estructura en SQLite:
- `transactions`
- `budgets`
- `users`
- `configurations` (flags, preferencias)
- `notifications`

---

## 🧠 Lógica Premium/Pro (Flags y Control)
- La app tiene una bandera local para verificar la suscripción.
- Al intentar usar función Premium:
  - Si tiene acceso, ejecuta función.
  - Si no, redirige a pantalla de upgrade.
- Flags como:
  - `hasPremiumAccess`
  - `hasProAccess`
  - `enableCloudSync`
  - `enableWidget`
  - `enableChatAI`

---

## 📁 Flujo de sincronización
```
+--------------+          +--------------+        +--------------+
| Usuario crea |  ---->   |   SQLite DB  | ---->  | Firestore DB |
| transacción  |          | (guardado)   |        | (si premium) |
+--------------+          +--------------+        +--------------+
```

- La app prioriza SQLite.
- Se hace sincronización en background.
- Usa `connectivity_plus` para verificar red.

---

## 🚨 Manejo de errores
- Validaciones en formularios.
- Manejo de errores con try/catch.
- Visual feedback con snackbars/dialogs.
- Logs locales con `logger` package.
- Reportes opcionales a Firestore (crash logs, Pro).

---

## 🧪 Testing
- Unit tests para lógica de negocio.
- Widget tests para formularios y pantallas clave.
- Integración con CI para pruebas automatizadas.

---

## ✅ Conclusión
La app funciona bajo una lógica simple pero poderosa: registrar, clasificar, analizar y ayudar al usuario a mejorar su vida financiera. Todo el flujo está diseñado para crecer gradualmente según la versión que tenga el usuario, manteniendo la escalabilidad, sincronización y seguridad como ejes clave.
