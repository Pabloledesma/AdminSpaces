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
  _propertyId;

  /**
   * Setter y no un campo suelto porque cambiar de propiedad tiene que invalidar
   * lo que hay en pantalla: si quedara el desglose de la propiedad anterior, el
   * botón "Guardar" seguiría activo y se guardaría un presupuesto para la
   * propiedad nueva con un número que el usuario nunca vio para esa propiedad.
   */
  @api
  get propertyId() {
    return this._propertyId;
  }
  set propertyId(value) {
    if (value === this._propertyId) {
      return;
    }
    this._propertyId = value;
    this.resetProjection();
    this.isLoadingBudgets = true;
  }

  startDate;
  endDate;
  projection;
  budgets;
  projectionError;
  listError;
  savedBudgetName;
  isProjecting = false;
  isSaving = false;
  isLoadingBudgets = true;

  budgetsResult;

  @wire(getBudgets, { propertyId: "$_propertyId" })
  wiredBudgets(result) {
    this.budgetsResult = result;
    const { data, error } = result;
    if (data || error) {
      this.isLoadingBudgets = false;
    }
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
      this._propertyId &&
      this.startDate &&
      this.endDate &&
      this.endDate > this.startDate
    );
  }

  get cannotProject() {
    // También mientras se guarda: si el usuario reproyecta con otras fechas en
    // medio del guardado, el mensaje de éxito terminaría nombrando un período
    // distinto del que se guardó.
    return !this.canProject || this.isProjecting || this.isSaving;
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
        propertyId: this._propertyId,
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

    // El período se captura acá y se usa para el insert y para el mensaje: son
    // el mismo dato, no puede leerse dos veces del estado.
    const desde = this.startDate;
    const hasta = this.endDate;

    let guardado = false;
    try {
      await createBudget({
        propertyId: this._propertyId,
        startDate: desde,
        endDate: hasta
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

    this.savedBudgetName = `${desde} → ${hasta}`;
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
