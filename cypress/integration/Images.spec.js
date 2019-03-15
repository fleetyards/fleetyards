describe('Images', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('Images')

    cy.url().should('include', '/images')

    cy.get('.images a').should('have.length', Cypress.env('CI') ? 16 : 30)
  })
})
