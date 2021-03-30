describe('Ship', () => {
  it('Loads', () => {
    cy.visit('/ships')

    cy.acceptCookies()

    cy.get('.panel-title a span')
      .contains('100i')
      .click()

    cy.url().should('include', '/ships/100i')

    cy.get('h1').should($h1 => {
      expect($h1).to.contain('100i')
    })

    cy.select('model-dropdown').click()
    cy.select('compare').click()

    cy.url().should('include', '/compare/?models%5B%5D=100i')
  })
})
