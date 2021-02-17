import 'cypress-mochawesome-reporter/register'
import './commands'

Cypress.on(
  'uncaught:exception',
  (_err, _runnable) =>
    // returning false here prevents Cypress from
    // failing the test
    false,
)
