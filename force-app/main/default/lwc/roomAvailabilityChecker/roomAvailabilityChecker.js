import { LightningElement, api, wire } from "lwc";
import checkAvailability from "@salesforce/apex/RoomAvailabilityController.checkAvailability";
import getBlockedDateRangesForRoom from "@salesforce/apex/RoomAvailabilityController.getBlockedDateRangesForRoom";

export default class RoomAvailabilityChecker extends LightningElement {
  @api recordId;
  selectedRoomId;
  checkinDate;
  checkoutDate;
  isAvailable;
  blockedRanges;

  @wire(getBlockedDateRangesForRoom, { roomId: "$selectedRoomId" })
  wiredBlockedRanges({ data }) {
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

  async handleCheckAvailability() {
    this.isAvailable = await checkAvailability({
      roomId: this.selectedRoomId,
      checkIn: this.checkinDate,
      checkOut: this.checkoutDate
    });
  }
}
