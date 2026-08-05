import { createElement } from "lwc";
import ExpenseCategoryChart from "c/expenseCategoryChart";
import getExpensesByCategory from "@salesforce/apex/FinanceController.getExpensesByCategory";

describe("c-expense-category-chart", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("muestra una barra por categoría con el ancho proporcional al total", async () => {
    const element = createElement("c-expense-category-chart", {
      is: ExpenseCategoryChart
    });
    element.propertyId = "a06000000000001AAA";
    document.body.appendChild(element);

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
    expect(bars[0].textContent).toContain("100");

    const progressValues = element.shadowRoot.querySelectorAll(
      ".slds-progress-bar__value"
    );
    // Labor es el total más alto (300), así que su barra debe ser el 100% del ancho
    expect(progressValues[1].style.width).toBe("100%");
    // Materials es 100/300 ≈ 33%
    expect(progressValues[0].style.width).toBe("33%");
  });

  it("muestra un mensaje cuando no hay gastos", async () => {
    const element = createElement("c-expense-category-chart", {
      is: ExpenseCategoryChart
    });
    element.propertyId = "a06000000000001AAA";
    document.body.appendChild(element);

    getExpensesByCategory.emit([]);
    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain(
      "Todavía no hay gastos cargados"
    );
  });

  it("maneja errores del servidor y muestra el estado vacío (caso negativo)", async () => {
    const element = createElement("c-expense-category-chart", {
      is: ExpenseCategoryChart
    });
    element.propertyId = "a06000000000001AAA";
    document.body.appendChild(element);

    getExpensesByCategory.error("Server Error");
    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain(
      "Todavía no hay gastos cargados"
    );
  });
});
