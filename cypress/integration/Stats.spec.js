describe('Stats', () => {
  it('Loads', () => {
    cy.visit('/')

    cy.get('.nav-toggle').click()
    cy.get('nav a').contains('Stats').click()

    cy.url().should('include', '/stats')

    cy.get('.stats').should('exist')
  })
})
