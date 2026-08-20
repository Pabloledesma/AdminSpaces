import { LightningElement, api } from "lwc";

/**
 * Presentacional puro: muestra el desglose mes a mes que calculó el Apex.
 * No sabe de qué propiedad se trata ni cómo se calculó cada mes; solo distingue
 * visualmente los meses que salen de reservas reales de los estimados con el
 * promedio histórico, que es la decisión de diseño central de la Historia 5.6.
 */
export default class BudgetProjection extends LightningElement {
  @api projection;

  get months() {
    return (this.projection?.months ?? []).map((month) => ({
      ...month,
      origen: month.fromReservations ? "Reservas" : "Promedio",
      claseOrigen: month.fromReservations
        ? "slds-badge slds-badge_inverse"
        : "slds-badge"
    }));
  }

  get hasMonths() {
    return this.months.length > 0;
  }
}
