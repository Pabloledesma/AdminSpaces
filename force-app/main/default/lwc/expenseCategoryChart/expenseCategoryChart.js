import { LightningElement, api, wire } from "lwc";
import getExpensesByCategory from "@salesforce/apex/FinanceController.getExpensesByCategory";

export default class ExpenseCategoryChart extends LightningElement {
  @api propertyId;
  categories;

  @wire(getExpensesByCategory, { propertyId: "$propertyId" })
  wiredCategories({ data }) {
    if (data) {
      const maxTotal = Math.max(...data.map((c) => c.total), 0);
      this.categories = data.map((c) => ({
        category: c.category,
        total: c.total,
        barStyle: `width: ${maxTotal ? Math.round((c.total / maxTotal) * 100) : 0}%; background: #1589ee; height: 8px;`
      }));
    }
  }

  get hasCategories() {
    return Boolean(this.categories && this.categories.length);
  }
}
