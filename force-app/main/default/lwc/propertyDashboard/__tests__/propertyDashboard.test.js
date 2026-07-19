import { createElement } from "@lwc/engine-dom";
import PropertyDashboard from "c/propertyDashboard";
import getDashboardData from "@salesforce/apex/PropertyDashboardController.getDashboardData";

const MOCK_DASHBOARD_DATA = {
  totalRooms: 5,
  occupiedRooms: 3,
  monthlyRevenue: 450,
  pendingTasksCount: 2
};

describe("c-property-dashboard", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("muestra datos del dashboard cuando el wire resuelve", async () => {
    // Arrange
    const element = createElement("c-property-dashboard", {
      is: PropertyDashboard
    });
    element.recordId = "a06000000000001AAA";
    // Act
    document.body.appendChild(element);
    getDashboardData.emit(MOCK_DASHBOARD_DATA);
    await Promise.resolve();
    // Assert
    // const div = element.shadowRoot.querySelector('div');
    expect(element.shadowRoot.textContent).toContain("5");
    expect(element.shadowRoot.textContent).toContain("3");
    expect(element.shadowRoot.textContent).toContain("450");
    expect(element.shadowRoot.textContent).toContain("2");
  });
});
