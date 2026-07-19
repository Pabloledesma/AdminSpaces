import getDashboardData from "@salesforce/apex/PropertyDashboardController.getDashboardData";
import { LightningElement, wire, api } from "lwc";

export default class PropertyDashboard extends LightningElement {
  @api recordId;
  dashboardData;
  error;

  @wire(getDashboardData, { propertyId: "$recordId" })
  wiredDashboardData({ data, error }) {
    if (data) {
      this.dashboardData = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.dashboardData = undefined;
    }
  }
}
