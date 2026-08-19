import { LightningElement, wire } from "lwc";
import getProperties from "@salesforce/apex/FinanceController.getProperties";

export default class FinancesDashboard extends LightningElement {
  propertyOptions = [];
  selectedPropertyId;
  error;

  @wire(getProperties)
  wiredProperties({ error, data }) {
    if (data) {
      this.propertyOptions = data.map((prop) => ({
        label: prop.Name,
        value: prop.Id
      }));
      this.error = undefined;
    } else if (error) {
      // Antes esto era un console.error: el usuario veía un combobox vacío,
      // indistinguible de "todavía no hay propiedades cargadas".
      this.error = error.body?.message ?? "No pudimos cargar las propiedades.";
      this.propertyOptions = [];
      this.selectedPropertyId = undefined;
    }
  }

  handlePropertyChange(event) {
    this.selectedPropertyId = event.detail.value;
  }
}
