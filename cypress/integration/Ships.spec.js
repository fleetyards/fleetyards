describe('Ships', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.get('.nav-toggle').click()
    cy.get('nav a').contains('Ships').click()

    cy.url().should('include', '/ships')

    cy.get('.panel-title a span').contains('100i').should('exist')

    cy.get('.panel').should('have.length', 30)
  })
})
