describe('Signup', () => {
  it('Allows Signup/Login/Account deletion', () => {
    cy.visit('/')

    cy.clickNav('login')

    cy.select('signup-link').click()

    cy.url().should('include', '/sign-up')

    // eslint-disable-next-line jest/valid-expect-in-promise
    cy.fixture('users').then((userData) => {
      cy.selectInput('username').type(userData.new.username)
      cy.selectInput('email').type(userData.new.email)
      cy.selectInput('password').type(userData.new.password)
      cy.selectInput('passwordConfirmation').type(userData.new.password)

      cy.get('button[type=submit]').click()

      cy.success('Welcome to FleetYards.net')

      cy.clickNav('login')

      cy.selectInput('login').type(userData.new.username)
      cy.selectInput('password').type(userData.new.password)

      cy.get('button[type=submit]').click()

      cy.location('pathname').should('eq', '/')

      cy.contains('.username', userData.new.username).click()
      cy.clickNav('settings')

      cy.url().should('include', '/settings')

      cy.selectInput('username').should('have.value', userData.new.username)
      cy.selectInput('email').should('have.value', userData.new.email)

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

    // eslint-disable-next-line jest/valid-expect-in-promise
    cy.fixture('users').then((userData) => {
      cy.selectInput('username').type(userData.test.username)
      cy.selectInput('username').parent().should('have.class', 'has-error')

      cy.selectInput('email').type('foo').clear()
      cy.selectInput('email').parent().should('have.class', 'has-error')

      cy.selectInput('password').type('bar')
      cy.selectInput('password').parent().should('have.class', 'has-error')
      cy.selectInput('password').clear().type(userData.test.password)
      cy.selectInput('password').parent().should('not.have.class', 'has-error')

      cy.selectInput('passwordConfirmation').type('bar').clear()
      cy.selectInput('passwordConfirmation').parent().should('have.class', 'has-error')
      cy.selectInput('passwordConfirmation').type(userData.test.password)
      cy.selectInput('passwordConfirmation').parent().should('not.have.class', 'has-error')

      cy.get('button[type=submit]').click()
    })
  })

  it('Validates all fields on submit', () => {
    cy.visit('/sign-up')

    cy.get('button[type=submit]').click()

    cy.selectInput('username').parent().should('have.class', 'has-error')
    cy.selectInput('email').parent().should('have.class', 'has-error')
    cy.selectInput('password').parent().should('have.class', 'has-error')
    cy.selectInput('passwordConfirmation').parent().should('have.class', 'has-error')
  })
})
