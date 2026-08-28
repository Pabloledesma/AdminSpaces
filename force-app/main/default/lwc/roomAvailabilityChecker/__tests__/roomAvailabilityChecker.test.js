import { createElement } from "lwc";
import RoomAvailabilityChecker from "c/roomAvailabilityChecker";
import checkAvailability from "@salesforce/apex/RoomAvailabilityController.checkAvailability";
import createReservation from "@salesforce/apex/ReservationCreationController.createReservation";
import { refreshApex } from "@salesforce/apex";

jest.mock(
  "@salesforce/apex",
  () => ({
    refreshApex: jest.fn()
  }),
  { virtual: true }
);

// refreshApex es un mock compartido por todo el archivo: si un test lo deja
// rechazando, los siguientes lo heredan (clearAllMocks limpia llamadas, no
// implementaciones). Cada test arranca con un refresco que funciona.
beforeEach(() => {
  refreshApex.mockReset();
  refreshApex.mockResolvedValue(undefined);
});

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

  it("muestra el mensaje de éxito después de crear la reserva", async () => {
    checkAvailability.mockResolvedValue(true);
    createReservation.mockResolvedValue("a07000000000001AAA");

    const element = createElement("c-room-availability-checker", {
      is: RoomAvailabilityChecker
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    element.shadowRoot.querySelector("c-room-picker").dispatchEvent(
      new CustomEvent("roomselect", {
        detail: { roomId: "a05000000000001AAA" }
      })
    );
    element.shadowRoot.querySelector("c-date-range-picker").dispatchEvent(
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

    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "003000000000001AAA" }
      })
    );
    await Promise.resolve();

    element.shadowRoot
      .querySelectorAll("lightning-button")[1]
      .dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain(
      "Reserva creada con éxito"
    );
  });

  it("limpia el mensaje de éxito cuando se elige una nueva habitación", async () => {
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
    element.shadowRoot.querySelector("c-date-range-picker").dispatchEvent(
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

    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "003000000000001AAA" }
      })
    );
    await Promise.resolve();

    element.shadowRoot
      .querySelectorAll("lightning-button")[1]
      .dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain(
      "Reserva creada con éxito"
    );

    roomPicker.dispatchEvent(
      new CustomEvent("roomselect", {
        detail: { roomId: "a05000000000002AAA" }
      })
    );
    await Promise.resolve();

    expect(element.shadowRoot.textContent).not.toContain(
      "Reserva creada con éxito"
    );
  });

  it("un refresco fallido no puede decir que la reserva no se creó", async () => {
    checkAvailability.mockResolvedValue(true);
    createReservation.mockResolvedValue("a01000000000001AAA");
    refreshApex.mockRejectedValue({ body: undefined });

    const element = createElement("c-room-availability-checker", {
      is: RoomAvailabilityChecker
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    element.shadowRoot.querySelector("c-room-picker").dispatchEvent(
      new CustomEvent("roomselect", {
        detail: { roomId: "a05000000000001AAA" }
      })
    );
    element.shadowRoot.querySelector("c-date-range-picker").dispatchEvent(
      new CustomEvent("daterangechange", {
        detail: { checkIn: "2026-08-01", checkOut: "2026-08-05" }
      })
    );
    await Promise.resolve();

    const [checkButton] =
      element.shadowRoot.querySelectorAll("lightning-button");
    checkButton.dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "003000000000001AAA" }
      })
    );
    await Promise.resolve();

    element.shadowRoot
      .querySelectorAll("lightning-button")[1]
      .dispatchEvent(new CustomEvent("click"));
    for (let i = 0; i < 6; i++) {
      // eslint-disable-next-line no-await-in-loop
      await Promise.resolve();
    }

    // La reserva existe: no puede aparecer el error de creación...
    expect(createReservation).toHaveBeenCalledTimes(1);
    const errores = Array.from(
      element.shadowRoot.querySelectorAll(".slds-text-color_error")
    ).map((p) => p.textContent);
    expect(errores).not.toContain("Ocurrió un error inesperado.");
    // ...y sí el aviso de que lo desactualizado es la pantalla.
    expect(
      element.shadowRoot.querySelector('[data-id="refresh-error"]').textContent
    ).toContain("Creamos la reserva");
  });

  it("limpia el aviso de refresco fallido al cambiar la selección", async () => {
    checkAvailability.mockResolvedValue(true);
    createReservation.mockResolvedValue("a01000000000001AAA");
    refreshApex.mockRejectedValue({ body: undefined });

    const element = createElement("c-room-availability-checker", {
      is: RoomAvailabilityChecker
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    element.shadowRoot.querySelector("c-room-picker").dispatchEvent(
      new CustomEvent("roomselect", {
        detail: { roomId: "a05000000000001AAA" }
      })
    );
    element.shadowRoot.querySelector("c-date-range-picker").dispatchEvent(
      new CustomEvent("daterangechange", {
        detail: { checkIn: "2026-08-01", checkOut: "2026-08-05" }
      })
    );
    await Promise.resolve();

    element.shadowRoot
      .querySelectorAll("lightning-button")[0]
      .dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "003000000000001AAA" }
      })
    );
    await Promise.resolve();

    element.shadowRoot
      .querySelectorAll("lightning-button")[1]
      .dispatchEvent(new CustomEvent("click"));
    for (let i = 0; i < 6; i++) {
      // eslint-disable-next-line no-await-in-loop
      await Promise.resolve();
    }
    expect(
      element.shadowRoot.querySelector('[data-id="refresh-error"]')
    ).not.toBeNull();

    // El usuario elige otra habitación: el aviso hablaba de la operación
    // anterior y ya no aplica a lo que hay en pantalla.
    element.shadowRoot.querySelector("c-room-picker").dispatchEvent(
      new CustomEvent("roomselect", {
        detail: { roomId: "a05000000000002AAA" }
      })
    );
    await Promise.resolve();

    expect(
      element.shadowRoot.querySelector('[data-id="refresh-error"]')
    ).toBeNull();
  });
});
