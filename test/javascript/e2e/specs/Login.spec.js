describe('Login', () => {
  it('Loads and excepts valid credentials', () => {
    cy.visit('/')

    cy.clickNav('Login')

    cy.url().should('include', '/login')

    // eslint-disable-next-line jest/valid-expect-in-promise
    cy.fixture('users').then((userData) => {
      cy.select('login').type(userData.test.username)
      cy.select('password').type(userData.test.password)

      cy.get('button[type=submit]').click()

      cy.location('pathname').should('eq', '/')

      cy.contains('.username', userData.test.username).click()
      cy.clickNav('Logout')

      cy.contains('nav a', 'Login').should('exist')

      cy.location('pathname').should('eq', '/')
    })
  })

  it('Shows error message with wrong credentails', () => {
    cy.visit('/login')

    cy.url().should('include', '/login')

    cy.select('login').type('invalidUsername')
    cy.select('password').type('invalidPassword')

    cy.get('button[type=submit]').click()

    cy.alert('Invalid email or password')
  })

  it('Redirects to login when visiting restricted page', () => {
    cy.visit('/settings')

    cy.url().should('include', '/login')

    // eslint-disable-next-line jest/valid-expect-in-promise
    cy.fixture('users').then((userData) => {
      cy.select('login').type(userData.test.username)
      cy.select('password').type(userData.test.password)

      cy.get('button[type=submit]').click()

      cy.url().should('include', '/settings')
    })
  })
})
