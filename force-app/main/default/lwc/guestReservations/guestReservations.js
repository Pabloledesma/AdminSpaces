import { LightningElement, wire } from "lwc";
import getMyReservations from "@salesforce/apex/ReservationSelfServiceController.getMyReservations";
import updateMyReservationDates from "@salesforce/apex/ReservationSelfServiceController.updateMyReservationDates";
import { refreshApex } from "@salesforce/apex";

export default class GuestReservations extends LightningElement {
  reservations;
  error;
  wiredResult;
  pendingChanges = {};
  saveErrors = {};
  savingReservationId;
  savedReservationId;

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

  get reservationsView() {
    if (!this.reservations) {
      return [];
    }
    return this.reservations.map((reservation) => {
      const isSaving = this.savingReservationId === reservation.Id;
      const justSaved = this.savedReservationId === reservation.Id;
      return {
        ...reservation,
        isSaving,
        justSaved,
        saveDisabled: isSaving || justSaved,
        saveError: this.saveErrors[reservation.Id]
      };
    });
  }

  get hasReservations() {
    return this.reservations && this.reservations.length > 0;
  }

  get isEmpty() {
    return this.reservations && this.reservations.length === 0;
  }

  handleCheckoutChange(event) {
    this.updatePendingChange(event, "checkout");
  }

  handleCheckinChange(event) {
    this.updatePendingChange(event, "checkin");
  }

  updatePendingChange(event, field) {
    const id = event.target.dataset.reservationId;
    this.pendingChanges[id] = {
      ...this.pendingChanges[id],
      [field]: event.target.value
    };
    if (this.savedReservationId === id) {
      this.savedReservationId = undefined;
    }
  }

  async handleSave(event) {
    const reservationId = event.target.dataset.reservationId;
    const changes = this.pendingChanges[reservationId] || {};

    this.savingReservationId = reservationId;
    delete this.saveErrors[reservationId];

    try {
      await updateMyReservationDates({
        reservationId,
        newCheckin: changes.checkin ?? null,
        newCheckout: changes.checkout ?? null
      });
      await refreshApex(this.wiredResult);
      this.savedReservationId = reservationId;
      delete this.pendingChanges[reservationId];
    } catch (error) {
      this.saveErrors = {
        ...this.saveErrors,
        [reservationId]: error.body?.message ?? "Ocurrió un error inesperado."
      };
    } finally {
      this.savingReservationId = undefined;
    }
  }
}
