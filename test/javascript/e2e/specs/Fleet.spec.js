describe('Fleet', () => {
  it('Shows Preview', () => {
    cy.visit('/')

    cy.clickNav('Fleets')
    cy.clickNav('Create a new Fleet')

    cy.url().should('include', '/fleets/preview/')

    cy.select('login').click()

    cy.url().should('include', '/login')

    cy.clickNav('Fleets')
    cy.clickNav('Create a new Fleet')

    cy.url().should('include', '/login')

    cy.visit('/')

    cy.clickNav('Fleets')
    cy.clickNav('Create a new Fleet')

    cy.url().should('include', '/login')
  })
})
