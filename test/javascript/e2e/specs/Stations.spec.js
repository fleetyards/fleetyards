describe('Stations', () => {
  it('Loads', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('stations-menu')
    cy.clickNav('stations')

    cy.url().should('include', '/stations')

    cy.get('.station-panel').should('have.length.of.at.least', 1)
  })
})
