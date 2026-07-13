import { LightningElement, wire } from "lwc";
import getMyReservations from "@salesforce/apex/ReservationSelfServiceController.getMyReservations";
import updateMyReservationDates from "@salesforce/apex/ReservationSelfServiceController.updateMyReservationDates";
import { refreshApex } from "@salesforce/apex";

export default class GuestReservations extends LightningElement {
  reservations;
  error;
  wiredResult;
  pendingChanges = {};

  @wire(getMyReservations)
  wiredReservations(result) {
    this.wiredResult = result;
    const { data, error } = result;
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

  handleCheckoutChange(event) {
    const id = event.target.dataset.reservationId;
    this.pendingChanges[id] = {
      ...this.pendingChanges[id],
      checkout: event.target.value
    };
  }

  handleCheckinChange(event) {
    const id = event.target.dataset.reservationId;
    this.pendingChanges[id] = {
      ...this.pendingChanges[id],
      checkin: event.target.value
    };
  }

  async handleSave(event) {
    const reservationId = event.target.dataset.reservationId;
    const changes = this.pendingChanges[reservationId] || {};

    try {
      this.saveError = undefined;
      await updateMyReservationDates({
        reservationId,
        newCheckin: changes.checkin ?? null,
        newCheckout: changes.checkout ?? null
      });
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.saveError = error.body?.message ?? "Ocurrió un error inesperado.";
    }
  }
}
