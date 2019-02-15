describe('The Home Page', () => {
  it('loads successfully', () => {
    cy.visit('/')

    cy.get('button.nav-toggle').should('exist')

    cy.contains('Welcome to')

    cy.get('input[name=search]').should('exist')
    cy.get('button[aria-label=Search]').should('exist')

    cy.get('.home-ships .panel').should('have.length', 9)
    cy.get('.home-images a.image').should('have.length', 16)
  })

  it('submits search via input', () => {
    cy.visit('/')

    cy.get('input[name=search]')
      .type('600i').should('have.value', '600i')

    cy.get('input[name=search]').type('{enter}')

    cy.location('pathname').should('include', 'ships')

    cy.contains('600i')
  })

  it('submits search via button', () => {
    cy.visit('/')

    cy.get('input[name=search]')
      .type('600i').should('have.value', '600i')

    cy.get('button[aria-label=Search]').click()

    cy.location('pathname').should('include', 'ships')

    cy.contains('600i')
  })
})
