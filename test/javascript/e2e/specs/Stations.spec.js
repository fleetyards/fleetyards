describe('Stations', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('stations-menu')
    cy.clickNav('stations')

    cy.url().should('include', '/stations')

    cy.get('.panel-title a').contains('Port Olisar').should('exist')

    cy.get('.panel').should('have.length', Cypress.env('CI') ? 1 : 10)
  })
})
