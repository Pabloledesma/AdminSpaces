import { LightningElement, wire } from "lwc";
import getProperties from "@salesforce/apex/FinanceController.getProperties";

export default class FinancesDashboard extends LightningElement {
  propertyOptions = [];
  selectedPropertyId;

  @wire(getProperties)
  wiredProperties({ error, data }) {
    if (data) {
      this.propertyOptions = data.map((prop) => ({
        label: prop.Name,
        value: prop.Id
      }));
    } else if (error) {
      console.error("Error fetching properties", error);
    }
  }

  handlePropertyChange(event) {
    this.selectedPropertyId = event.detail.value;
  }
}
