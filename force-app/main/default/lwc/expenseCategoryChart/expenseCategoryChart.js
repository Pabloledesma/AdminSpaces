import { LightningElement, api, wire } from "lwc";
import getExpensesByCategory from "@salesforce/apex/FinanceController.getExpensesByCategory";

export default class ExpenseCategoryChart extends LightningElement {
  categories;
  error;
  isLoading = true;
  _propertyId;

  /**
   * Getter/setter en vez de campo plano para volver al estado "cargando" cada
   * vez que el padre cambia de propiedad: sin esto, el spinner solo aparecería
   * en la primera carga y en los cambios siguientes se verían los datos de la
   * propiedad anterior hasta que llegara la respuesta nueva.
   */
  @api
  get propertyId() {
    return this._propertyId;
  }

  set propertyId(value) {
    this._propertyId = value;
    this.isLoading = true;
  }

  @wire(getExpensesByCategory, { propertyId: "$propertyId" })
  wiredCategories({ data, error }) {
    this.isLoading = false;
    if (data) {
      const maxTotal = data.reduce((max, cat) => Math.max(max, cat.total), 0);
      this.categories = data.map((cat) => ({
        category: cat.category,
        total: cat.total,
        barStyle: `width: ${maxTotal ? Math.round((cat.total / maxTotal) * 100) : 0}%`
      }));
      this.error = undefined;
    } else if (error) {
      this.error =
        error.body?.message ??
        "No pudimos cargar los gastos de esta propiedad.";
      this.categories = undefined;
    }
  }

  get hasCategories() {
    return Boolean(this.categories && this.categories.length);
  }
}
