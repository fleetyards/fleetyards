describe('Ships', () => {
  it('Loads', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('models-menu')
    cy.clickNav('models')

    cy.url().should('include', '/ships')

    cy.get('.model-panel').should('have.length', 30)

    cy.get('.model-panel .panel-title a span')
      .contains('100i')
      .should('exist')
  })
})
