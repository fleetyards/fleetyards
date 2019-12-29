describe('Roadmap', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('Roadmap')

    cy.get('#roadmap-sub-menu a').contains('Overview').click()

    cy.url().should('include', '/roadmap')

    cy.get('.roadmap-item').should('have.length', Cypress.env('CI') ? 1 : 62)

    cy.get('#roadmap-sub-menu a').contains('Ship-Roadmap').click()

    cy.url().should('include', '/roadmap/ships')

    cy.get('.roadmap-item').should('have.length', Cypress.env('CI') ? 1 : 62)

    cy.get('#roadmap-sub-menu a').contains('Changes').click()

    cy.url().should('include', '/roadmap/changes')
  })
})
