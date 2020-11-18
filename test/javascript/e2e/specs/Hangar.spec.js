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

    cy.clickNav('models-menu')
    cy.clickNav('models')

    cy.url().should('include', '/ships/')

    cy.addToHangar('300i')

    cy.clickNav('hangar')

    cy.get('.model-panel-300i .panel-title a')
      .first()
      .contains('300i')
      .should('exist')

    cy.openShipModal('300i')

    cy.select('input-vehicle-name')
      .clear()
      .type('Enterprise')

    cy.saveShip()

    cy.get('.model-panel-300i .panel-title a')
      .first()
      .contains('Enterprise')
      .should('exist')

    cy.select('fleetchart-link').click()

    cy.url().should('include', '/fleetchart/')

    cy.openContextMenu('300i')

    cy.openShipModalFromContext()

    cy.deleteShip()

    cy.acceptConfirm()

    cy.get('.fleetchart-item').should('have.length', 0)
  })
})
