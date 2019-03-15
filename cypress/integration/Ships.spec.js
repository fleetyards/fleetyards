describe('Ships', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('Ships')

    cy.url().should('include', '/ships')

    cy.get('.panel-title a span').contains('100i').should('exist')

    cy.get('.panel').should('have.length', 30)
  })
})
