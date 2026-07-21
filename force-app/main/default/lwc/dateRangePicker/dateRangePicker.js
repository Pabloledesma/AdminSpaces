import { LightningElement } from "lwc";
export default class DateRangePicker extends LightningElement {
  checkIn;
  checkOut;

  handleCheckInChange(event) {
    this.checkIn = event.target.value;
    this.notifyChange();
  }
  handleCheckOutChange(event) {
    this.checkOut = event.target.value;
    this.notifyChange();
  }
  notifyChange() {
    this.dispatchEvent(
      new CustomEvent("daterangechange", {
        detail: { checkIn: this.checkIn, checkOut: this.checkOut }
      })
    );
  }
}
