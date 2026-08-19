import { createElement } from "lwc";
import ExpenseCategoryChart from "c/expenseCategoryChart";
import getExpensesByCategory from "@salesforce/apex/FinanceController.getExpensesByCategory";

// El mensaje del servidor tiene que ser DISTINTO del fallback del componente:
// si son iguales, el test pasa igual aunque el componente ignore lo que manda Apex.
// Este es el texto real del Custom Label Finance_Expenses_Load_Error.
const MENSAJE_DEL_SERVIDOR =
  "No pudimos cargar los gastos de esta propiedad. Es posible que no tengas permisos sobre Gastos.";
const MENSAJE_FALLBACK = "No pudimos cargar los gastos de esta propiedad.";

function createChart() {
  const element = createElement("c-expense-category-chart", {
    is: ExpenseCategoryChart
  });
  element.propertyId = "a06000000000001AAA";
  document.body.appendChild(element);
  return element;
}

describe("c-expense-category-chart", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("muestra el spinner mientras espera la respuesta del servidor", () => {
    const element = createChart();

    expect(
      element.shadowRoot.querySelector('[data-id="chart-spinner"]')
    ).not.toBeNull();
    // Sin datos todavía no debe verse el estado vacío: son estados distintos
    expect(
      element.shadowRoot.querySelector('[data-id="chart-empty"]')
    ).toBeNull();
  });

  it("muestra una barra por categoría con el ancho proporcional al total", async () => {
    const element = createChart();

    getExpensesByCategory.emit([
      { category: "Materials", total: 100 },
      { category: "Labor", total: 300 }
    ]);
    await Promise.resolve();

    const bars = element.shadowRoot.querySelectorAll(
      '[data-id="category-bar"]'
    );
    expect(bars.length).toBe(2);
    expect(bars[0].textContent).toContain("Materials");

    const progressValues = element.shadowRoot.querySelectorAll(
      ".slds-progress-bar__value"
    );
    // Labor es el total más alto (300), así que su barra debe ser el 100% del ancho
    expect(progressValues[1].style.width).toBe("100%");
    // Materials es 100/300 ≈ 33%
    expect(progressValues[0].style.width).toBe("33%");
  });

  it("formatea los importes como moneda en vez de imprimir el número crudo", async () => {
    const element = createChart();

    getExpensesByCategory.emit([{ category: "Materials", total: 1234.5 }]);
    await Promise.resolve();

    const amount = element.shadowRoot.querySelector(
      "lightning-formatted-number"
    );
    expect(amount.value).toBe(1234.5);
    expect(amount.formatStyle).toBe("currency");
  });

  it("marca la barra como decorativa para el lector de pantalla", async () => {
    const element = createChart();

    getExpensesByCategory.emit([{ category: "Materials", total: 100 }]);
    await Promise.resolve();

    const bar = element.shadowRoot.querySelector(".slds-progress-bar");
    expect(bar.getAttribute("aria-hidden")).toBe("true");
  });

  it("no rompe cuando todas las categorías suman cero", async () => {
    const element = createChart();

    // maxTotal = 0: la división por el máximo tiene que quedar en 0%, no en NaN
    getExpensesByCategory.emit([{ category: "Materials", total: 0 }]);
    await Promise.resolve();

    const bar = element.shadowRoot.querySelector(".slds-progress-bar__value");
    expect(bar.style.width).toBe("0%");
  });

  it("muestra un mensaje cuando no hay gastos", async () => {
    const element = createChart();

    getExpensesByCategory.emit([]);
    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain(
      "Todavía no hay gastos cargados"
    );
  });

  it("muestra el mensaje del servidor cuando el Apex falla, no el estado vacío", async () => {
    const element = createChart();

    getExpensesByCategory.error({ message: MENSAJE_DEL_SERVIDOR });
    await Promise.resolve();

    const errorMessage = element.shadowRoot.querySelector(
      '[data-id="chart-error"]'
    );
    expect(errorMessage.textContent).toContain(MENSAJE_DEL_SERVIDOR);
    expect(
      element.shadowRoot.querySelector('[data-id="chart-empty"]')
    ).toBeNull();
  });

  it("usa un mensaje propio si el error del servidor no trae message", async () => {
    const element = createChart();

    // Un error sin message en el body (no todo error de plataforma lo trae):
    // el fallback del ?? es el que tiene que responder
    getExpensesByCategory.error({});
    await Promise.resolve();

    const texto = element.shadowRoot.querySelector(
      '[data-id="chart-error"]'
    ).textContent;
    expect(texto).toContain(MENSAJE_FALLBACK);
    // Y no puede aparecer la parte que solo existe en el mensaje del servidor:
    // eso probaría que el componente lo está inventando en vez de propagarlo.
    expect(texto).not.toContain("Es posible que no tengas permisos");
  });
});
