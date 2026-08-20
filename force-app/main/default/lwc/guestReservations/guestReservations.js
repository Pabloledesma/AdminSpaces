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
  refreshError;

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

    let guardado = false;
    try {
      await updateMyReservationDates({
        reservationId,
        newCheckin: changes.checkin ?? null,
        newCheckout: changes.checkout ?? null
      });
      guardado = true;
    } catch (error) {
      this.saveErrors = {
        ...this.saveErrors,
        [reservationId]: error.body?.message ?? "Ocurrió un error inesperado."
      };
    } finally {
      this.savingReservationId = undefined;
    }

    if (!guardado) {
      return;
    }

    // El cambio ya está aplicado en el servidor. Marcarlo como guardado y
    // limpiar los cambios pendientes no puede depender de que el refresco de
    // la lista funcione: si el refresco falla, el huésped vería un error sobre
    // un cambio que sí se guardó, con sus ediciones todavía en pantalla, y lo
    // más probable es que lo reintente.
    this.savedReservationId = reservationId;
    delete this.pendingChanges[reservationId];

    await this.refreshList(
      "Guardamos tu cambio, pero no pudimos actualizar la vista. Recargá la página para verla al día."
    );
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

    let cancelada = false;
    try {
      await cancelMyReservation({ reservationId });
      cancelada = true;
    } catch (error) {
      this.cancelErrors = {
        ...this.cancelErrors,
        [reservationId]: error.body?.message ?? "Ocurrió un error inesperado."
      };
    } finally {
      this.cancelingReservationId = undefined;
    }

    if (!cancelada) {
      return;
    }

    await this.refreshList(
      "Cancelamos tu reserva, pero no pudimos actualizar la vista. Recargá la página para verla al día."
    );
  }

  /**
   * El refresco de la lista es un paso aparte de la mutación: su resultado no
   * cambia si la mutación funcionó o no, solo si lo que se ve en pantalla está
   * al día.
   */
  async refreshList(mensajeSiFalla) {
    try {
      await refreshApex(this.wiredResult);
      this.refreshError = undefined;
    } catch {
      this.refreshError = mensajeSiFalla;
    }
  }
}
