describe('Images', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.get('.nav-toggle').click()
    cy.get('nav a').contains('Images').click()

    cy.url().should('include', '/images')

    cy.get('.images a').should('have.length', Cypress.env('CI') ? 16 : 30)
  })
})
