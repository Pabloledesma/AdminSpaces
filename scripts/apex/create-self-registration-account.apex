// Crea la Account a la que se van a asociar los Contact de los huéspedes
// que se autorregistren en el sitio AdminSpaces (Login & Registration ->
// Registration Page Configuration -> Account).
//
// Ejecutar con: SFDX: Execute Anonymous Apex with Editor Contents
// o: sf apex run --file scripts/apex/create-self-registration-account.apex --target-org <alias>

Account guestAccount = new Account(Name = 'AdminSpaces Portal Guests');
insert guestAccount;

System.debug('Account creada -> Id: ' + guestAccount.Id + ' | Name: ' + guestAccount.Name);
System.debug('Usá este Id en el campo Account de Login & Registration.');
