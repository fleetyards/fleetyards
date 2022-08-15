describe('Fleet', () => {
  beforeEach(() => {
    cy.visitApp('/')

    cy.acceptCookies()
  })

  it('Shows Preview', () => {
    cy.clickNav('fleets-menu')
    cy.clickNav('fleet-preview')

    cy.url().should('include', '/fleets/preview/')

    cy.selectElement('login').click()

    cy.url().should('include', '/login')

    cy.clickNav('fleets-menu')
    cy.clickNav('fleet-add')

    cy.url().should('include', '/login')

    cy.visitApp('/')

    cy.clickNav('fleets-menu')
    cy.clickNav('fleet-add')

    cy.url().should('include', '/login')
  })

  it('default workflow', () => {
    cy.clickNav('fleets-menu')
    cy.clickNav('fleet-preview')

    cy.url().should('include', '/fleets/preview/')

    cy.selectElement('login').click()

    cy.url().should('include', '/login')

    cy.clickNav('fleets-menu')
    cy.clickNav('fleet-add')

    cy.url().should('include', '/login')

    cy.visitApp('/')

    cy.clickNav('fleets-menu')
    cy.clickNav('fleet-add')

    cy.url().should('include', '/login')

    cy.login()

    cy.url().should('include', '/fleets/add/')

    cy.selectElement('input-fid').type('TestFleet1')
    cy.selectElement('input-name').type('Test Fleet 1.')

    cy.selectElement('fleet-save').click()

    cy.url().should('include', '/fleets/testfleet1/')

    cy.success('Your Fleet has been created.')

    cy.wait(500)

    cy.clickNav('fleet-settings')

    cy.selectElement('fleet-delete').click()

    cy.acceptConfirm()

    cy.wait(500)

    cy.success('Your Fleet has been destroyed.')
  })
})
