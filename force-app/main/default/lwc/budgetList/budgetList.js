import { LightningElement, api } from "lwc";

/**
 * Presentacional puro: presupuestos ya creados, cada uno con lo que se proyectó
 * el día que se armó, lo que se gastó dentro de su período y la diferencia.
 * El signo del disponible es la única lógica que vive acá, y es de presentación:
 * pintar en rojo cuando el gasto se pasó de lo proyectado.
 */
export default class BudgetList extends LightningElement {
  @api budgets;

  get rows() {
    return (this.budgets ?? []).map((budget) => ({
      ...budget,
      claseDisponible:
        budget.available < 0
          ? "slds-text-align_right slds-text-color_error"
          : "slds-text-align_right"
    }));
  }

  get hasBudgets() {
    return this.rows.length > 0;
  }
}
