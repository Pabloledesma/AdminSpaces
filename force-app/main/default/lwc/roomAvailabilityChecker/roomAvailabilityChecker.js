import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import checkAvailability from "@salesforce/apex/RoomAvailabilityController.checkAvailability";
import getBlockedDateRangesForRoom from "@salesforce/apex/RoomAvailabilityController.getBlockedDateRangesForRoom";
import createReservation from "@salesforce/apex/ReservationCreationController.createReservation";

export default class RoomAvailabilityChecker extends LightningElement {
  @api recordId;
  selectedRoomId;
  checkinDate;
  checkoutDate;
  isAvailable;
  blockedRanges;
  selectedGuestId;
  reservationCreated;
  createError;

  blockedRangesResult;

  @wire(getBlockedDateRangesForRoom, { roomId: "$selectedRoomId" })
  wiredBlockedRanges(result) {
    this.blockedRangesResult = result;
    const { data } = result;
    if (data) {
      this.blockedRanges = data.map((reservation) => ({
        id: reservation.Id,
        label: `${reservation.Check_In_Date__c} - ${reservation.Check_Out_Date__c}`
      }));
    }
  }

  handleRoomSelect(event) {
    this.selectedRoomId = event.detail.roomId;
    this.isAvailable = undefined;
  }

  handleDateRangeChange(event) {
    this.checkinDate = event.detail.checkIn;
    this.checkoutDate = event.detail.checkOut;
    this.isAvailable = undefined;
  }

  handleGuestSelect(event) {
    this.selectedGuestId = event.detail.recordId;
  }

  get canCheck() {
    return Boolean(
      this.selectedRoomId && this.checkinDate && this.checkoutDate
    );
  }

  get cannotCheck() {
    return !this.canCheck;
  }

  get hasBeenChecked() {
    return this.isAvailable !== undefined;
  }

  get canCreate() {
    return Boolean(this.isAvailable && this.selectedGuestId);
  }

  get cannotCreate() {
    return !this.canCreate;
  }

  async handleCheckAvailability() {
    this.isAvailable = await checkAvailability({
      roomId: this.selectedRoomId,
      checkIn: this.checkinDate,
      checkOut: this.checkoutDate
    });
  }

  async handleCreateReservation() {
    this.createError = undefined;
    this.reservationCreated = false;
    try {
      await createReservation({
        roomId: this.selectedRoomId,
        guestContactId: this.selectedGuestId,
        checkIn: this.checkinDate,
        checkOut: this.checkoutDate
      });
      this.reservationCreated = true;
      this.isAvailable = undefined;
      this.selectedGuestId = undefined;
      await refreshApex(this.blockedRangesResult);
    } catch (error) {
      this.createError = error.body?.message ?? "Ocurrió un error inesperado.";
    }
  }
}
