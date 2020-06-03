describe('Starsystems', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('stations-menu')
    cy.clickNav('starsystems')

    cy.url().should('include', '/starsystems')
  })
})
