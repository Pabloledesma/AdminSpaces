# AdminSpaces — Property Manager

Proyecto de portafolio para practicar el ciclo completo de desarrollo en Salesforce: modelo de datos, seguridad, Apex, LWC, Experience Cloud y Agentforce, construido sobre un caso de uso realista de gestión de propiedades en alquiler (habitaciones, reservas, mantenimiento y gastos).

El desarrollo está organizado en **Hitos** con **Historias de Usuario**, documentados en [`docs/property-manager-roadmap.md`](docs/property-manager-roadmap.md). Cada hito construye sobre el anterior: modelo de datos → seguridad → lógica de negocio en Apex → componentes LWC → testing → sitio Experience Cloud → Agentforce.

## Modelo de datos

5 objetos custom con relaciones Master-Detail (`Property__c → Room__c → Reservation__c`, `Property__c → Expense__c`) y Lookup (`Maintenance_Task__c`). Documentado en detalle, incluyendo el diagrama entidad-relación y el razonamiento de cada decisión de diseño, en [`docs/property-manager-data-model.md`](docs/property-manager-data-model.md).

| Objeto                | Relación                                                | Propósito                        |
| --------------------- | ------------------------------------------------------- | -------------------------------- |
| `Property__c`         | —                                                       | Propiedad/activo raíz            |
| `Room__c`             | Master-Detail → `Property__c`                           | Habitaciones de una propiedad    |
| `Reservation__c`      | Master-Detail → `Room__c`, Lookup → `Contact` (huésped) | Reservas de huéspedes            |
| `Maintenance_Task__c` | Lookup → `Property__c`, `Room__c`                       | Tareas de mantenimiento/limpieza |
| `Expense__c`          | Master-Detail → `Property__c`                           | Gastos de renovación/operación   |

Todos los objetos tienen un campo `Is_Demo__c` (default `true`), pensado para las Sharing Rules del futuro Guest User del sitio Experience Cloud: solo se expondrán públicamente los registros marcados como demo, nunca el objeto completo.

## Seguridad y permisos

- **OWD**: `Private` en los objetos raíz (`Property__c`, `Maintenance_Task__c`); `ControlledByParent` en los que cuelgan de una relación Master-Detail (`Room__c`, `Reservation__c`, `Expense__c`).
- **Permission Sets**:
  - `Property_Manager` — acceso operativo completo a los 5 objetos, para administradores de la plataforma.
  - `Maintenance_Staff` — acceso exclusivo a `Maintenance_Task__c`, aplicando el principio de menor privilegio para el personal de limpieza/mantenimiento.
  - `Huesped` — `allowEdit` sobre `Reservation__c` para el huésped autenticado (Historia 4.3). Deliberadamente un Permission Set y no un cambio al profile: más chico y portable entre orgs. La asignación a cada huésped autorregistrado es manual por ahora (ver roadmap).
- **Guest User anónimo** (Hito 3): Sharing Rule por criterio (`Is_Demo__c = true`) sobre `Property__c` para el sitio Experience Cloud.
- **Huésped autenticado** (Hito 4, Customer Community): `Reservation__c` es `ControlledByParent` hasta el `Property__c` raíz, así que ninguna Sharing Rule/Sharing Set declarativo puede aislar la reserva de un huésped sin exponer también las de otros huéspedes de la misma propiedad (ver detalle en el roadmap). Se resolvió con **Apex-managed sharing**: `ReservationSelfServiceController` corre `without sharing` y filtra explícitamente por `Guest__c = ContactId` del usuario logueado — el único control de acceso es ese filtro, no el sharing declarativo. Para la escritura (Historia 4.3), como una `update` de Apex no aplica CRUD/FLS automáticamente, se suma `Security.stripInaccessible` sobre un registro armado solo con los campos que se editan (no el resultado completo de una query de lectura, que arrastraría campos irrelevantes y bloquearía el update por permisos que no corresponden a esa operación).

## Lógica de negocio (Apex)

El trigger de `Reservation__c` implementa dos reglas de negocio con TDD (tests escritos antes que la implementación):

1. **No overbooking**: no se puede crear ni editar una reserva si sus fechas se solapan con otra reserva activa (`Pending`, `Confirmed`, `Checked In`) de la misma habitación. Las reservas `Cancelled` no bloquean.
2. **Cálculo automático de `Total_Amount__c`**: se calcula (noches × `Nightly_Rate__c` de la habitación) al crear o modificar una reserva, siempre que no haya solapamiento.

**Arquitectura**, siguiendo capas de responsabilidad única en vez de lógica concentrada en el trigger:

```
Reservation.trigger
      │
      ▼
ReservationTriggerHandler   (orquesta antes de insert/update, sin lógica de negocio propia)
      │
      ├── ReservationSelector / RoomSelector   (todo el SOQL de estos objetos vive acá — DIP)
      ├── ReservationOverlapValidator          (regla de solapamiento, reusable — SRP/OCP)
      └── ReservationPricingCalculator         (regla de cálculo de precio, reusable — SRP)
```

`TestDataFactory` centraliza la creación de datos de prueba para evitar duplicación entre tests.

**`RoomCheckoutScheduler`** (Schedulable, pensado para correr una vez al día): libera la habitación de las reservas ya marcadas `Checked Out` el día de su checkout, y extiende un día el `Check_Out_Date__c` de las que no hicieron checkout (no-show) — la noche extra se recalcula sola vía el trigger existente. El conflicto entre una extensión y la reserva del siguiente huésped queda como trabajo pendiente (ver `docs/property-manager-roadmap.md`).

**`ReservationFlow`** (Record-Triggered Flow con Scheduled Path): crea una `Maintenance_Task__c` de limpieza un día antes de cada checkout. Se resolvió con Flow en vez de Apex porque es una automatización puramente basada en fecha, sin necesidad del batch/query propio de un Schedulable — la lógica de solapamiento y precio (Historias 2.1/2.2) se mantuvo en Apex a propósito, ya que un Flow _before-save_ no puede comparar registros entre sí dentro del mismo batch de inserción.

## Componentes LWC

**`guestReservations`** (Historias 4.2, 4.3 y 4.4): componente del portal autenticado que muestra al huésped el detalle de su propia reserva (habitación, fechas, monto, estado) vía `@wire` a `getMyReservations`, le permite modificar las fechas de check-in/check-out (`updateMyReservationDates`) y cancelarla (`cancelMyReservation`, con confirmación previa) — ambas llamadas imperativas, no vía Lightning Data Service, ya que `Reservation__c` no tiene ningún camino de sharing declarativo viable para esto (ver roadmap). Maneja los estados de lectura (datos/vacío/error) y de cada mutación (deshabilitado mientras guarda/cancela, mensaje de éxito, mensaje de error, reactivación al editar de nuevo), todo cubierto por su test Jest (`__tests__/guestReservations.test.js`), sin fase de testing separada.

**`propertyDashboard`** (Historia 5.1): componente interno (no del sitio Experience Cloud) en la Lightning Record Page de `Property__c`, para el Property Manager. Usa `@api recordId` y `@wire` a `PropertyDashboardController.getDashboardData`, que calcula ocupación (`RoomSelector`, `GROUP BY Status__c`), ingresos del mes (`ReservationSelector`, `SUM()` con rango de fechas exclusivo) y tareas de mantenimiento pendientes (`MaintenanceTaskSelector`, `COUNT()`) — las tres con la consulta SOQL más barata posible para cada caso, no con listas completas de registros.

**Familia `roomAvailabilityChecker`** (Historias 5.2 y 5.3): 4 LWC en la misma Record Page de `Property__c`, comunicados por Custom Events (hijo→padre) y propiedades `@api` (padre→hijo) — `roomAvailabilityChecker` (padre, orquesta) + `roomPicker`, `dateRangePicker` y `availabilityResult` (hijos). `RoomAvailabilityController.checkAvailability` reutiliza `ReservationOverlapValidator.overlaps` (Historia 2.1) en vez de duplicar la regla de solapamiento — la llamada es imperativa a propósito (objetivo explícito de la historia), mientras que la carga de habitaciones y de fechas ya reservadas usa `@wire`. Se evaluaron en el camino y se descartaron: Platform Events (no hay caso de uso pub/sub genuino acá) y compilar los componentes en TypeScript vía `tsc` (`@api`/`@wire` no son decoradores TC39 estándar — solo `@lwc/compiler` los interpreta; `tsc` los rompe con un polyfill que el compilador de LWC no reconoce). La Historia 5.3 extendió el mismo padre en vez de armar un formulario aparte: un `lightning-record-picker` de `Contact` + botón "Crear reserva" (`ReservationCreationController.createReservation`), habilitado solo cuando ya se confirmó disponibilidad y hay huésped elegido — el enforcement real sigue siendo el trigger de la Historia 2.1, esto es solo UX. Detalle completo en el roadmap.

## Testing

```bash
sf apex run test --class-names ReservationTest --target-org <alias> --result-format human --synchronous
npm run test:unit
```

La suite de `ReservationTest` cubre casos positivos, negativos (todas las variantes de solapamiento de fechas), edge cases de reglas de negocio (back-to-back, reservas canceladas) y volumen (200 registros en bulk, solapamientos dentro del mismo batch). Los componentes LWC se prueban con Jest (`sfdx-lwc-jest`); los mocks de métodos Apex usados por `@wire` viven en `force-app/test/jest-mocks/apex/` (fuera del bundle del componente, para que no se intenten desplegar como metadata real — ver `jest.config.js`).

## Roadmap

Estado actual por hito (detalle completo con historias en [`docs/property-manager-roadmap.md`](docs/property-manager-roadmap.md)):

- ✅ **Hito 0** — Modelo de datos
- 🟡 **Hito 1** — Seguridad y permisos (Permission Sets listos; Guest User se resuelve en el Hito 3)
- 🟡 **Hito 2** — Lógica de negocio en Apex y Flow (no overbooking, cálculo de total, liberación/no-show de habitaciones y tarea de limpieza automática listos)
- ✅ **Hito 3** — Sitio Experience Cloud (publicado; Guest User anónimo viendo demo data)
- ✅ **Hito 4** — Portal de autoservicio del huésped (login/registro, ver/editar/cancelar la propia reserva)
- 🟡 **Hito 5** — Componentes LWC (dashboard de propiedad, chequeo de disponibilidad y creación de reserva listos; faltan las historias 5.4-5.5)
- ⬜ **Hito 6** — Agentforce

## Desarrollo asistido por IA

Este repo usa [`sf-skills`](https://github.com/forcedotcom/sf-skills) (instaladas en `.agents/skills/`, referenciadas en `skills-lock.json`) para asistir el desarrollo con agentes de IA en tareas de Apex, LWC, metadata, permission sets y Experience Cloud.

## Cómo levantar el proyecto

Requiere [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) y un org autenticado.

```bash
# Ver el org configurado por defecto
sf config get target-org

# Retrieve de metadata desde el org
sf project retrieve start --target-org <alias>

# Deploy de metadata al org
sf project deploy start --target-org <alias>

# Correr los tests de Apex
sf apex run test --target-org <alias> --result-format human --synchronous
```

Para levantar un scratch org nuevo con la definición incluida en `config/project-scratch-def.json`:

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias <alias> --set-default
sf project deploy start --target-org <alias>
```
