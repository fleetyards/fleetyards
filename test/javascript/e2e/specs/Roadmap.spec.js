describe('Roadmap', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('roadmap-menu')
    cy.clickNav('roadmap')

    cy.url().should('include', '/roadmap')

    cy.get('.roadmap-item').should('have.length', 50)

    cy.clickNav('roadmap-ships')

    cy.url().should('include', '/roadmap/ships')

    cy.get('.roadmap-item').should('have.length', 50)

    cy.clickNav('roadmap-changes')

    cy.url().should('include', '/roadmap/changes')
  })
})
