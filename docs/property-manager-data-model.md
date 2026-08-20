# Property Manager — Modelo de Datos (Fase 1)

Orden recomendado de creación (respeta las dependencias de Master-Detail):

1. Property__c
2. Room__c
3. Reservation__c (usa Contact estándar para huéspedes)
4. Maintenance_Task__c
5. Expense__c

> Nota de diseño: uso relaciones **Master-Detail** en la jerarquía principal (Property → Room → Reservation, y Property → Expense) porque así puedes usar **Roll-Up Summary Fields** y porque el Master-Detail propaga el sharing del padre — esto es justo el tema que vas a explicar en la parte de seguridad del Guest User más adelante.

---

## 1. Property__c

| Campo                | Tipo            | Detalles                                                                      |
| -------------------- | --------------- | ----------------------------------------------------------------------------- |
| Name                 | Text            | Label "Property Name", campo estándar                                         |
| Address__c           | Text(255)       |                                                                               |
| City__c              | Text(100)       |                                                                               |
| Renovation_Status__c | Picklist        | Not Started; In Progress; Completed                                           |
| Square_Meters__c     | Number(8,2)     |                                                                               |
| Property_Owner__c    | Lookup(User)    | Opcional                                                                      |
| Is_Demo__c           | Checkbox        | Default = **true** (clave para reglas de sharing del Guest User más adelante) |
| Room_Count__c        | Roll-Up Summary | COUNT sobre Room__c (se crea después de Room__c)                              |
| Total_Expenses__c    | Roll-Up Summary | SUM sobre Expense__c.Amount__c (se crea después de Expense__c)                |

## 2. Room__c

| Campo                | Tipo            | Detalles                                     |
| -------------------- | --------------- | -------------------------------------------- |
| Name                 | Auto Number     | Formato `R-{0000}`                           |
| Property__c          | Master-Detail   | → Property__c                                |
| Room_Type__c         | Picklist        | Single; Double; Suite; Studio                |
| Capacity__c          | Number(2,0)     |                                              |
| Nightly_Rate__c      | Currency(16,2)  |                                              |
| Status__c            | Picklist        | Available; Occupied; Maintenance; Cleaning   |
| Is_Demo__c           | Checkbox        | Default = true                               |
| Reservation_Count__c | Roll-Up Summary | COUNT sobre Reservation__c (se crea después) |

## 3. Reservation__c

| Campo             | Tipo           | Detalles                                                                                      |
| ----------------- | -------------- | --------------------------------------------------------------------------------------------- |
| Name              | Auto Number    | Formato `RES-{0000}`                                                                          |
| Room__c           | Master-Detail  | → Room__c                                                                                     |
| Guest__c          | Lookup         | → Contact (objeto estándar, no crear Guest__c custom)                                         |
| Check_In_Date__c  | Date           | Required                                                                                      |
| Check_Out_Date__c | Date           | Required                                                                                      |
| Status__c         | Picklist       | Pending; Confirmed; Checked In; Checked Out; Cancelled                                        |
| Total_Amount__c   | Currency(16,2) | **No es fórmula** — se calcula por Apex (trigger) en Fase 2, para practicar lógica de negocio |
| Is_Demo__c        | Checkbox       | Default = true                                                                                |

**Validation Rule sugerida (créala ya, aunque la lógica fuerte de solapamiento la haremos en Apex):**
`Check_Out_Date__c <= Check_In_Date__c` → Error "La fecha de salida debe ser posterior a la de entrada"

## 4. Maintenance_Task__c

| Campo             | Tipo                 | Detalles                   |
| ----------------- | -------------------- | -------------------------- |
| Name              | Auto Number          | Formato `MT-{0000}`        |
| Property__c       | Lookup               | → Property__c, required    |
| Room__c           | Lookup               | → Room__c, opcional        |
| Priority__c       | Picklist             | Low; Medium; High; Urgent  |
| Status__c         | Picklist             | Pending; In Progress; Done |
| Estimated_Cost__c | Currency(16,2)       |                            |
| Description__c    | Long Text Area(1000) |                            |
| Due_Date__c       | Date                 |                            |
| Is_Demo__c        | Checkbox             | Default = true             |

_(Lookup, no Master-Detail, porque una tarea puede seguir existiendo aunque cambie la lógica de negocio de Room — más flexible para este objeto.)_

## 5. Expense__c

| Campo           | Tipo           | Detalles                                    |
| --------------- | -------------- | ------------------------------------------- |
| Name            | Auto Number    | Formato `EXP-{0000}`                        |
| Property__c     | Master-Detail  | → Property__c                               |
| Category__c     | Picklist       | Materials; Labor; Permits; Furniture; Other |
| Amount__c       | Currency(16,2) |                                             |
| Expense_Date__c | Date           |                                             |
| Is_Demo__c      | Checkbox       | Default = true                              |

---

## 6. Budget__c

Agregado en la Historia 5.6, después de los cinco objetos originales.

| Campo                 | Tipo                    | Detalles                                                                          |
| --------------------- | ----------------------- | --------------------------------------------------------------------------------- |
| Name                  | Auto Number             | `BUD-{0000}`                                                                      |
| Property\_\_c         | Master-Detail(Property) | Un presupuesto no existe sin su propiedad; hereda el sharing (ControlledByParent) |
| Start_Date\_\_c       | Date                    | Requerido. Primer mes del período proyectado                                      |
| End_Date\_\_c         | Date                    | Requerido. Validation Rule `End_After_Start`                                      |
| Projected_Income\_\_c | Currency(18,2)          | Proyección **congelada** al crear el presupuesto, no un roll-up ni una fórmula    |
| Is_Demo\_\_c          | Checkbox                | Default = **true**, mismo criterio que el resto                                   |

**Por qué `Projected_Income__c` es un campo común y no una fórmula:** una fórmula se recalcularía sola cada vez que entra una reserva, y entonces el presupuesto dejaría de ser la decisión que se tomó aquel día. El valor lo escribe `BudgetController.createBudget` una única vez, a partir de lo que devuelve `RevenueProjectionService`.

**Por qué no hay objeto de ingresos:** ver la nota de la Historia 5.5 en el roadmap — el ingreso ya es la revenue de `Reservation__c.Total_Amount__c`, y duplicarlo en otro objeto habría creado dos fuentes de verdad.

## Checklist de Page Layouts / Compact Layouts

- [ ] Agregar los Roll-Up Summary Fields después de crear los objetos hijos (no se pueden crear antes)
- [ ] Compact Layout en Room__c mostrando Status__c y Nightly_Rate__c (se verá en las tarjetas del LWC más adelante)
- [ ] Agregar related lists de Room__c y Expense__c en el layout de Property__c
- [ ] Agregar related list de Reservation__c en el layout de Room__c

## Por qué Is_Demo__c en todos los objetos

Este campo es la base de las Sharing Rules que vamos a crear en la Fase de seguridad para el Guest User del sitio Experience: solo se compartirán registros con `Is_Demo__c = true`, nunca el objeto completo. Créalo desde ya en cada objeto aunque todavía no configuremos el sitio.

---

**Siguiente fase:** Seguridad (OWD, Sharing Rules para Guest User, Permission Sets) — o si prefieres, Apex (trigger de validación de solapamiento de fechas en Reservation__c). Dime cuál prefieres cuando termines de crear esto.
