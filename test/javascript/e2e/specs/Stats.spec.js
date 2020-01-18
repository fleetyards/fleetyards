describe('Stats', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.clickNav('stats')

    cy.url().should('include', '/stats')

    cy.get('.stats').should('exist')
  })
})
