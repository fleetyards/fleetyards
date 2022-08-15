describe('Stats', () => {
  it('Loads', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('stats')

    cy.url().should('include', '/stats')

    cy.get('.stats').should('exist')
  })
})
