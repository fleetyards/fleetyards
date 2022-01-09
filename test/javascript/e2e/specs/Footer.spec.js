describe('Footer', () => {
  it('Is present', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.get('.app-footer').should('be.visible')
  })
})
