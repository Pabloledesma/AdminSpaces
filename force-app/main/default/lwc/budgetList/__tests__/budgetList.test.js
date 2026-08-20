import { createElement } from "lwc";
import BudgetList from "c/budgetList";

const PRESUPUESTOS = [
  {
    id: "a0A1",
    name: "BUD-0001",
    startDate: "2026-09-01",
    endDate: "2026-11-30",
    projectedIncome: 1000,
    actualExpenses: 250,
    available: 750
  },
  {
    id: "a0A2",
    name: "BUD-0002",
    startDate: "2026-01-01",
    endDate: "2026-03-31",
    projectedIncome: 500,
    actualExpenses: 800,
    available: -300
  }
];

function crear(budgets) {
  const element = createElement("c-budget-list", { is: BudgetList });
  element.budgets = budgets;
  document.body.appendChild(element);
  return element;
}

describe("c-budget-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("muestra una fila por presupuesto", () => {
    const element = crear(PRESUPUESTOS);

    const filas = element.shadowRoot.querySelectorAll('[data-id="budget-row"]');
    expect(filas.length).toBe(2);
    expect(filas[0].textContent).toContain("BUD-0001");
  });

  it("marca en rojo el presupuesto que se pasó de lo proyectado", () => {
    const element = crear(PRESUPUESTOS);

    const disponibles = element.shadowRoot.querySelectorAll(
      '[data-id="available"]'
    );
    expect(disponibles[0].className).not.toContain("slds-text-color_error");
    expect(disponibles[1].className).toContain("slds-text-color_error");
  });

  it("avisa cuando la propiedad no tiene presupuestos", () => {
    const element = crear([]);

    expect(
      element.shadowRoot.querySelector('[data-id="budget-list-empty"]')
        .textContent
    ).toContain("todavía no tiene presupuestos");
  });

  it("trata la ausencia de datos como lista vacía, no como error", () => {
    const element = crear(undefined);

    expect(
      element.shadowRoot.querySelector('[data-id="budget-list-empty"]')
    ).not.toBeNull();
  });
});
