import { createElement } from "lwc";
import BudgetPlanner from "c/budgetPlanner";
import { refreshApex } from "@salesforce/apex";
import previewProjection from "@salesforce/apex/BudgetController.previewProjection";
import createBudget from "@salesforce/apex/BudgetController.createBudget";
import getBudgets from "@salesforce/apex/BudgetController.getBudgets";

jest.mock(
  "@salesforce/apex",
  () => ({
    refreshApex: jest.fn()
  }),
  { virtual: true }
);

const PROPERTY_ID = "a06000000000001AAA";
const PROYECCION = {
  months: [{ label: "2026-09", amount: 300, fromReservations: true }],
  total: 300,
  historicalMonthlyAverage: 16.67
};

function crear() {
  const element = createElement("c-budget-planner", { is: BudgetPlanner });
  element.propertyId = PROPERTY_ID;
  document.body.appendChild(element);
  return element;
}

// El handler lee event.target.value, así que lo que importa es setear el value
// del input y disparar el change sobre ese mismo elemento.
function elegirPeriodo(element, desde, hasta) {
  const [start, end] = element.shadowRoot.querySelectorAll("lightning-input");
  start.value = desde;
  start.dispatchEvent(new CustomEvent("change"));
  end.value = hasta;
  end.dispatchEvent(new CustomEvent("change"));
}

function boton(element, id) {
  return element.shadowRoot.querySelector(`[data-id="${id}"]`);
}

describe("c-budget-planner", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("mantiene deshabilitado Proyectar hasta tener un período válido", async () => {
    const element = crear();
    expect(boton(element, "project-button").disabled).toBe(true);

    // Rango invertido: sigue sin habilitarse
    elegirPeriodo(element, "2026-12-01", "2026-09-01");
    await Promise.resolve();
    expect(boton(element, "project-button").disabled).toBe(true);

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    expect(boton(element, "project-button").disabled).toBe(false);
  });

  it("proyecta con el período elegido y le pasa el resultado al hijo", async () => {
    previewProjection.mockResolvedValue(PROYECCION);
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    expect(previewProjection).toHaveBeenCalledWith({
      propertyId: PROPERTY_ID,
      startDate: "2026-09-01",
      endDate: "2026-12-01"
    });
    expect(
      element.shadowRoot.querySelector("c-budget-projection").projection
    ).toEqual(PROYECCION);
  });

  it("muestra el error del servidor si la proyección falla", async () => {
    previewProjection.mockRejectedValue({
      body: { message: "No pudimos calcular la proyección de ingresos." }
    });
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    expect(boton(element, "projection-error").textContent).toContain(
      "No pudimos calcular la proyección de ingresos."
    );
    expect(
      element.shadowRoot.querySelector('[data-id="save-button"]')
    ).toBeNull();
  });

  it("no ofrece guardar hasta que exista una proyección", async () => {
    previewProjection.mockResolvedValue(PROYECCION);
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    expect(boton(element, "save-button")).toBeNull();

    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();
    expect(boton(element, "save-button")).not.toBeNull();
  });

  it("guarda el presupuesto y avisa, aunque la proyección se limpie en el mismo handler", async () => {
    previewProjection.mockResolvedValue(PROYECCION);
    createBudget.mockResolvedValue("a0X000000000001AAA");
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    boton(element, "save-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(createBudget).toHaveBeenCalledWith({
      propertyId: PROPERTY_ID,
      startDate: "2026-09-01",
      endDate: "2026-12-01"
    });
    // El mensaje vive fuera del lwc:if de la proyección: tiene que seguir visible
    expect(boton(element, "saved-message").textContent).toContain(
      "2026-09-01 → 2026-12-01"
    );
  });

  it("muestra el error del servidor si falla el guardado", async () => {
    previewProjection.mockResolvedValue(PROYECCION);
    createBudget.mockRejectedValue({
      body: { message: "La fecha de fin del presupuesto debe ser posterior." }
    });
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    boton(element, "save-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(boton(element, "projection-error").textContent).toContain(
      "La fecha de fin del presupuesto debe ser posterior."
    );
    expect(boton(element, "saved-message")).toBeNull();
  });

  it("un refresco fallido no puede decir que falló el guardado", async () => {
    previewProjection.mockResolvedValue(PROYECCION);
    createBudget.mockResolvedValue("a0X000000000001AAA");
    refreshApex.mockRejectedValue({ body: undefined });
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    boton(element, "save-button").dispatchEvent(new CustomEvent("click"));
    for (let i = 0; i < 6; i++) {
      // eslint-disable-next-line no-await-in-loop
      await Promise.resolve();
    }

    // El registro se creó: el mensaje de éxito manda, y no puede convivir con
    // un error que diga lo contrario.
    expect(createBudget).toHaveBeenCalledTimes(1);
    expect(boton(element, "saved-message")).not.toBeNull();
    expect(boton(element, "projection-error")).toBeNull();
    // Lo único que falló fue el refresco de la lista, y eso es lo que se avisa.
    expect(boton(element, "list-error").textContent).toContain(
      "no pudimos actualizar la lista"
    );
  });

  it("cambiar el período descarta la proyección anterior", async () => {
    previewProjection.mockResolvedValue(PROYECCION);
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();
    expect(boton(element, "save-button")).not.toBeNull();

    elegirPeriodo(element, "2027-01-01", "2027-06-01");
    await Promise.resolve();

    expect(boton(element, "save-button")).toBeNull();
    expect(
      element.shadowRoot.querySelector("c-budget-projection").projection
    ).toBeUndefined();
  });

  it("usa mensajes propios cuando el error del servidor no trae message", async () => {
    previewProjection.mockRejectedValue({ body: {} });
    const element = crear();

    elegirPeriodo(element, "2026-09-01", "2026-12-01");
    await Promise.resolve();
    boton(element, "project-button").dispatchEvent(new CustomEvent("click"));
    await Promise.resolve();
    await Promise.resolve();

    const texto = boton(element, "projection-error").textContent;
    expect(texto).toContain("No pudimos calcular la proyección.");
    // La cola "de ingresos" solo existe en el mensaje del servidor: si aparece,
    // el componente lo estaría inventando en vez de propagarlo.
    expect(texto).not.toContain("de ingresos");
  });

  it("usa un mensaje propio si el error del wire no trae message", async () => {
    const element = crear();

    getBudgets.error({});
    await Promise.resolve();

    const texto = boton(element, "list-error").textContent;
    expect(texto).toContain("No pudimos cargar los presupuestos.");
    expect(texto).not.toContain("de esta propiedad");
  });

  it("le pasa a la lista los presupuestos que devuelve el wire", async () => {
    const element = crear();

    getBudgets.emit([
      {
        id: "a0A1",
        name: "BUD-0001",
        projectedIncome: 1000,
        actualExpenses: 250,
        available: 750
      }
    ]);
    await Promise.resolve();

    expect(
      element.shadowRoot.querySelector("c-budget-list").budgets.length
    ).toBe(1);
  });

  it("muestra el error del wire en vez de una lista vacía", async () => {
    const element = crear();

    getBudgets.error({
      message: "No pudimos cargar los presupuestos de esta propiedad."
    });
    await Promise.resolve();

    expect(boton(element, "list-error").textContent).toContain(
      "No pudimos cargar los presupuestos de esta propiedad."
    );
    expect(element.shadowRoot.querySelector("c-budget-list")).toBeNull();
  });
});
