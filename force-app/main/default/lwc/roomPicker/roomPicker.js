import { LightningElement, api, wire } from "lwc";
import getRoomsForProperty from "@salesforce/apex/RoomAvailabilityController.getRoomsForProperty";

export default class RoomPicker extends LightningElement {
  @api propertyId;
  options = [];
  error;

  @wire(getRoomsForProperty, { propertyId: "$propertyId" })
  wiredRooms({ data, error }) {
    if (data) {
      this.options = data.map((room) => ({
        label: `${room.Name} (${room.Room_Type__c})`,
        value: room.Id
      }));
      this.error = undefined;
    } else if (error) {
      this.error = "No se pudieron cargar las habitaciones.";
      this.options = [];
    }
  }

  handleChange(event) {
    this.dispatchEvent(
      new CustomEvent("roomselect", { detail: { roomId: event.detail.value } })
    );
  }
}
