describe('Footer', () => {
  it('Is present', () => {
    cy.visit('/')

    cy.get('.app-footer').should('be.visible')
  })
})
