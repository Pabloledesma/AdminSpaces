import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import previewProjection from "@salesforce/apex/BudgetController.previewProjection";
import createBudget from "@salesforce/apex/BudgetController.createBudget";
import getBudgets from "@salesforce/apex/BudgetController.getBudgets";

/**
 * Orquestador de la Historia 5.6. Sostiene el estado (período elegido,
 * proyección calculada, presupuestos existentes) y habla con Apex; sus dos
 * hijos, budgetProjection y budgetList, son presentacionales.
 *
 * previewProjection y createBudget son imperativos porque los dispara el
 * usuario; getBudgets es @wire porque es la foto de los datos que ya existen.
 */
export default class BudgetPlanner extends LightningElement {
  @api propertyId;

  startDate;
  endDate;
  projection;
  budgets;
  projectionError;
  listError;
  savedBudgetName;
  isProjecting = false;
  isSaving = false;

  budgetsResult;

  @wire(getBudgets, { propertyId: "$propertyId" })
  wiredBudgets(result) {
    this.budgetsResult = result;
    const { data, error } = result;
    if (data) {
      this.budgets = data;
      this.listError = undefined;
    } else if (error) {
      this.listError =
        error.body?.message ?? "No pudimos cargar los presupuestos.";
      this.budgets = undefined;
    }
  }

  handleStartDateChange(event) {
    this.startDate = event.target.value;
    this.resetProjection();
  }

  handleEndDateChange(event) {
    this.endDate = event.target.value;
    this.resetProjection();
  }

  /**
   * Cambiar el período invalida lo proyectado antes: mostrar un desglose que
   * ya no corresponde a las fechas de la pantalla sería peor que no mostrar
   * nada.
   */
  resetProjection() {
    this.projection = undefined;
    this.projectionError = undefined;
    this.savedBudgetName = undefined;
  }

  get canProject() {
    return Boolean(
      this.propertyId &&
      this.startDate &&
      this.endDate &&
      this.endDate > this.startDate
    );
  }

  get cannotProject() {
    return !this.canProject || this.isProjecting;
  }

  get cannotSave() {
    return !this.projection || this.isSaving;
  }

  async handleProject() {
    this.isProjecting = true;
    this.projectionError = undefined;
    this.savedBudgetName = undefined;
    try {
      this.projection = await previewProjection({
        propertyId: this.propertyId,
        startDate: this.startDate,
        endDate: this.endDate
      });
    } catch (error) {
      this.projection = undefined;
      this.projectionError =
        error.body?.message ?? "No pudimos calcular la proyección.";
    } finally {
      this.isProjecting = false;
    }
  }

  async handleSave() {
    this.isSaving = true;
    this.projectionError = undefined;

    let guardado = false;
    try {
      await createBudget({
        propertyId: this.propertyId,
        startDate: this.startDate,
        endDate: this.endDate
      });
      guardado = true;
    } catch (error) {
      this.projectionError =
        error.body?.message ?? "No pudimos guardar el presupuesto.";
    } finally {
      this.isSaving = false;
    }

    if (!guardado) {
      return;
    }

    this.savedBudgetName = `${this.startDate} → ${this.endDate}`;
    this.projection = undefined;

    // El refresco va fuera del try del guardado a propósito: a esta altura el
    // presupuesto ya existe en la base, así que si el refresco falla no se
    // puede decir que falló el guardado. Sería mostrarle al usuario un error
    // sobre un registro que sí se creó.
    try {
      await refreshApex(this.budgetsResult);
    } catch {
      this.listError =
        "Guardamos el presupuesto, pero no pudimos actualizar la lista. Recargá la página para verla al día.";
    }
  }
}
