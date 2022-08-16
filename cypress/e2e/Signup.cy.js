describe('Signup', () => {
  it('Allows Signup/Login/Account deletion', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('login')

    cy.selectElement('signup-link').click()

    cy.url().should('include', '/sign-up')

    cy.fixture('users').then((userData) => {
      cy.selectInput('username').type(userData.new.username)
      cy.selectInput('email').type(userData.new.email)
      cy.selectInput('password').type(userData.new.password)
      cy.selectInput('passwordConfirmation').type(userData.new.password)

      cy.selectElement('submit-signup').click()

      cy.success('Welcome to FleetYards.net')

      cy.clickNav('login')

      cy.selectInput('login').type(userData.new.username)
      cy.selectInput('password').type(userData.new.password)

      cy.selectElement('submit-login').click()

      cy.location('pathname').should('eq', '/')

      cy.contains('.user-menu', userData.new.username).click()
      cy.clickNav('settings')

      cy.url().should('include', '/settings')

      cy.get('.tabs a').contains('Account').click()

      cy.url().should('include', '/settings/account')

      cy.confirmAccess(userData.new.password)

      cy.selectInput('username').should('have.value', userData.new.username)
      cy.selectInput('email').should('have.value', userData.new.email)

      cy.selectElement('destroy-account').click()

      cy.acceptConfirm()

      cy.location('pathname').should('eq', '/')

      cy.success('Your Account has been destroyed')

      cy.get('nav a').contains('nav a', 'Login').should('exist')
    })
  })

  it('Validates all fields', () => {
    cy.visitApp('/sign-up')

    cy.acceptCookies()

    cy.fixture('users').then((userData) => {
      cy.selectInput('username').type(userData.test.username)
      cy.selectInput('username')
        .parents('.form-input')
        .should('have.class', 'has-error')

      cy.selectInput('email').type('foo').clear()
      cy.selectInput('email')
        .parents('.form-input')
        .should('have.class', 'has-error')

      cy.selectInput('password').type('bar')
      cy.selectInput('password')
        .parents('.form-input')
        .should('have.class', 'has-error')
      cy.selectInput('password').clear().type(userData.test.password)
      cy.selectInput('password')
        .parents('.form-input')
        .should('not.have.class', 'has-error')

      cy.selectInput('passwordConfirmation').type('bar').clear()
      cy.selectInput('passwordConfirmation')
        .parents('.form-input')
        .should('have.class', 'has-error')
      cy.selectInput('passwordConfirmation').type(userData.test.password)
      cy.selectInput('passwordConfirmation')
        .parents('.form-input')
        .should('not.have.class', 'has-error')

      cy.selectElement('submit-signup').click()
    })
  })

  it('Validates all fields on submit', () => {
    cy.visitApp('/sign-up')

    cy.acceptCookies()

    cy.selectElement('submit-signup').click()

    cy.selectInput('username')
      .parents('.form-input')
      .should('have.class', 'has-error')
    cy.selectInput('email')
      .parents('.form-input')
      .should('have.class', 'has-error')
    cy.selectInput('password')
      .parents('.form-input')
      .should('have.class', 'has-error')
    cy.selectInput('passwordConfirmation')
      .parents('.form-input')
      .should('have.class', 'has-error')
  })
})
