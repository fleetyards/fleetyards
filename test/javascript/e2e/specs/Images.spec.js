describe('Images', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('images')

    cy.url().should('include', '/images')

    cy.get('.images a').should('have.length', Cypress.env('CI') ? 20 : 30)
  })
})
