describe('Signup', () => {
  it('Allows Signup/Login/Account deletion', () => {
    cy.visit('/')

    cy.clickNav('Sign up')

    cy.url().should('include', '/sign-up')

    cy.fixture('users').then((userData) => {
      cy.select('username').type(userData.new.username)
      cy.select('rsi-handle').type(userData.new.handle)
      cy.select('email').type(userData.new.email)
      cy.select('password').type(userData.new.password)
      cy.select('password-confirmation').type(userData.new.password)

      cy.get('button[type=submit]').click()

      cy.success('Welcome to FleetYards.net')

      cy.clickNav('Login')

      cy.select('login').type(userData.new.username)
      cy.select('password').type(userData.new.password)

      cy.get('button[type=submit]').click()

      cy.location('pathname').should('eq', '/')

      cy.get('.nav-toggle').click()
      cy.contains('.username', userData.new.username).click()
      cy.clickNav('Settings', false)

      cy.url().should('include', '/settings')

      cy.select('username').should('have.value', userData.new.username)
      cy.select('email').should('have.value', userData.new.email)
      cy.select('rsi-handle').should('have.value', userData.new.handle)

      cy.get('.tabs a').contains('Account').click()

      cy.url().should('include', '/settings/account')

      cy.get('button').contains('Destroy').click()

      cy.acceptConfirm()

      cy.location('pathname').should('eq', '/')

      cy.success('Your Account has been destroyed')

      cy.get('nav a').contains('nav a', 'Login').should('exist')
    })
  })

  it('Validates all fields', () => {
    cy.visit('/sign-up')

    cy.fixture('users').then((userData) => {
      cy.select('username').type(userData.test.username)
      cy.select('username').parent().should('have.class', 'has-error')

      cy.select('email').type('foo').clear()
      cy.select('email').parent().should('have.class', 'has-error')

      cy.select('password').type('bar')
      cy.select('password').parent().should('have.class', 'has-error')
      cy.select('password').clear().type(userData.test.password)
      cy.select('password').parent().should('not.have.class', 'has-error')

      cy.select('rsi-handle').type('torle')
      cy.select('rsi-handle').parent().should('have.class', 'has-error')
      cy.select('rsi-handle').clear().type('torlekmaru')
      cy.select('rsi-handle').parent().should('not.have.class', 'has-error')

      cy.select('password-confirmation').parent().should('have.class', 'has-error')
      cy.select('password-confirmation').type(userData.test.password)
      cy.select('password-confirmation').parent().should('not.have.class', 'has-error')

      cy.get('button[type=submit]').click()

      cy.alert('Please resolve the errors')
    })
  })

  it('Validates all fields on submit', () => {
    cy.visit('/sign-up')

    cy.get('button[type=submit]').click()

    cy.select('username').parent().should('have.class', 'has-error')
    cy.select('email').parent().should('have.class', 'has-error')
    cy.select('password').parent().should('have.class', 'has-error')
    cy.select('password-confirmation').parent().should('have.class', 'has-error')

    cy.alert('Please resolve the errors')
  })
})
