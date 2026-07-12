import { LightningElement, wire } from "lwc";
import getMyReservations from "@salesforce/apex/ReservationSelfServiceController.getMyReservations";

export default class GuestReservations extends LightningElement {
  reservations;
  error;

  @wire(getMyReservations)
  wiredReservations({ data, error }) {
    if (data) {
      this.reservations = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.reservations = undefined;
    }
  }

  get hasReservations() {
    return this.reservations && this.reservations.length > 0;
  }

  get isEmpty() {
    return this.reservations && this.reservations.length === 0;
  }
}
