describe('Ships', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.clickNav('models')

    cy.url().should('include', '/ships')

    cy.get('.model-panel .panel-title a span').contains('100i').should('exist')

    cy.get('.model-panel').should('have.length', 30)
  })
})
