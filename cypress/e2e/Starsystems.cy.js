describe('Starsystems', () => {
  it('Loads', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('stations-menu')
    cy.clickNav('starsystems')

    cy.url().should('include', '/starsystems')
  })
})
