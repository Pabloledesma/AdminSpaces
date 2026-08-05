import { createElement } from "lwc";
import FinancesDashboard from "c/financesDashboard";
import getProperties from "@salesforce/apex/FinanceController.getProperties";

describe("c-finances-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renderiza la estructura inicial del DOM correctamente (sin gráfico)", () => {
    const element = createElement("c-finances-dashboard", {
      is: FinancesDashboard
    });
    document.body.appendChild(element);

    // El componente base card y el combobox deben existir
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("Tablero de Finanzas");

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox).not.toBeNull();
    expect(combobox.options).toEqual([]); // Inicialmente vacío

    // El gráfico no debe renderizarse hasta seleccionar una propiedad
    const chart = element.shadowRoot.querySelector("c-expense-category-chart");
    expect(chart).toBeNull();
  });

  it("puebla las opciones del combobox cuando el backend devuelve propiedades", async () => {
    const element = createElement("c-finances-dashboard", {
      is: FinancesDashboard
    });
    document.body.appendChild(element);

    // Simulamos datos de propiedades devueltos por FinanceController.getProperties
    const mockProperties = [
      { Id: "prop1", Name: "Propiedad Test 1" },
      { Id: "prop2", Name: "Propiedad Test 2" }
    ];
    getProperties.emit(mockProperties);

    // Esperamos a que los re-renders asíncronos finalicen
    await Promise.resolve();

    // Verificamos que se mapearon a { label, value } correctamente
    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox.options.length).toBe(2);
    expect(combobox.options[0].label).toBe("Propiedad Test 1");
    expect(combobox.options[0].value).toBe("prop1");
    expect(combobox.options[1].label).toBe("Propiedad Test 2");
    expect(combobox.options[1].value).toBe("prop2");
  });

  it("muestra el gráfico de gastos al seleccionar una propiedad (interacción del DOM)", async () => {
    const element = createElement("c-finances-dashboard", {
      is: FinancesDashboard
    });
    document.body.appendChild(element);

    const mockProperties = [{ Id: "prop1", Name: "Propiedad Test 1" }];
    getProperties.emit(mockProperties);
    await Promise.resolve();

    // Simulamos que el usuario selecciona una propiedad
    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    combobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "prop1" } })
    );

    await Promise.resolve();

    // Verificamos que el gráfico hijo se renderizó y recibió el ID correcto
    const chart = element.shadowRoot.querySelector("c-expense-category-chart");
    expect(chart).not.toBeNull();
    expect(chart.propertyId).toBe("prop1");
  });

  it("maneja el error del servidor e ignora propiedades vacías (caso negativo)", async () => {
    const element = createElement("c-finances-dashboard", {
      is: FinancesDashboard
    });
    document.body.appendChild(element);

    // Espiamos a console.error para no imprimir errores reales durante el test
    const consoleSpy = jest
      .spyOn(console, "error")
      .mockImplementation(() => {});

    // Simulamos un error devuelto por Apex
    getProperties.error("Error interno del servidor");

    await Promise.resolve();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox.options.length).toBe(0);
    expect(consoleSpy).toHaveBeenCalled();

    consoleSpy.mockRestore();
  });
});
