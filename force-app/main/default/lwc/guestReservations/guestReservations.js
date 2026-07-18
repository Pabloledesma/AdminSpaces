import { LightningElement, wire } from "lwc";
import getMyReservations from "@salesforce/apex/ReservationSelfServiceController.getMyReservations";
import updateMyReservationDates from "@salesforce/apex/ReservationSelfServiceController.updateMyReservationDates";
import cancelMyReservation from "@salesforce/apex/ReservationSelfServiceController.cancelMyReservation";
import { refreshApex } from "@salesforce/apex";

export default class GuestReservations extends LightningElement {
  reservations;
  error;
  wiredResult;
  pendingChanges = {};
  saveErrors = {};
  savingReservationId;
  savedReservationId;
  cancelingReservationId;
  cancelErrors = {};

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
      const CANCELLABLE_STATUSES = ["Pending", "Confirmed"];
      const isCanceling = this.cancelingReservationId === reservation.Id;
      const canCancel = CANCELLABLE_STATUSES.includes(reservation.Status__c);
      const isSaving = this.savingReservationId === reservation.Id;
      const justSaved = this.savedReservationId === reservation.Id;
      return {
        ...reservation,
        isSaving,
        justSaved,
        saveDisabled: isSaving || justSaved,
        saveError: this.saveErrors[reservation.Id],
        isCanceling,
        cancelDisabled: isCanceling || !canCancel,
        cancelError: this.cancelErrors[reservation.Id]
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

  async handleCancel(event) {
    const reservationId = event.target.dataset.reservationId;

    // eslint-disable-next-line no-alert
    const confirmed = window.confirm(
      "Estas seguro/a que quieres cancelar esta reserva?"
    );
    if (!confirmed) {
      return;
    }

    this.cancelingReservationId = reservationId;
    delete this.cancelErrors[reservationId];

    try {
      await cancelMyReservation({ reservationId });
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.cancelErrors = {
        ...this.cancelErrors,
        [reservationId]: error.body?.message ?? "Ocurrió un error inesperado."
      };
    } finally {
      this.cancelingReservationId = undefined;
    }
  }
}
