describe('Hangar', () => {
  beforeEach(() => {
    cy.visit('/')

    cy.acceptCookies()
  })

  it('Shows Preview', () => {
    cy.clickNav('hangar-preview')

    cy.url().should('include', '/hangar/preview/')

    cy.select('login').click()

    cy.url().should('include', '/login')

    cy.clickNav('hangar')

    cy.url().should('include', '/login')

    cy.visit('/')

    cy.clickNav('hangar')

    cy.url().should('include', '/login')
  })

  it('Default Workflow', () => {
    cy.clickNav('login')

    cy.login()

    cy.url().should('include', '/')

    cy.clickNav('models')

    cy.url().should('include', '/ships/')

    cy.addToHangar('300i')

    cy.clickNav('hangar')

    cy.get('.model-panel .panel-title a')
      .contains('300i')
      .should('exist')

    cy.openShipModal('300i')

    cy.select('input-vehicle-name').type('Enterprise')

    cy.saveShip()

    cy.get('.model-panel .panel-title a')
      .contains('Enterprise')
      .should('exist')

    cy.openShipModal('300i')

    cy.deleteShip()

    cy.acceptConfirm()

    cy.get('.model-panel').should('have.length', 0)
  })
})
