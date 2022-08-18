describe('Images', () => {
  it('Loads', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('images')

    cy.url().should('include', '/images')

    cy.get('.images a').should('have.length.of.at.least', 20)
  })
})
