describe('Footer', () => {
  it('Is present', () => {
    cy.visit('/')

    cy.acceptCookies()

    cy.get('.app-footer').should('be.visible')
  })
})
