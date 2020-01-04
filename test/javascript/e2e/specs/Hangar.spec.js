describe('Hangar', () => {
  it('Shows Preview', () => {
    cy.visit('/')

    cy.clickNav('Hangar')

    cy.url().should('include', '/hangar/preview/')

    cy.select('login').click()

    cy.url().should('include', '/login')

    cy.clickNav('Hangar')

    cy.url().should('include', '/login')

    cy.visit('/')

    cy.clickNav('Hangar')

    cy.url().should('include', '/login')
  })

  it('Shows Guide on initial Visit', () => {
    cy.visit('/')

    cy.clickNav('Hangar')

    cy.select('login').click()

    cy.login()

    cy.url().should('include', '/hangar/')

    cy.get('.hangar-guide-box').should('exist')
  })

  it.only('Shows Added Ships', () => {
    cy.visit('/')

    cy.clickNav('Login')

    cy.login()

    cy.url().should('include', '/')

    cy.clickNav('Ships')

    cy.url().should('include', '/ships/')

    cy.addToHangar('300i')

    cy.clickNav('Hangar')

    cy.get('.model-panel .panel-title a').contains('300i').should('exist')

    cy.select('vehicle-edit').first().click()

    cy.select('vehicle-delete').first().click()

    cy.acceptConfirm()

    cy.get('.model-panel').should('have.length', 0)
  })
})
