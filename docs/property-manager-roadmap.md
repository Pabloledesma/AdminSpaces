# Property Manager — Hitos e Historias de Usuario

Marca cada historia cuando la completes. El orden importa: cada hito construye sobre el anterior.

---

## ✅ Hito 0 — Modelo de datos (completado)

- [x] 5 objetos custom creados con sus campos y relaciones
- [x] Diagrama entidad-relación

---

## Hito 1 — Seguridad y modelo de permisos

> Antes de escribir una sola línea de Apex, necesitas decidir quién puede ver/editar qué. Esto evita rehacer trabajo después.

- [ ] **Historia 1.1:** Como administrador de la plataforma, quiero un Permission Set "Property Manager" que dé acceso completo (CRUD) a los 5 objetos custom, para que solo usuarios autorizados gestionen la operación completa.
- [ ] **Historia 1.2:** Como encargado de limpieza/mantenimiento, quiero un Permission Set separado que solo me dé acceso a `Maintenance_Task__c` (sin ver reservas ni gastos), para respetar el principio de menor privilegio.
- [ ] **Historia 1.3:** Como visitante no autenticado del futuro sitio Experience, quiero ver únicamente los registros marcados como `Is_Demo__c = true`, para que el portafolio sea público sin exponer datos reales del hogar.

---

## Hito 2 — Lógica de negocio en Apex

> Aquí vive el trigger que ya discutimos, más varias piezas asíncronas para practicar distintos patrones de Apex.

- [X] **Historia 2.1:** Como administrador de la propiedad, quiero que el sistema impida crear una reserva si las fechas se solapan con otra reserva existente para la misma habitación, para evitar overbooking. *(la que ya empezamos)*
- [X] **Historia 2.2:** Como administrador, quiero que el campo `Total_Amount__c` de una reserva se calcule automáticamente al crearla o modificarla, para no depender de cálculo manual.
- [ ] **Historia 2.3:** Como administrador, quiero que las habitaciones cambien automáticamente a estado "Available" el día del checkout, para no tener que actualizarlas a mano.
- [ ] **Historia 2.4:** Como administrador, quiero que se cree automáticamente una tarea de limpieza (`Maintenance_Task__c`) la noche antes de cada checkout, para no olvidar coordinar al personal.
- [ ] **Historia 2.5:** Como huésped, quiero recibir una notificación (o que se procese algo en segundo plano) cuando mi reserva se confirma, para practicar Queueable Apex.

---

## Hito 3 — Componentes LWC

> Cada historia aquí debería consumir algo de Apex ya construido en el Hito 2.

- [ ] **Historia 3.1:** Como administrador, quiero un dashboard que muestre ocupación actual, ingresos del mes y tareas pendientes de una propiedad, para tener visibilidad rápida.
- [ ] **Historia 3.2:** Como administrador, quiero seleccionar una habitación y un rango de fechas y que el sistema me confirme si está disponible antes de crear la reserva, para practicar llamada Apex imperativa.
- [ ] **Historia 3.3:** Como administrador, quiero un formulario para crear una nueva reserva con validación en tiempo real, para agilizar el proceso de check-in.
- [ ] **Historia 3.4:** Como encargado de mantenimiento, quiero un tablero tipo kanban de `Maintenance_Task__c` donde pueda mover tareas entre estados, para gestionar mi trabajo visualmente.
- [ ] **Historia 3.5:** Como administrador, quiero un gráfico de gastos agrupados por categoría, para entender en qué se está invirtiendo el dinero de la renovación.

---

## Hito 4 — Testing

> No es opcional para un portafolio serio — es lo primero que un revisor técnico va a mirar en tu repo.

- [ ] **Historia 4.1:** Como desarrollador, quiero una test class para el trigger de reservas que cubra casos positivos, negativos (conflicto de fechas) y de volumen (bulk, 200 registros), para asegurar cobertura real.
- [ ] **Historia 4.2:** Como desarrollador, quiero tests Jest para al menos dos de mis componentes LWC, para validar wire adapters y manejo de eventos sin desplegar a la org.

---

## Hito 5 — Sitio Experience Cloud

- [ ] **Historia 5.1:** Como visitante, quiero acceder a un sitio público (LWR) donde pueda ver el proyecto en funcionamiento, para evaluar las habilidades del desarrollador.
- [ ] **Historia 5.2:** Como administrador de seguridad, quiero configurar OWD y Sharing Rules para que el Guest User solo vea registros demo, aplicando el principio de menor privilegio.
- [ ] **Historia 5.3:** Como visitante, quiero interactuar con los componentes LWC del Hito 3 dentro del sitio público, para ver la app real, no solo capturas de pantalla.

---

## Hito 6 — Agentforce

- [ ] **Historia 6.1:** Como huésped potencial, quiero poder preguntarle a un agente si una habitación está disponible en ciertas fechas, para no tener que navegar la interfaz manualmente.
- [ ] **Historia 6.2:** Como encargado de mantenimiento, quiero poder reportarle un problema a un agente en lenguaje natural y que este cree automáticamente el `Maintenance_Task__c` correspondiente, para agilizar el reporte de incidencias.

---

## Notas de seguimiento

*(usa este espacio para anotar decisiones importantes que tomes durante la implementación, útil para cuando armes el case study del portafolio)*

-
