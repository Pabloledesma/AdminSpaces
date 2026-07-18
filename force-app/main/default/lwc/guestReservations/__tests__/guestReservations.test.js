import { createElement } from "lwc";
import GuestReservations from "c/guestReservations";
import getMyReservationsAdapter from "@salesforce/apex/ReservationSelfServiceController.getMyReservations";
import updateMyReservationDates from "@salesforce/apex/ReservationSelfServiceController.updateMyReservationDates";
import cancelMyReservation from "@salesforce/apex/ReservationSelfServiceController.cancelMyReservation";
import { refreshApex } from "@salesforce/apex";

jest.mock(
  "@salesforce/apex",
  () => ({
    refreshApex: jest.fn()
  }),
  { virtual: true }
);

const MOCK_RESERVATIONS = [
  {
    Id: "a01000000000001AAA",
    Status__c: "Confirmed",
    Check_In_Date__c: "2026-08-01",
    Check_Out_Date__c: "2026-08-05",
    Total_Amount__c: 400,
    Room__r: { Name: "R-0001", Room_Type__c: "Suite" }
  }
];

describe("guardar fechas de la reserva", () => {
  beforeEach(() => {
    updateMyReservationDates.mockReset();
  });

  it("llama a updateReservationDates con los parámetros correctos", async () => {
    const RESERVATION_ID = MOCK_RESERVATIONS[0].Id;
    const element = createElement("c-guest-guestReservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);

    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const checkinInput = element.shadowRoot.querySelector(
      `[data-reservation-id="${RESERVATION_ID}"][data-field="checkin"]`
    );
    checkinInput.value = "2026-08-01";
    checkinInput.dispatchEvent(new CustomEvent("change"));

    const checkoutInput = element.shadowRoot.querySelector(
      `[data-reservation-id="${RESERVATION_ID}"][data-field="checkout"]`
    );
    checkoutInput.value = "2026-08-10";
    checkoutInput.dispatchEvent(new CustomEvent("change"));

    const saveButton = element.shadowRoot.querySelector(
      `[data-reservation-id="${RESERVATION_ID}"][data-field="saveButton"]`
    );
    saveButton.dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();

    expect(updateMyReservationDates).toHaveBeenCalledWith({
      reservationId: RESERVATION_ID,
      newCheckin: "2026-08-01",
      newCheckout: "2026-08-10"
    });

    expect(refreshApex).toHaveBeenCalledTimes(1);
  });

  it("deshabilita el botón mientras se está guardando", async () => {
    updateMyReservationDates.mockReturnValue(new Promise(() => {})); // nunca se resuelve
    const RESERVATION_ID = MOCK_RESERVATIONS[0].Id;
    const element = createElement("c-guest-reservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);
    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const saveButton = element.shadowRoot.querySelector(
      `[data-reservation-id = "${RESERVATION_ID}"][data-field="saveButton"]`
    );
    saveButton.dispatchEvent(new CustomEvent("click"));
    await Promise.resolve(); //deja que arranque el handleSave y llegue al primer await

    expect(saveButton.disabled).toBe(true);
  });

  it("muestra el mensaje de exito y deshabilita el botón al guardar con éxito", async () => {
    updateMyReservationDates.mockResolvedValue();
    const RESERVATION_ID = MOCK_RESERVATIONS[0].Id;

    const element = createElement("c-guest-reservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);
    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const saveButton = element.shadowRoot.querySelector(
      `[data-reservation-id = "${RESERVATION_ID}"][data-field="saveButton"]`
    );
    saveButton.dispatchEvent(new CustomEvent("click"));

    // varios ticks: uno por cada await encadenado dentro de handleSave
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    const successMessage = element.shadowRoot.querySelector(
      '[data-id="save-success"]'
    );
    expect(successMessage).not.toBeNull();
    expect(saveButton.disabled).toBe(true);
  });

  it("vuelve a habilitarse si el huesped edita de nuevo", async () => {
    updateMyReservationDates.mockResolvedValue();
    const RESERVATION_ID = MOCK_RESERVATIONS[0].Id;

    const element = createElement("c-guest-reservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);
    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const saveButton = element.shadowRoot.querySelector(
      `[data-reservation-id = "${RESERVATION_ID}"][data-field="saveButton"]`
    );
    saveButton.dispatchEvent(new CustomEvent("click"));

    // varios ticks: uno por cada await encadenado dentro de handleSave
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    const successMessage = element.shadowRoot.querySelector(
      '[data-id="save-success"]'
    );
    expect(successMessage).not.toBeNull();
    expect(saveButton.disabled).toBe(true);

    const checkinInput = element.shadowRoot.querySelector(
      `[data-reservation-id="${RESERVATION_ID}"][data-field="checkin"]`
    );
    checkinInput.value = "2026-08-02";
    checkinInput.dispatchEvent(new CustomEvent("change"));
    await Promise.resolve();

    expect(
      element.shadowRoot.querySelector('[data-id="save-success"]')
    ).toBeNull();
    expect(saveButton.disabled).toBe(false);
  });

  it("muestra el mensaje de error si falla el guardado", async () => {
    updateMyReservationDates.mockRejectedValue({
      body: {
        message:
          "Las fechas se solapan con otra reserva existente para esta habitación."
      }
    });
    const RESERVATION_ID = MOCK_RESERVATIONS[0].Id;

    const element = createElement("c-guest-reservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);
    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const saveButton = element.shadowRoot.querySelector(
      `[data-reservation-id="${RESERVATION_ID}"][data-field="saveButton"]`
    );
    saveButton.dispatchEvent(new CustomEvent("click"));

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    const errorMessage = element.shadowRoot.querySelector(
      '[data-id="save-error"]'
    );
    expect(errorMessage).not.toBeNull();
    expect(errorMessage.textContent).toContain("se solapan");
  });
});

describe("c-guest-reservations", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders a card for each reservation returned by the wire", async () => {
    const element = createElement("c-guest-reservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);

    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const cards = element.shadowRoot.querySelectorAll(
      '[data-id="reservation-card"]'
    );
    expect(cards.length).toBe(MOCK_RESERVATIONS.length);
    expect(cards[0].textContent).toContain("Suite");
    expect(cards[0].textContent).toContain("Confirmed");
  });

  it("shows an empty state message when there are no reservations", async () => {
    const element = createElement("c-guest-reservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);

    getMyReservationsAdapter.emit([]);
    await Promise.resolve();

    const emptyState = element.shadowRoot.querySelector(
      '[data-id="empty-state"]'
    );
    expect(emptyState).not.toBeNull();
    expect(
      element.shadowRoot.querySelector('[data-id="reservation-card"]')
    ).toBeNull();
  });

  it("shows an error state when the wire adapter errors out", async () => {
    const element = createElement("c-guest-reservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);

    getMyReservationsAdapter.error();
    await Promise.resolve();

    const errorState = element.shadowRoot.querySelector(
      '[data-id="error-state"]'
    );
    expect(errorState).not.toBeNull();
  });
});

describe("cancelar la reserva", () => {
  beforeEach(() => {
    cancelMyReservation.mockReset();
  });

  it("pide confirmación y no cancela si el usuario dice que no", async () => {
    jest.spyOn(window, "confirm").mockReturnValue(false);

    const RESERVATION_ID = MOCK_RESERVATIONS[0].Id;
    const element = createElement("c-guest-guestReservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);

    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const cancelButton = element.shadowRoot.querySelector(
      `[data-reservation-id="${RESERVATION_ID}"][data-field="cancelButton"]`
    );
    cancelButton.dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    expect(cancelMyReservation).not.toHaveBeenCalled();
  });

  it("cancela la reserva si el usuario confirma", async () => {
    jest.spyOn(window, "confirm").mockReturnValue(true);
    cancelMyReservation.mockResolvedValue();

    const RESERVATION_ID = MOCK_RESERVATIONS[0].Id;
    const element = createElement("c-guest-guestReservations", {
      is: GuestReservations
    });
    document.body.appendChild(element);

    getMyReservationsAdapter.emit(MOCK_RESERVATIONS);
    await Promise.resolve();

    const cancelButton = element.shadowRoot.querySelector(
      `[data-reservation-id="${RESERVATION_ID}"][data-field="cancelButton"]`
    );
    cancelButton.dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(cancelMyReservation).toHaveBeenCalledWith({
      reservationId: RESERVATION_ID
    });
  });
});
