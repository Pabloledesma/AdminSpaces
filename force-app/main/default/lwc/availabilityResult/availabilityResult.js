import { LightningElement, api } from "lwc";

export default class AvailabilityResult extends LightningElement {
  @api isAvailable;
  @api hasChecked;

  get resultMessage() {
    return this.isAvailable ? "Disponible ✅" : "No disponible ❌";
  }
}
