# Vaulted — Manual de Usuario

Aplicación premium de inventario del hogar para familias.

---

## Índice de Contenidos

1. [Inicio de Sesión](#1-inicio-de-sesión)
2. [Dashboard](#2-dashboard)
3. [Propiedades](#3-propiedades)
4. [Inventario](#4-inventario)
5. [Detalle de Objeto](#5-detalle-de-objeto)
6. [Escaneo QR](#6-escaneo-qr)
7. [Movimientos](#7-movimientos--operaciones)
8. [Mantenimiento](#8-mantenimiento)
9. [Seguros](#9-seguros)
10. [Guardarropa](#10-guardarropa)
11. [Escaneo con IA](#11-escaneo-con-ia)
12. [Asistente IA](#12-asistente-ia)
13. [Equipo](#13-equipo--usuarios)
14. [Configuración](#14-configuración)

---

## 1. Inicio de Sesión

Accede a tu cuenta de Vaulted con email y contraseña, y verifica tu identidad con autenticación de dos factores.

### Cómo Usar

1. Abre la app Vaulted
2. Escribe tu correo electrónico en el campo Email
3. Escribe tu contraseña en el campo Password
4. Toca **Log in** para entrar

Si tu cuenta tiene autenticación de dos factores activada, verás la pantalla de verificación.

### Verificar con Código MFA

1. Abre tu app autenticadora (Google Authenticator, Authy, etc.)
2. Copia el código de 6 dígitos que aparece
3. Escribe el código en la app Vaulted
4. Toca **Verify** para completar el acceso

### Aceptar una Invitación

Si recibiste una invitación por email:

1. Abre el enlace de invitación en tu email
2. Crea una contraseña segura (mínimo 12 caracteres, con mayúscula, minúscula, número y símbolo)
3. Confirma la contraseña escribiéndola de nuevo
4. Toca **Create account**

Si tu rol requiere MFA, configurarás el código en el siguiente paso.

### Consejos

- Si olvidaste tu contraseña, contacta al administrador de tu familia
- El código MFA cambia cada 30 segundos; si expira, espera al siguiente
- Guarda el enlace de invitación en un lugar seguro; caduca en 48 horas

---

## 2. Dashboard

La pantalla principal donde ves un resumen de tu inventario, propiedades y accesos directos a las funciones más usadas.

### Cómo Usar

1. Al abrir la app, estás en el Dashboard
2. Debajo del saludo verás dos tarjetas: **Total Value** y **Total Items**
3. Debajo verás el estado de tus objetos (cuántos están activos, en préstamo, en reparación, etc.)

### Ver tus Propiedades

1. Desliza hacia abajo para ver todas tus propiedades
2. Cada tarjeta muestra: nombre, ubicación, tipo y cantidad de objetos
3. Toca cualquier propiedad para ver sus pisos y habitaciones

### Usar los Accesos Directos

En la sección **QUICK ACTIONS** tienes 4 botones:

1. **Scan QR** — abre la cámara para escanear un código QR de objeto
2. **AI Assistant** — abre el chat con inteligencia artificial
3. **Operations** — ve los préstamos y movimientos activos
4. **Maintenance** — revisa el mantenimiento programado

### Abrir el Menú de Usuario

1. Toca el círculo con tus iniciales o avatar en la esquina superior derecha
2. Desde ahí puedes:
   - Ir a Maintenance
   - Ir a Settings
   - Cerrar sesión (Sign out)

### Consejos

- Desliza hacia abajo para actualizar los datos
- Si eres Owner o Manager, verás el botón **Add** para agregar propiedades
- Los valores totales solo los ven Owners y Auditors

---

## 3. Propiedades

Gestiona tus propiedades, pisos y habitaciones. Cada propiedad puede ser tu casa principal, casa de vacaciones o alquiler.

### Cómo Usar

### Ver una Propiedad

1. Desde el Dashboard, toca una propiedad
2. Verás la foto de portada, dirección y tipo
3. Desliza hacia abajo para ver los pisos y habitaciones

### Agregar una Propiedad

1. En el Dashboard, toca **Add** junto a **YOUR PROPERTIES**
2. Llena los datos: nombre, tipo, dirección
3. Opcional: agrega una foto de portada
4. Toca **Save** para crear

### Agregar un Piso

1. Dentro de una propiedad, toca el botón flotante morado
2. Selecciona **Add floor**
3. Escribe el nombre del piso (ej: Primer Piso, Segundo Piso)
4. Toca **Add floor**

### Agregar una Habitación

1. En un piso, toca el botón **+** junto al nombre del piso
2. Escribe el nombre de la habitación
3. Selecciona el tipo de habitación
4. Toca **Add room**

### Agregar Secciones

Una habitación puede tener secciones (cajones, estantes, gabinetes):

1. Dentro de una habitación, toca **Sections**
2. Para agregar: toca el icono + o escanea con IA
3. Define código (ej: 1A), nombre y tipo de sección
4. Toca **Add section**

### Cambiar la Foto de Portada

1. Dentro de una propiedad, toca el icono de cámara
2. Elige cámara o galería
3. Toma o selecciona la foto
4. La foto se subirá automáticamente

### Consejos

- El tipo de propiedad afecta el color de la insignia (Primary=oro, Vacation=azul, Rental=gris)
- Los objetos **sin asignar** aparecen en banner naranja; toca **Assign** para ubicarlos
- Solo Owners y Managers pueden agregar o editar propiedades

---

## 4. Inventario

Consulta, busca y gestiona todos tus objetos inventariados en un solo lugar.

### Cómo Usar

### Buscar Objetos

1. Desde el Dashboard, toca **Scan QR** o ve a **Asset Directory**
2. En la barra de búsqueda, escribe nombre, etiqueta o número de serie
3. Los resultados aparecen automáticamente

### Filtrar por Categoría

1. Toca una categoría: All, Furniture, Art, Technology, Wardrobe, Vehicles, Wine, Sports
2. La lista se actualiza para mostrar solo esa categoría

### Filtrar por Estado

1. Toca un estado: Active, Loaned, Repair, Storage
2. Puedes combinar filtros de categoría y estado

### Filtrar por Propiedad

1. Toca el nombre de una propiedad
2. Solo verás objetos de esa propiedad

### Ordenar Resultados

1. Toca **Recent** para ver los más recientes
2. Toca **Value** para ver por valor (solo Owners/Auditors)
3. Toca **Name A-Z** para ordenar alfabéticamente

### Ver Objetos sin Ubicación

1. Toca **Unlocated** para ver objetos sin piso ni habitación asignados

### Ver Detalles de un Objeto

1. Toca cualquier objeto
2. Verás: foto, valor, especificaciones, historial, mantenimiento
3. Si puedes editar, toca **Edit Item** abajo

### Consejos

- Usa múltiples filtros para encontrar objetos específicos rápido
- El filtro **Unlocated** es útil para asignar objetos pendientes
- Los valores solo los ven Owners y Auditors

---

## 5. Detalle de Objeto

Toda la información de un objeto: fotos, valor, especificaciones, historial y mantenimiento.

### Cómo Usar

### Ver Información del Objeto

1. Busca o escanea un objeto
2. Toca para ver los detalles
3. Desliza para ver toda la información

### Secciones Disponibles

- **Foto** — imagen principal
- **Valor** — precio actual (solo Owners/Auditors)
- **Specifications** — categoría, estado, serie, marca, modelo
- **Valuation** — precio de compra, fecha, valor actual
- **Maintenance** — tareas de mantenimiento programadas
- **Documents** — archivos adjuntos (beta)
- **Tags** — etiquetas personalizadas
- **QR Code** — código QR del objeto
- **History** — historial de cambios y movimientos

### Agregar una Foto

1. En el detalle, toca el icono de cámara
2. Elige cámara o galería
3. Toma o selecciona la foto
4. Se subirá automáticamente

### Agregar Mantenimiento

1. Desliza hasta **Maintenance**
2. Toca **Add maintenance**
3. Define: título, fecha, recurrencia (opcional)
4. Toca **Save**

### Ver Historial

1. Desliza hasta **History**
2. Toca **View all** para expandir
3. Verás: fecha, acción, usuario

### Editar el Objeto

1. Toca **Edit Item** abajo de la pantalla
2. Modifica los campos necesarios
3. Toca **Save** para guardar

### Consejos

- Los valores solo los ven Owners y Auditors
- Para prendas de wardrobe, verás el estado de limpieza
- El QR Code sirve para escanear rápido el objeto

---

## 6. Escaneo QR

Usa la cámara para escanear códigos QR y encontrar objetos o habitaciones rápidamente.

### Cómo Usar

### Escanea un Objeto

1. Desde el Dashboard, toca **Scan QR**
2. Apunta la cámara al código QR del objeto
3. El código debe estar dentro de los marcos blancos
4. Al detectar, irás automáticamente al detalle del objeto

### Escanea una Habitación

1. Apunta al código QR de una sección
2. Irás directo a esa sección en la pantalla de ubicaciones

### Consejos

- Mantén el código QR bien iluminado
- Sostén el teléfono sin movimiento
- El código debe caber dentro de los 4 marcos blancos
- Códigos QR de objetos: `vaulted://items/ID`
- Códigos QR de secciones: `vaulted://rooms/ID?section=CODE`
- Si no detecta, limpia el lente y mejora la luz

---

## 7. Movimientos / Operaciones

Gestiona préstamos, reparaciones y disposiciones de objetos. Controla dónde están tus objetos en todo momento.

### Cómo Usar

### Ver Operaciones

1. Desde el Dashboard, toca **Operations** o ve a la pestaña
2. Verás dos pestañas: Active e History
3. Active = operaciones en progreso
4. History = operaciones terminadas

### Crear una Operación

1. Toca el botón **New Operation** (+)
2. Selecciona el tipo:
   - **Loan** — prestar objetos a alguien
   - **Repair** — enviar a reparación
   - **Disposal** — dar de baja/retirar
3. Define un título para la operación
4. Toca **Create**

### Escanear Objetos

1. Toca una operación activa
2. Apunta al código QR de cada objeto
3. Cada escaneo agrega el objeto a la operación
4. Verás el contador subir

### Devolver Objetos (Check-in)

1. En una operación activa, toca **Check-in**
2. Escanea los objetos que regresan
3. Los objetos vuelven a su estado anterior

### Completar Operación

1. En una operación activa, toca el menú (tres puntos)
2. Toca **Mark as complete**
3. Confirma; objetos no devueltos se marcarán como **MISSING**

### Cancelar Operación

1. Toca el menú (tres puntos)
2. Toca **Cancel operation**
3. Confirma para cancelar

### Consejos

- Si cierras la app durante una operación, puedes continuar después desde **Draft in progress**
- Los objetos en préstamo muestran estado **Loaned**
- Solo Owners y Managers pueden crear operaciones

---

## 8. Mantenimiento

Programa y rastrea el mantenimiento de tus objetos valiosos.

### Cómo Usar

### Ver Mantenimiento

1. Desde el Dashboard, toca **Maintenance**
2. Verás 4 pestañas:
   - **Overdue** — tareas atrasadas
   - **This Week** — tareas de esta semana
   - **Upcoming** — tareas futuras
   - **Completed** — tareas terminadas

### Agregar Mantenimiento

Desde el detalle de un objeto:

1. Ve al objeto
2. Desliza hasta **Maintenance**
3. Toca **Add maintenance**
4. Define: título, fecha, recurrencia (opcional)
5. Toca **Save**

### Completar Mantenimiento

1. En la lista de mantenimiento, toca el objeto
2. Toca el botón **Complete**
3. Se marca como completado

### Ver Detalles

1. Toca cualquier tarea
2. Verás: título, fecha, recurrencia, estado
3. AI sugiere tareas con porcentaje de riesgo

### Consejos

- Las tareas atrasadas aparecen en rojo
- Las tareas de esta semana aparecen en dorado
- Activa la recurrencia para tareas repetitivas (ej: limpieza anual de joyería)
- AI puede sugerir mantenimiento basado en el tipo de objeto

---

## 9. Seguros

Gestiona tus pólizas de seguro y protege tus objetos valiosos.

### Cómo Usar

### Ver Pólizas

1. Desde la barra inferior, toca el icono de escudo
2. Lista todas tus pólizas de seguro
3. Cada tarjeta muestra: proveedor, número, cobertura, expiry, objetos asegurados

### Agregar una Póliza

1. Toca el botón + arriba
2. Ingresa: proveedor, número de póliza, tipo de cobertura
3. Define: monto de cobertura, prima, fecha de inicio y expiración
4. Toca **Save**

### Ver Detalles de Póliza

1. Toca cualquier póliza
2. Verás: monto total, prima, fechas, objetos asegurados
3. Desde aquí puedes editar o agregar objetos

### Agregar Objetos Asegurados

1. En la póliza, toca el botón + en **Insured Items**
2. Busca y selecciona objetos
3. Toca **Attach**

### Análisis de Gaps (pro beta)

1. En una póliza, toca **Gap Analysis**
2. AI analiza qué objetos no están asegurados
3. Ves brechas en tu cobertura

### Eliminar Póliza

1. En los detalles, toca el icono de papelera
2. Confirma para eliminar

### Consejos

- Las pólizas próximas a expirar aparecen en rojo
- El monto de cobertura es lo que paga el seguro en caso de pérdida total
- Asegura objetos de alto valor primero
- Un gap mayor que 0 significa que el objeto excede la cobertura de la póliza
- **Fully Uninsured** = objeto no está en ninguna póliza

---

## 10. Guardarropa

Gestiona tu ropa, calzado, accesorios y joyería. Organiza tu wardrobe con filtros y estados de limpieza.

### Cómo Usar

### Ver tu Wardrobe

1. Desde la barra inferior, toca el icono de closet
2. Verás tus objetos de categoría Wardrobe en una grilla
3. Cada tarjeta muestra: foto, nombre, tipo, estado de limpieza

### Filtrar por Tipo

1. Toca: All, Clothing, Footwear, Accessories, Jewelry and Watches

### Filtrar por Limpieza

1. Toca: All, Clean, Needs Cleaning, At Dry Cleaner

### Filtrar por Temporada

1. Toca: All Seasons, Spring/Summer, Fall/Winter, All Season

### Ver Outfits

1. Toca el botón **Outfits** arriba a la derecha
2. Verás looks guardados

### Crear un Outfit

1. En Outfits, toca **Create Outfit**
2. Escribe el nombre
3. Opcional: descripción y temporada
4. Selecciona las prendas de tu wardrobe
5. Toca **Create outfit**

### Actualizar Estado de Limpieza

1. Toca el punto de color en una tarjeta
2. Selecciona: Clean, Needs Cleaning, At Dry Cleaner
3. Se actualiza automáticamente

### Consejos

- Las estadísticas arriba muestran: total, necesita limpieza, en limpieza, outfits
- Toca cualquier objeto para ver sus detalles
- El estado de limpieza ayuda a saber qué mandar a la tintorería

---

## 11. Escaneo con IA

Usa inteligencia artificial para agregar objetos rápido. Toma fotos del objeto y del recibo, y AI extrae la información automáticamente.

### Cómo Usar

### Iniciar Escaneo

1. Desde una propiedad, toca el botón flotante morado
2. Selecciona **AI Scan**
3. O desde el Dashboard, ve a AI Scan

### Paso 1: Foto del Objeto

1. Apunta al objeto y toca el botón de cámara
2. O toca el icono de galería para seleccionar
3. AI identifica el objeto

### Paso 2: Foto del Recibo (Opcional)

1. Toca para capturar el recibo
2. O selecciona de galería
3. O toca **Skip** para omitir

### AI Analiza

1. Verás **Analyzing...**
2. AI extrae: nombre, categoría, valor, serie

### Revisar y Guardar

1. Revisa la información extraída
2. Edita lo que necesites
3. Selecciona la ubicación (piso/habitación)
4. Toca **Save** para agregar

### Consejos

- El recibo es opcional pero ayuda a obtener valor exacto
- AI sugiere categoría y subcategoría
- Revisa siempre la información antes de guardar

---

## 12. Asistente IA

Chat con inteligencia artificial para preguntas sobre tu inventario. Pregunta en lenguaje natural y obtén respuestas útiles.

### Cómo Usar

### Iniciar Conversación

1. Desde el Dashboard, toca **AI Assistant**
2. O desde cualquier lugar, busca el acceso directo

### Hacer Preguntas

Escribe en el campo de abajo y toca enviar. Ejemplos:

- ¿Dónde está mi Rolex?
- ¿Qué objetos tengo en préstamo?
- Lista todos los objetos de valor mayor a $10,000
- Muéveme mis muebles de la sala
- ¿Qué joyería tengo más valiosa?

### Ver Sugerencias

En el estado inicial, verás preguntas sugeridas. Toca cualquiera para enviarlas automáticamente.

### Limpiar Conversación

1. Toca el icono de papelera arriba
2. Confirma para borrar el historial

### Consejos

- Sé específico para mejores resultados
- Puedes pedir acciones (muéveme, lista, etc.)
- Las respuestas incluyen enlaces a los objetos
- Los valores solo los ven Owners y Auditors

---

## 13. Equipo / Usuarios

Gestiona los miembros de tu familia o equipo. Invita nuevos usuarios y asigna roles.

### Cómo Usar

### Ver Miembros

1. Ve a Settings > Team members
2. O desde el Dashboard, toca tu avatar > Team
3. Lista todos los miembros con su rol y estado

### Roles Disponibles

- **Owner** — acceso completo, puede invitar
- **Manager** — puede gestionar propiedades e invitar
- **Staff** — puede agregar y editar objetos
- **Auditor** — solo puede ver valores y reportes
- **Guest** — acceso limitado

### Invitar a Alguien

1. Toca el botón + de invite
2. Escribe el email de la persona
3. Selecciona el rol
4. Toca **Send invitation**
5. La persona recibirá un email con el enlace

### Ver Detalles de Miembro

1. Toca cualquier miembro
2. Verás: email, rol, estado, último acceso
3. Solo Owners y Managers pueden ver detalles

### Cambiar Rol

Desde User Detail (solo Owners):

1. Toca el rol actual
2. Selecciona el nuevo rol
3. Confirma

### Consejos

- Solo Owners pueden invitar y cambiar roles
- Los miembros pendientes mostrarán **Pending**
- El círculo verde indica usuario conectado ahora

---

## 14. Configuración

Ajustes de la app: equipo, apariencia y cuenta.

### Cómo Usar

### Acceder a Settings

1. Desde el Dashboard, toca tu avatar
2. Toca **Settings**

### Gestionar Equipo

(Solo Owners/Managers)

1. Toca **Team members**
2. Invita o gestiona miembros

### Cambiar Apariencia

1. Toca Appearance
2. Elige:
   - **Light** — tema claro
   - **Dark** — tema oscuro
   - **System** — sigue la configuración del teléfono

### Cerrar Sesión

1. Toca **Sign out** abajo
2. Confirma en el diálogo
3. Volverás a la pantalla de login

### Consejos

- El tema oscuro es recomendado para usarlo de noche
- Al cerrar sesión, tus datos quedan seguros en el dispositivo
- Necesitas conexión a internet para iniciar sesión de nuevo

---

## Ayuda Adicional

- ¿Olvidaste tu contraseña? Contacta al administrador
- ¿Problemas técnicos? support@vaulted.app
- ¿Necesitas más funciones? Contáctanos para el plan pro

---

*Vaulted — Everything you own. Protected.*