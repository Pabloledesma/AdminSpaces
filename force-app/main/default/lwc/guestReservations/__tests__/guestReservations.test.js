import { createElement } from "lwc";
import GuestReservations from "c/guestReservations";
import getMyReservationsAdapter from "@salesforce/apex/ReservationSelfServiceController.getMyReservations";

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
