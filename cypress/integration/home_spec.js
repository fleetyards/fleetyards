describe('The Home Page', () => {
  it('successfully loads', () => {
    cy.visit('/')

    cy.contains('Welcome to')
    cy.contains('Welcome to')
  })
})
