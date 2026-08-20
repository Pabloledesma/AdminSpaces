import { createElement } from "lwc";
import FinancesDashboard from "c/financesDashboard";
import getProperties from "@salesforce/apex/FinanceController.getProperties";

// Igual que en expenseCategoryChart: el mensaje del servidor (texto del Custom
// Label Finance_Properties_Load_Error) tiene que ser distinto del fallback del
// componente, si no el test no distingue "propaga" de "inventa".
const MENSAJE_DEL_SERVIDOR =
  "No pudimos cargar las propiedades. Es posible que no tengas permisos sobre Propiedades.";
const MENSAJE_FALLBACK = "No pudimos cargar las propiedades.";

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

    // La Historia 5.6 suma el planificador de presupuesto a la misma tab,
    // alimentado por la misma selección de propiedad.
    const planner = element.shadowRoot.querySelector("c-budget-planner");
    expect(planner).not.toBeNull();
    expect(planner.propertyId).toBe("prop1");
  });

  it("muestra el error del servidor en vez de un combobox vacío (caso negativo)", async () => {
    const element = createElement("c-finances-dashboard", {
      is: FinancesDashboard
    });
    document.body.appendChild(element);

    getProperties.error({ message: MENSAJE_DEL_SERVIDOR });

    await Promise.resolve();

    const errorMessage = element.shadowRoot.querySelector(
      '[data-id="properties-error"]'
    );
    expect(errorMessage.textContent).toContain(MENSAJE_DEL_SERVIDOR);
    // El combobox vacío era un callejón sin salida: se reemplaza por el error
    expect(element.shadowRoot.querySelector("lightning-combobox")).toBeNull();
  });

  it("usa un mensaje propio si el error del servidor no trae message", async () => {
    const element = createElement("c-finances-dashboard", {
      is: FinancesDashboard
    });
    document.body.appendChild(element);

    getProperties.error({});
    await Promise.resolve();

    const texto = element.shadowRoot.querySelector(
      '[data-id="properties-error"]'
    ).textContent;
    expect(texto).toContain(MENSAJE_FALLBACK);
    expect(texto).not.toContain("Es posible que no tengas permisos");
  });

  it("desmonta el gráfico si el wire falla después de haber cargado propiedades", async () => {
    const element = createElement("c-finances-dashboard", {
      is: FinancesDashboard
    });
    document.body.appendChild(element);

    getProperties.emit([{ Id: "prop1", Name: "Propiedad Test 1" }]);
    await Promise.resolve();
    element.shadowRoot
      .querySelector("lightning-combobox")
      .dispatchEvent(new CustomEvent("change", { detail: { value: "prop1" } }));
    await Promise.resolve();
    expect(
      element.shadowRoot.querySelector("c-expense-category-chart")
    ).not.toBeNull();

    // Al fallar la carga de propiedades, la selección anterior deja de ser
    // válida: el gráfico no puede quedar mostrando datos de una propiedad que
    // ya no se puede ni elegir.
    getProperties.error({ message: MENSAJE_DEL_SERVIDOR });
    await Promise.resolve();

    expect(
      element.shadowRoot.querySelector("c-expense-category-chart")
    ).toBeNull();
  });
});
