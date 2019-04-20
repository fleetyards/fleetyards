describe('Roadmap', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('Ship-Roadmap')

    cy.url().should('include', '/roadmap')

    cy.get('.roadmap-item').should('have.length', Cypress.env('CI') ? 1 : 62)
  })
})
