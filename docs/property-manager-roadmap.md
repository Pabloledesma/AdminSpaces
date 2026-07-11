# Property Manager — Hitos e Historias de Usuario

Marca cada historia cuando la completes. El orden importa: cada hito construye sobre el anterior.

---

## ✅ Hito 0 — Modelo de datos (completado)

- [x] 5 objetos custom creados con sus campos y relaciones
- [x] Diagrama entidad-relación

---

## Hito 1 — Seguridad y modelo de permisos

> Antes de escribir una sola línea de Apex, necesitas decidir quién puede ver/editar qué. Esto evita rehacer trabajo después.

- [X] **Historia 1.1:** Como administrador de la plataforma, quiero un Permission Set "Property Manager" que dé acceso completo (CRUD) a los 5 objetos custom, para que solo usuarios autorizados gestionen la operación completa.
- [X] **Historia 1.2:** Como encargado de limpieza/mantenimiento, quiero un Permission Set separado que solo me dé acceso a `Maintenance_Task__c` (sin ver reservas ni gastos), para respetar el principio de menor privilegio.

*(La historia de seguridad para el Guest User no autenticado se movió al Hito 3, junto con la creación del sitio Experience Cloud del que depende — ver Historia 3.2.)*

---

## Hito 2 — Lógica de negocio en Apex y Flow

> Aquí vive el trigger que ya discutimos, más varias piezas asíncronas para practicar distintos patrones de Apex.

- [X] **Historia 2.1:** Como administrador de la propiedad, quiero que el sistema impida crear una reserva si las fechas se solapan con otra reserva existente para la misma habitación, para evitar overbooking. *(la que ya empezamos)*
- [X] **Historia 2.2:** Como administrador, quiero que el campo `Total_Amount__c` de una reserva se calcule automáticamente al crearla o modificarla, para no depender de cálculo manual.
- [X] **Historia 2.3:** Como administrador, quiero que las habitaciones cambien automáticamente a estado "Available" el día del checkout, para no tener que actualizarlas a mano. *(incluye también la extensión automática de una noche por no-show; ver notas de seguimiento)*
- [X] **Historia 2.4:** Como administrador, quiero que se cree automáticamente una tarea de limpieza (`Maintenance_Task__c`) la noche antes de cada checkout, para no olvidar coordinar al personal. *(resuelta con Flow, no Apex; ver notas de seguimiento)*
- [ ] **Historia 2.6 (backlog, sin priorizar):** Como administrador, quiero que cuando un no-show entre en conflicto real con la reserva del siguiente huésped, el sistema deje registrado el conflicto (tarea/notificación) para resolución manual, y contemplar descuento al huésped afectado + posible penalidad al que no confirmó el checkout a tiempo.

---

## Hito 3 — Sitio Experience Cloud

> Se adelanta antes que los componentes LWC a propósito: teniendo el sitio ya armado, cada componente del Hito 4 se puede probar en vivo apenas se construye, en vez de integrar todo recién al final.

- [ ] **Historia 3.1:** Como visitante, quiero acceder a un sitio público (LWR) donde pueda ver el proyecto en funcionamiento, para evaluar las habilidades del desarrollador.
- [ ] **Historia 3.2 (antes Historia 1.3 / 5.2):** Como visitante no autenticado del sitio Experience, quiero ver únicamente los registros marcados como `Is_Demo__c = true`, para que el portafolio sea público sin exponer datos reales del hogar — configurando OWD y Sharing Rules por criterio para el Guest User, aplicando el principio de menor privilegio.

---

## Hito 4 — Portal de autoservicio del huésped (Experience Cloud autenticado)

> Distinto de la Historia 3.2: ahí el Guest User anónimo veía solo demo data vía Sharing Rules por criterio, igual para todos los visitantes. Acá el huésped se loguea con una licencia Customer Community ligada a su `Contact`, y el modelo de seguridad cambia de raíz: cada huésped autenticado debe ver **únicamente sus propios registros**, no los de otros huéspedes — no alcanza con una Sharing Rule genérica, hace falta sharing a nivel de registro individual (ownership/criteria por `Guest__c = $User.ContactId` o similar). No confundir con el personal de limpieza, que ya tiene resuelto su acceso como usuario interno vía el Permission Set `Maintenance_Staff` de la Historia 1.2 — no necesita loguearse en este sitio.

- [ ] **Historia 4.1:** Como huésped, quiero poder registrarme e iniciar sesión en el sitio, para hacer seguimiento de mi reserva sin depender de que el administrador me la comunique manualmente.
- [ ] **Historia 4.2:** Como huésped autenticado, quiero ver el detalle de mi propia reserva (habitación, fechas, monto total, estado), para no tener que llamar a la propiedad para consultarlo.
- [ ] **Historia 4.3:** Como huésped autenticado, quiero poder modificar las fechas de mi reserva (respetando la misma regla de no solapamiento de la Historia 2.1), para ajustar mi estadía sin intervención manual.
- [ ] **Historia 4.4:** Como huésped autenticado, quiero poder cancelar mi reserva, para liberar la habitación si cambian mis planes.
- [ ] **Historia 4.5 (seguridad crítica):** Como administrador de seguridad, quiero configurar el sharing para que un huésped autenticado solo pueda ver/editar sus propias reservas y no las de otros huéspedes, aplicando el principio de menor privilegio también entre usuarios externos autenticados (no solo entre Guest User y usuario interno).

---

## Hito 5 — Componentes LWC

> Cada historia aquí debería consumir algo de Apex ya construido en el Hito 2. Como el sitio del Hito 3 ya existe, cada componente se despliega y se prueba ahí en vivo apenas está listo — no se espera a tener todos los componentes para integrar. Por la misma razón de TDD que ya veníamos aplicando en Apex, **cada historia incluye sus propios tests Jest como parte de su criterio de aceptación**, no como fase separada al final.

- [ ] **Historia 5.1:** Como administrador, quiero un dashboard que muestre ocupación actual, ingresos del mes y tareas pendientes de una propiedad, para tener visibilidad rápida.
- [ ] **Historia 5.2:** Como administrador, quiero seleccionar una habitación y un rango de fechas y que el sistema me confirme si está disponible antes de crear la reserva, para practicar llamada Apex imperativa.
- [ ] **Historia 5.3:** Como administrador, quiero un formulario para crear una nueva reserva con validación en tiempo real, para agilizar el proceso de check-in.
- [ ] **Historia 5.4:** Como encargado de mantenimiento, quiero un tablero tipo kanban de `Maintenance_Task__c` donde pueda mover tareas entre estados, para gestionar mi trabajo visualmente.
- [ ] **Historia 5.5:** Como administrador, quiero un gráfico de gastos agrupados por categoría, para entender en qué se está invirtiendo el dinero de la renovación.

---

## Hito 6 — Agentforce

- [ ] **Historia 6.1:** Como huésped potencial, quiero poder preguntarle a un agente si una habitación está disponible en ciertas fechas, para no tener que navegar la interfaz manualmente.
- [ ] **Historia 6.2:** Como encargado de mantenimiento, quiero poder reportarle un problema a un agente en lenguaje natural y que este cree automáticamente el `Maintenance_Task__c` correspondiente, para agilizar el reporte de incidencias.

---

## Notas de seguimiento

*(usa este espacio para anotar decisiones importantes que tomes durante la implementación, útil para cuando armes el case study del portafolio)*

- **Hito 4 nuevo — Portal de autoservicio del huésped (2026-07-11):** al configurar el Guest User de la Historia 3.2, surgió la pregunta de si hacía falta login para huéspedes y personal de limpieza. Conclusión: notificar al huésped (`Guest__c` ya apunta a un `Contact` con email) y asignar tareas al personal (usuario interno con `Maintenance_Staff`) **no** requieren login en el sitio — ya estaban resueltos. Lo que sí es una feature real y nueva es que el huésped se loguee para autogestionar su propia reserva (ambición tipo "Airbnb"); se agrega como Hito 4 propio en vez de colarlo dentro de la 3.2, porque el modelo de seguridad es distinto (sharing por registro individual entre usuarios externos autenticados, no una Sharing Rule genérica para todo Guest User).
- **Reorganización de hitos (2026-07-11):** el Hito 5 (Sitio Experience Cloud) pasó a ser el Hito 3, y el antiguo Hito 3 (LWC) pasó a ser el Hito 4 — razón: con el sitio ya armado, cada componente LWC se prueba en vivo apenas se construye, en vez de integrar todo al final. Se eliminó el Hito de Testing como fase separada: la Historia 4.1 original (tests Apex del trigger) ya estaba cumplida retroactivamente por el TDD del Hito 2; la 4.2 (Jest para LWC) se folded como criterio de aceptación de cada historia del nuevo Hito 4, no como fase aparte. La antigua Historia 5.3 ("interactuar con los LWC del Hito 3 dentro del sitio") se disolvió en esa misma expectativa por-historia del Hito 4. La Historia 1.3 y la 5.2 originales eran duplicadas (mismo objetivo de Guest User) — se fusionaron en la Historia 3.2.
- **Regla de solapamiento (Historia 2.1):** dos reservas de la misma habitación se solapan si `nueva.CheckIn < existente.CheckOut AND existente.CheckIn < nueva.CheckOut` (comparación estricta). Esto implica que el mismo día puede ser checkout de una reserva y checkin de otra sin considerarse solapamiento (regla común en hotelería). Solo bloquean reservas en estado `Pending`, `Confirmed` o `Checked In`; `Cancelled` nunca bloquea.
- **Arquitectura del trigger de `Reservation__c`:** `ReservationTriggerHandler` solo orquesta; el SOQL vive en `ReservationSelector`/`RoomSelector` (DIP), la regla de solapamiento en `ReservationOverlapValidator` (SRP/OCP) y el cálculo de precio en `ReservationPricingCalculator` (SRP) — reutilizados tanto en `OnBeforeInsert` como en `OnBeforeUpdate`.
- **Historia 2.3 — no-show:** si una reserva no se marca `Checked Out` el día de su checkout, `RoomCheckoutScheduler` extiende `Check_Out_Date__c` un día (lo que dispara el recálculo automático de `Total_Amount__c` vía el trigger existente, cobrando la noche extra). **Pendiente (Historia 2.6):** qué pasa cuando esa extensión choca de verdad con la reserva del siguiente huésped — hoy el `update` de esa reserva puntual simplemente falla (el resto del batch sigue con `Database.update(..., false)`) sin dejar rastro para que el personal lo resuelva. Ahí también entra la idea de ofrecer un descuento al huésped desplazado y/o cobrar una penalidad al que no confirmó el checkout a tiempo.
- **OWD:** `Property__c` y `Maintenance_Task__c` en `Private`; `Room__c`, `Reservation__c` y `Expense__c` en `ControlledByParent` (heredan de su relación Master-Detail).
- **Historia 2.4 — por qué Flow y no Apex:** es una automatización "N días antes de una fecha en este registro", que Salesforce resuelve nativamente con un **Record-Triggered Flow + Scheduled Path** (1 día antes de `Check_Out_Date__c`) sin necesidad de un Schedulable/batch propio. Se decidió no reimplementar en Flow la validación de solapamiento ni el cálculo de precio (Historias 2.1/2.2): un Flow *before-save* no tiene visibilidad de otros registros del mismo batch de inserción, así que mover esa lógica a Flow hubiera reabierto el bug de solapamiento-en-batch que ya arreglamos en Apex.
- **`ReservationFlow`:** Start con `recordTriggerType=CreateAndUpdate` (necesario para que el Scheduled Path se recalcule si `Check_Out_Date__c` cambia, como en la extensión por no-show de la Historia 2.3) y filtro de fechas no nulas. Falta agregar un filtro por `Status__c` para excluir reservas `Cancelled` (no debería programarse limpieza para una reserva que nunca va a ocurrir) — pendiente.
- **Historia 2.5 retirada (Queueable Apex):** existía solo para "practicar Queueable Apex", pero forzar un patrón async para algo tan simple como enviar una notificación (resoluble con un Email Alert/Custom Notification de Flow) es sobre-ingeniería sin justificación real. Se retira del Hito 2; la práctica de Queueable/Batch Apex se retoma más adelante cuando surja un caso de uso genuino (ej. un callout externo o un proceso pesado en los Hitos 4 o 5), no por completar un checklist.
- **Testing de `ReservationFlow`:** se intentó un Flow Test formal (`.flowtest-meta.xml`, data silo aislado vía `ReservationFlowTestSetup`) pero el picker de "Apex Test Setup" en Flow Builder no reconocía la clase por un bug/limitación de esta feature (muy nueva, Winter '26) — no se resolvió ni cambiando la clase a `public` ni con refresh. Además `Reservation__c` tenía `enableSearch=false`, lo que impedía que CUALQUIER lookup (incluido el de "Set Initial Triggering Record") encontrara sus registros — ya corregido (`enableSearch=true`). De paso se corrigió `Reservation__c.Name` de `Text` a `Auto Number` formato `RES-{0000}` (discrepancia arrastrada desde el Hito 0). Por ahora la validación del flow se hace con **Debug** (path "before checkout") contra datos reales creados por `scripts/apex/create-reservation-flow-test-data.apex` y `create-reservation-for-flow-test.apex`; el Flow Test formal queda pendiente (Flow Builder ofrece "Convert to Test" a partir de una corrida de Debug exitosa, que es más simple que autoría manual de metadata).
