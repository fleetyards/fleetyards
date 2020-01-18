describe('Stats', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('stats')

    cy.url().should('include', '/stats')

    cy.get('.stats').should('exist')
  })
})
