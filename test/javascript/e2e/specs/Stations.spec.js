describe('Stations', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('Stations')

    cy.get('#stations-sub-menu').contains('Overview').click()

    cy.url().should('include', '/stations')

    cy.get('.panel-title a').contains('Port Olisar').should('exist')

    cy.get('.panel').should('have.length', Cypress.env('CI') ? 1 : 10)
  })
})
