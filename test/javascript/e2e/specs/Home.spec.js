describe('Home', () => {
  beforeEach(() => {
    cy.visit('/')
  })

  it('Loads', () => {
    cy.contains('Welcome')
  })

  it('Shows Search Results via Button', () => {
    cy.selectInput('home-search').type('600i')

    cy.get('#search-submit').click()

    cy.url().should('include', '/ships')

    cy.get('.panel .panel-title').should('contain', '600i Explorer')
  })

  it('Shows Search Results via Key', () => {
    cy.selectInput('home-search').type('600i Touring{enter}')

    cy.url().should('include', '/ships')

    cy.get('.panel .panel-title').should('contain', '600i Touring')
  })

  it('Shows Latest Ships', () => {
    cy.get('.home-ships .teaser-panel').should('have.length', 9)
  })

  it('Shows Random Images', () => {
    cy.get('.home-images .image').should('have.length', 16)
  })
})
