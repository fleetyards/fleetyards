describe('Roadmap', () => {
  it('Loads overview', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('roadmap')

    cy.url().should('include', '/roadmap')

    cy.get('.roadmap-item').should('have.length.of.at.least', 1)
  })

  it('Loads ships', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('roadmap')
    cy.clickNav('roadmap-ships')

    cy.url().should('include', '/roadmap/ships')
  })

  it('Loads changes', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('roadmap')
    cy.clickNav('roadmap-changes')

    cy.url().should('include', '/roadmap/changes')
  })
})
