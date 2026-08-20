import { createElement } from "lwc";
import BudgetProjection from "c/budgetProjection";

const PROYECCION = {
  months: [
    { label: "2026-09", amount: 300, fromReservations: true },
    { label: "2026-10", amount: 16.67, fromReservations: false }
  ],
  total: 316.67,
  historicalMonthlyAverage: 16.67
};

function crear(projection) {
  const element = createElement("c-budget-projection", {
    is: BudgetProjection
  });
  element.projection = projection;
  document.body.appendChild(element);
  return element;
}

describe("c-budget-projection", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("muestra una fila por mes del período", () => {
    const element = crear(PROYECCION);

    const filas = element.shadowRoot.querySelectorAll('[data-id="month-row"]');
    expect(filas.length).toBe(2);
    expect(filas[0].textContent).toContain("2026-09");
  });

  it("distingue el mes con reservas reales del estimado con el promedio", () => {
    const element = crear(PROYECCION);

    const origenes = element.shadowRoot.querySelectorAll(
      '[data-id="month-origin"]'
    );
    expect(origenes[0].textContent).toBe("Reservas");
    expect(origenes[1].textContent).toBe("Promedio");
  });

  it("muestra el total y el promedio histórico como moneda", () => {
    const element = crear(PROYECCION);

    const importes = element.shadowRoot.querySelectorAll(
      "lightning-formatted-number"
    );
    // 2 meses + total + promedio
    expect(importes.length).toBe(4);
    expect(
      Array.from(importes).every((n) => n.formatStyle === "currency")
    ).toBe(true);
    expect(
      element.shadowRoot.querySelector('[data-id="projection-total"]')
    ).not.toBeNull();
  });

  it("no renderiza nada si todavía no hay proyección", () => {
    const element = crear(undefined);

    expect(element.shadowRoot.querySelector("table")).toBeNull();
  });
});
