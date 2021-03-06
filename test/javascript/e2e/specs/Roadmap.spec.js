describe('Roadmap', () => {
  it('Loads overview', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('roadmap-menu')
    cy.clickNav('roadmap')

    cy.url().should('include', '/roadmap')

    cy.get('.roadmap-item').should('have.length.of.at.least', 1)
  })

  it('Loads ships', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('roadmap-menu')
    cy.clickNav('roadmap-ships')

    cy.url().should('include', '/roadmap/ships')
  })

  it('Loads changes', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('roadmap-menu')
    cy.clickNav('roadmap-changes')

    cy.url().should('include', '/roadmap/changes')
  })
})
