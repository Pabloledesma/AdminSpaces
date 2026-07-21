import { createElement } from "lwc";
import RoomAvailabilityChecker from "c/roomAvailabilityChecker";
import checkAvailability from "@salesforce/apex/RoomAvailabilityController.checkAvailability";
import createReservation from "@salesforce/apex/ReservationCreationController.createReservation";

jest.mock(
  "@salesforce/apex",
  () => ({
    refreshApex: jest.fn()
  }),
  { virtual: true }
);

describe("c-room-availability-checker", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("llama a checkAvailability con los datos elegidos en los hijos", async () => {
    checkAvailability.mockResolvedValue(true);
    // Arrange
    const element = createElement("c-room-availability-checker", {
      is: RoomAvailabilityChecker
    });
    element.recordId = "a06000000000001AAA";

    // Act
    document.body.appendChild(element);

    // Assert
    // Simulás lo que "roomPicker" dispararía al elegir una habitación
    const roomPicker = element.shadowRoot.querySelector("c-room-picker");
    roomPicker.dispatchEvent(
      new CustomEvent("roomselect", {
        detail: { roomId: "a05000000000001AAA" }
      })
    );
    // Simulando lo que 'dateRangePicker' dispararía al completar las fechas
    const dateRangePicker = element.shadowRoot.querySelector(
      "c-date-range-picker"
    );
    dateRangePicker.dispatchEvent(
      new CustomEvent("daterangechange", {
        detail: { checkIn: "2026-08-01", checkOut: "2026-08-05" }
      })
    );
    await Promise.resolve();

    const button = element.shadowRoot.querySelector("lightning-button");
    button.dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();

    expect(checkAvailability).toHaveBeenCalledWith({
      roomId: "a05000000000001AAA",
      checkIn: "2026-08-01",
      checkOut: "2026-08-05"
    });
  });

  it("no muestra el selector de huésped ni el botón de crear si todavía no se verificó disponibilidad", () => {
    const element = createElement("c-room-availability-checker", {
      is: RoomAvailabilityChecker
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    expect(
      element.shadowRoot.querySelector("lightning-record-picker")
    ).toBeNull();
  });

  it("crea la reserva cuando está disponible y se eligió un huésped", async () => {
    checkAvailability.mockResolvedValue(true);
    createReservation.mockResolvedValue("a07000000000001AAA");

    const element = createElement("c-room-availability-checker", {
      is: RoomAvailabilityChecker
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    const roomPicker = element.shadowRoot.querySelector("c-room-picker");
    roomPicker.dispatchEvent(
      new CustomEvent("roomselect", {
        detail: { roomId: "a05000000000001AAA" }
      })
    );
    const dateRangePicker = element.shadowRoot.querySelector(
      "c-date-range-picker"
    );
    dateRangePicker.dispatchEvent(
      new CustomEvent("daterangechange", {
        detail: { checkIn: "2026-08-01", checkOut: "2026-08-05" }
      })
    );
    await Promise.resolve();

    element.shadowRoot
      .querySelector("lightning-button")
      .dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    const guestPicker = element.shadowRoot.querySelector(
      "lightning-record-picker"
    );
    expect(guestPicker).not.toBeNull();
    guestPicker.dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "003000000000001AAA" }
      })
    );
    await Promise.resolve();

    const createButton =
      element.shadowRoot.querySelectorAll("lightning-button")[1];
    createButton.dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    expect(createReservation).toHaveBeenCalledWith({
      roomId: "a05000000000001AAA",
      guestContactId: "003000000000001AAA",
      checkIn: "2026-08-01",
      checkOut: "2026-08-05"
    });
  });
});
