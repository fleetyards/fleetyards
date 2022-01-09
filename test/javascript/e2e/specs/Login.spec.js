describe('Login', () => {
  it('Loads and excepts valid credentials', () => {
    cy.visitApp('/')

    cy.acceptCookies()

    cy.clickNav('login')

    cy.url().should('include', '/login')

    // eslint-disable-next-line jest/valid-expect-in-promise
    cy.fixture('users').then(userData => {
      cy.selectInput('login').type(userData.test.username)
      cy.selectInput('password').type(userData.test.password)

      cy.selectElement('submit-login').click()

      cy.location('pathname').should('eq', '/')

      cy.contains('.username', userData.test.username).click()
      cy.clickNav('logout')

      cy.contains('nav a', 'Login').should('exist')

      cy.location('pathname').should('eq', '/')
    })
  })

  it('Shows error message with wrong credentails', () => {
    cy.visitApp('/login')

    cy.acceptCookies()

    cy.url().should('include', '/login')

    cy.selectInput('login').type('invalidUsername')
    cy.selectInput('password').type('invalidPassword')

    cy.selectElement('submit-login').click()

    cy.alert('Invalid email or password')
  })

  it('Redirects to login when visiting restricted page', () => {
    cy.visitApp('/settings')

    cy.acceptCookies()

    cy.url().should('include', '/login')

    // eslint-disable-next-line jest/valid-expect-in-promise
    cy.fixture('users').then(userData => {
      cy.selectInput('login').type(userData.test.username)
      cy.selectInput('password').type(userData.test.password)

      cy.selectElement('submit-login').click()

      cy.url().should('include', '/settings')
    })
  })
})
