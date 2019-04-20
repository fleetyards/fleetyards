describe('Stats', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('Stats')

    cy.url().should('include', '/stats')

    cy.get('.stats').should('exist')
  })
})
