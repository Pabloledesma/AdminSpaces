// Script para generar gastos de prueba para la primera propiedad disponible
Property__c prop = [SELECT Id, Name FROM Property__c LIMIT 1];

List<Expense__c> expenses = new List<Expense__c>{
    new Expense__c(Property__c = prop.Id, Category__c = 'Materials', Amount__c = 1500, Expense_Date__c = Date.today().addDays(-10), Is_Demo__c = true),
    new Expense__c(Property__c = prop.Id, Category__c = 'Labor', Amount__c = 3200, Expense_Date__c = Date.today().addDays(-5), Is_Demo__c = true),
    new Expense__c(Property__c = prop.Id, Category__c = 'Permits', Amount__c = 850, Expense_Date__c = Date.today().addDays(-20), Is_Demo__c = true),
    new Expense__c(Property__c = prop.Id, Category__c = 'Furniture', Amount__c = 4500, Expense_Date__c = Date.today().addDays(-2), Is_Demo__c = true),
    new Expense__c(Property__c = prop.Id, Category__c = 'Other', Amount__c = 300, Expense_Date__c = Date.today().addDays(-1), Is_Demo__c = true),
    new Expense__c(Property__c = prop.Id, Category__c = 'Labor', Amount__c = 800, Expense_Date__c = Date.today().addDays(-1), Is_Demo__c = true) // Gasto adicional para verificar que se agrupen bien
};

insert expenses;
System.debug('Se insertaron ' + expenses.size() + ' gastos para la propiedad: ' + prop.Name);
