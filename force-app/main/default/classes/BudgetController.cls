public with sharing class BudgetController {
  /**
   * Lo que la tab Finanzas necesita saber de un presupuesto ya creado: lo que
   * se proyectó cuando se armó, lo que efectivamente se gastó dentro de su
   * período, y la diferencia entre las dos cosas.
   */
  public class BudgetSummary {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public Date startDate;
    @AuraEnabled
    public Date endDate;
    @AuraEnabled
    public Decimal projectedIncome;
    @AuraEnabled
    public Decimal actualExpenses;
    @AuraEnabled
    public Decimal available;
  }

  /**
   * Calcula la proyección sin guardar nada, para que el usuario vea el desglose
   * mes a mes antes de decidir. No es cacheable a propósito: es un cálculo que
   * el usuario dispara y quiere volver a correr con otras fechas.
   */
  @AuraEnabled
  public static RevenueProjectionService.Projection previewProjection(
    Id propertyId,
    Date startDate,
    Date endDate
  ) {
    validatePeriod(propertyId, startDate, endDate);

    try {
      return RevenueProjectionService.project(propertyId, startDate, endDate);
    } catch (QueryException e) {
      throw AuraExceptionUtil.create(System.Label.Budget_Projection_Error);
    }
  }

  /**
   * Congela la proyección en un Budget__c. El número guardado no se recalcula
   * después: un presupuesto es la decisión que se tomó con la información de
   * ese día, y sirve justamente para comparar contra lo que terminó pasando.
   */
  @AuraEnabled
  public static Id createBudget(Id propertyId, Date startDate, Date endDate) {
    validatePeriod(propertyId, startDate, endDate);

    RevenueProjectionService.Projection projection;
    try {
      projection = RevenueProjectionService.project(
        propertyId,
        startDate,
        endDate
      );
    } catch (QueryException e) {
      throw AuraExceptionUtil.create(System.Label.Budget_Projection_Error);
    }

    Budget__c budget = new Budget__c(
      Property__c = propertyId,
      Start_Date__c = startDate,
      End_Date__c = endDate,
      Projected_Income__c = projection.total
    );

    try {
      insert budget;
    } catch (DmlException e) {
      throw AuraExceptionUtil.create(e.getDmlMessage(0));
    }

    return budget.Id;
  }

  /**
   * Presupuestos de la propiedad con su gasto real. Los gastos se traen una
   * sola vez para la ventana completa que cubren todos los presupuestos y se
   * reparten en Apex: N presupuestos siguen siendo 2 queries, no N+1.
   */
  @AuraEnabled(cacheable=true)
  public static List<BudgetSummary> getBudgets(Id propertyId) {
    List<Budget__c> budgets;
    try {
      budgets = BudgetSelector.getByPropertyId(propertyId);
    } catch (QueryException e) {
      throw AuraExceptionUtil.create(System.Label.Budget_Load_Error);
    }

    List<BudgetSummary> summaries = new List<BudgetSummary>();
    if (budgets.isEmpty()) {
      return summaries;
    }

    Date windowStart = budgets[0].Start_Date__c;
    Date windowEnd = budgets[0].End_Date__c;
    for (Budget__c budget : budgets) {
      if (budget.Start_Date__c < windowStart) {
        windowStart = budget.Start_Date__c;
      }
      if (budget.End_Date__c > windowEnd) {
        windowEnd = budget.End_Date__c;
      }
    }

    List<Expense__c> expenses;
    try {
      expenses = ExpenseSelector.getForPropertyInPeriod(
        propertyId,
        windowStart,
        windowEnd
      );
    } catch (QueryException e) {
      throw AuraExceptionUtil.create(System.Label.Budget_Load_Error);
    }

    for (Budget__c budget : budgets) {
      BudgetSummary summary = new BudgetSummary();
      summary.id = budget.Id;
      summary.name = budget.Name;
      summary.startDate = budget.Start_Date__c;
      summary.endDate = budget.End_Date__c;
      summary.projectedIncome = budget.Projected_Income__c == null
        ? 0
        : budget.Projected_Income__c;
      summary.actualExpenses = totalSpentInPeriod(
        expenses,
        budget.Start_Date__c,
        budget.End_Date__c
      );
      summary.available = summary.projectedIncome - summary.actualExpenses;
      summaries.add(summary);
    }

    return summaries;
  }

  private static Decimal totalSpentInPeriod(
    List<Expense__c> expenses,
    Date startDate,
    Date endDate
  ) {
    Decimal total = 0;
    for (Expense__c expense : expenses) {
      if (
        expense.Amount__c != null &&
        expense.Expense_Date__c >= startDate &&
        expense.Expense_Date__c <= endDate
      ) {
        total += expense.Amount__c;
      }
    }
    return total;
  }

  private static void validatePeriod(
    Id propertyId,
    Date startDate,
    Date endDate
  ) {
    if (propertyId == null) {
      throw AuraExceptionUtil.create(System.Label.Budget_Property_Required);
    }
    if (startDate == null || endDate == null || endDate <= startDate) {
      throw AuraExceptionUtil.create(System.Label.Budget_Invalid_Period);
    }
  }
}
