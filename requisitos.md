# Corrección: RF, RFN e Historias de Usuarios

**Ignorar los nombres de responsables**  

---

# Requisitos funcionales

| N° | Requisito | Responsable | Corrección |
|---|---|---|---|
| RF1 | El sistema permitirá registrar clientes incluyendo obligatoriamente: Nombre/Razón Social, RUT, teléfono móvil (9 dígitos), correo electrónico y dirección de facturación. | Patricio Jaramillo | Se definieron los campos exactos de "contacto" (teléfono de 9 dígitos y correo) para que el programador sepa qué validar. |
| RF2 | El sistema permitirá ingresar solicitudes de despacho detallando peso (en kilogramos), dimensiones (alto, largo, ancho en centímetros) y tipo de carga (Paquetería, Construcción o Eventos). | Patricio Jaramillo | Se agregaron unidades de medida (kg, cm) y rangos para que los datos sean coherentes y no metan cualquier número. |
| RF3 | El sistema permitirá asignar una "Ventana Horaria" (bloque de 2 o 3 horas) obligatoria a cada solicitud de despacho, la cual será visible en el formulario de ingreso de pedidos. | Patricio Jaramillo | Se definió la ventana como "bloques de 2 o 3 horas" para estandarizar la agenda. |
| RF4 | El sistema permitirá asociar un pedido a una camioneta y a un conductor cuyo estado sea "Activo", "En horario laboral" y con "Licencia de conducir vigente". | Patricio Jaramillo | Se aclaró que "disponible" significa tener licencia vigente y estar en horario laboral, evitando errores legales. |
| RF5.1 | El sistema permitirá anular pedidos siempre que no hayan sido despachados a la ruta del conductor. | Patricio Jaramillo | Se separó "Anular" de "Editar", ya que son acciones con permisos y momentos distintos. |
| RF5.2 | El sistema permitirá editar los campos de contacto y dirección de un pedido antes de que este cambie al estado "En ruta". | Patricio Jaramillo | - |
| RF6 | El sistema ordenará la lista de tareas del conductor usando la hora de inicio de la ventana horaria. Ante igual ventana horaria, el sistema priorizará por el orden de registro (FIFO). | Benjamín Miranda | Se añadió una regla de desempate (FIFO) para el algoritmo; ejemplo, si dos entregas son a la misma hora, el sistema ya sabe cuál va primero. |
| RF7 | La aplicación móvil mostrará al conductor su "Hoja de Ruta Digital" diaria, listando exclusivamente las paradas programadas para la jornada actual en orden cronológico. | Benjamín Miranda | Se especificó que la hoja de ruta es diaria, para no saturar la App del conductor con entregas de toda la semana. |
| RF8 | El sistema permitirá al conductor cambiar el estado del pedido exclusivamente a: "En camino", "Entregado" o "Incidencia". | Benjamín Miranda | Sin corrección. |
| RF9 | Al marcar un pedido como "Entregado", la aplicación habilitará obligatoriamente la captura de una firma digital táctil o una fotografía del producto entregado. | Benjamín Miranda | Sin corrección. |
| RF10.1 | El sistema permitirá al conductor registrar un motivo de fallo seleccionando de una lista predefinida (ej: Cliente ausente, Dirección incorrecta). | Benjamín Miranda | Se dividió el "motivo" de la "foto" en dos requerimientos; así, si falla la cámara, pero el texto se guarda, el sistema no colapsa. |
| RF10.2 | En caso de entrega fallida, el sistema exigirá la captura de al menos una fotografía como evidencia del incidente. | Benjamín Miranda | - |
| RF11.1 | El sistema permitirá crear y editar cuentas de usuario con: nombre completo, correo institucional, contraseña (mín. 8 caracteres) y rol (Admin, Staff, Conductor). | Luis Bustamante | Se separó la creación de cuentas de su edición y desactivación para mejorar la gestión de perfiles. |
| RF11.2 | El sistema permitirá desactivar (eliminar de forma lógica) cuentas de usuario para impedir su acceso sin borrar el historial de sus gestiones pasadas. | Luis Bustamante | - |
| RF12 | El sistema generará automáticamente un reporte consolidado en formato PDF cada día a las 20:00 hrs, enviado al correo del Administrador, detallando despachos realizados y pendientes. | Luis Bustamante | Se fijó un horario (20:00 hrs) y un destinatario para que el reporte sea realmente automático y útil. |
| RF13 | El sistema calculará el "Indicador de Puntualidad" restando la hora real de entrega al cierre de la ventana programada. Un resultado positivo se considerará "Atrasado". | Luis Bustamante | Se estableció la fórmula matemática exacta para medir la puntualidad. |
| RF14.1 | El sistema permitirá exportar el historial de servicios de un cliente en formato PDF, filtrado opcionalmente por un rango de fechas. | Luis Bustamante | Se dividieron los formatos PDF y Excel, para no mezclar formatos. |
| RF14.2 | El sistema permitirá exportar el historial de servicios de un cliente en formato Excel, incluyendo campos de RUT, fecha, peso, tipo de carga y estado final. | Luis Bustamante | - |
| RF15 | El sistema mostrará un Dashboard con el estado de disponibilidad, ubicación de la última parada y carga actual de todas las camionetas registradas en la flota. | Luis Bustamante | Se eliminó la mención a "5 camionetas" para que el Dashboard sirva aunque la empresa crezca a 50 o 100 vehículos. |

---

# Requisitos no funcionales

| N° | Requisito no funcional | Responsable | Corrección |
|---|---|---|---|
| RNF1 | El 90% de los usuarios administrativos nuevos deberá registrar un pedido completo en menos de 30 minutos, sin asistencia externa, tras una inducción de 15 minutos. | Patricio Jaramillo | Métrica de Usabilidad: Se cambia "intuitivo" por una prueba de éxito con tiempo y porcentaje de usuarios. |
| RNF2 | El sistema debe ser compatible y funcional en las últimas dos versiones estables de Google Chrome, Mozilla Firefox y Microsoft Edge. | Patricio Jaramillo | Sin corrección. |
| RNF3 | La interfaz debe aplicar la paleta de colores (Azul #003366, Naranja #FF6600) y tipografías definidas en el Manual de Marca v1.0 de Qúbico Transportes. | Patricio Jaramillo | Se define referencia directa al manual de identidad visual. |
| RNF4 | Los mensajes de error deben indicar el campo fallido y la regla incumplida (ej: "RUT inválido: falta dígito verificador") en lenguaje no técnico. | Patricio Jaramillo | Se elimina el concepto de "claro" por una instrucción de diseño: indicar campo y regla de validación. |
| RNF5 | El sistema debe cargar un listado de hasta 500 pedidos diarios en menos de 2 segundos bajo una conexión 4G estable (10 Mbps de bajada). | Patricio Jaramillo | Se define el volumen de datos (500 registros) y el tipo de conexión para que la prueba sea justa. |
| RNF6 | La aplicación móvil debe garantizar una disponibilidad del 99.9% (máximo 43 min de caída al mes) durante el horario de 08:00 a 20:00 hrs. | Benjamín Miranda | A pesar de no tener corrección: Se transforma el porcentaje en tiempo real de caída permitida para facilitar el monitoreo. |
| RNF7 | El modo "Offline" debe permitir guardar hasta 50 reportes de entrega localmente y sincronizarlos automáticamente al detectar señal de internet. | Benjamín Miranda | Se especifica la cantidad de datos que el teléfono debe ser capaz de retener sin conexión. |
| RNF8 | Los elementos accionables (botones) en la App deben tener un tamaño mínimo de 44x44 píxeles y un contraste de color de al menos 4.5:1. | Benjamín Miranda | Se reemplazan palabras vagas como "grande" y "alto contraste" por medidas técnicas de diseño móvil. |
| RNF9 | El sistema debe comprimir las imágenes de evidencia a un peso máximo de 500 KB por archivo antes de iniciar la subida al servidor. | Benjamín Miranda | Se define el límite de peso exacto para cumplir con la eficiencia de datos solicitada. |
| RNF10 | El sistema debe registrar un archivo Log diario que capture errores de servidor (500) y de red, permitiendo su descarga en formato `.txt`. | Benjamín Miranda | Se especifica qué debe capturar el log y cómo se debe acceder a él para el equipo técnico. |
| RNF11 | El acceso requiere autenticación con contraseña de 8 caracteres, incluyendo al menos una mayúscula y un número. | Luis Bustamante | Se definieron los parámetros de complejidad de la contraseña para evitar accesos débiles. |
| RNF12 | Los datos de RUT y teléfonos deben encriptarse mediante el estándar AES-256 tanto en reposo (BD) como en tránsito (HTTPS). | Luis Bustamante | Sin corrección. |
| RNF13 | El algoritmo de prioridad debe procesar el ordenamiento de 1.000 pedidos en menos de 500ms sin aumentar el consumo de CPU sobre el 20%. | Luis Bustamante | Se definieron límites de procesamiento para asegurar que el sistema no se ralentice al crecer la flota. |
| RNF14 | El administrador podrá ejecutar un respaldo completo de la base de datos en formato `.SQL` de manera manual desde el panel de control. | Luis Bustamante | Se aclara el formato y el método de ejecución del backup para evitar ambigüedades en la operación. |
| RNF15 | El registro de auditoría debe incluir: ID de usuario, acción realizada, fecha, hora y valor anterior/nuevo del dato modificado. | Luis Bustamante | Sin corrección. |

---

# Historias de usuario

| N° | Historia de Usuario (Como / Quiero / Para) | Responsable | Corrección |
|---|---|---|---|
| HU01 | Como Encargado de CS, quiero registrar un despacho con una ventana horaria obligatoria, para que el sistema pueda organizar la prioridad cronológica de las entregas. | Patricio Jaramillo | Sin corrección. |
| HU02.1 | Como Encargado de CS, quiero seleccionar un conductor de una lista de personal disponible para asignarlo a un pedido, para asegurar que cada carga tenga un responsable. | Patricio Jaramillo | Se separó la asignación administrativa de la sincronización técnica con el móvil para que sea testeable por separado. |
| HU02.2 | Como Conductor, quiero recibir una actualización en mi App al ser asignado a un nuevo pedido, para visualizar los datos del cliente de forma inmediata (en < 10 segundos). | Benjamín Miranda | Se define qué significa "automáticamente" mediante un tiempo de respuesta medible (10 seg). |
| HU03 | Como Conductor, quiero visualizar mi hoja de ruta ordenada por hora en la App, para conocer mi próximo destino sin depender de instrucciones por radio. | Benjamín Miranda | Sin corrección. |
| HU04 | Como Conductor, quiero registrar la entrega de un pedido con una firma digital o foto, para contar con una evidencia de recepción válida en tiempo real. | Benjamín Miranda | Sin corrección. |
| HU05.1 | Como Administrador, quiero crear y editar perfiles de usuario, para mantener actualizada la nómina de trabajadores que acceden al sistema. | Luis Bustamante | Se dividió la gestión de usuarios para que sea "Pequeña" (Small) y fácil de estimar en puntos de historia. |
| HU05.2 | Como Administrador, quiero asignar roles específicos (Admin, Staff, Conductor) a las cuentas, para restringir el acceso a funciones sensibles según el cargo. | Luis Bustamante | Al separarla de la creación de cuentas, se puede estimar con mayor precisión el esfuerzo de la lógica de permisos. |
| HU06 | Como Administrador, quiero generar un reporte diario que resalte en rojo las entregas con más de 15 minutos de atraso, para evaluar el cumplimiento de las ventanas horarias. | Luis Bustamante | Se añaden fórmulas y umbrales (15 min) para que QA pueda verificar si el reporte marca correctamente los retrasos. |