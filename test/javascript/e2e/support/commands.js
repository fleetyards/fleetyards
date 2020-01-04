Cypress.Commands.add('select', (id) => cy.get(`[data-test="${id}"]`))
Cypress.Commands.add('selectInput', (id) => cy.get(`[data-test="${id}"] > input`))

Cypress.Commands.add('clickNav', (name) => {
  cy.contains('nav a', name).click()
})

Cypress.Commands.add('acceptConfirm', () => {
  cy.get('#noty-confirm .noty_buttons button:first-child').click()
})

Cypress.Commands.add('cancelConfirm', () => {
  cy.get('#noty-confirm .noty_buttons button:last-child').click()
})

Cypress.Commands.add('alert', (message) => {
  cy.get('.noty_type__error .noty_body', { timeout: 10000 }).then(($noty) => {
    expect($noty).to.contain(message)
  })
})

Cypress.Commands.add('success', (message) => {
  cy.get('.noty_type__success .noty_body', { timeout: 10000 }).then(($noty) => {
    expect($noty).to.contain(message)
  })
})
