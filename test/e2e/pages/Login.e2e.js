import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Login', '/')

test('Loads', async (t) => {
  await t.click(Selector('.nav-toggle'))
    .click(Selector('nav a').withText('Login'))
    .typeText('input#login', 'TestUser')
    .click(Selector('button[type=submit]'))
})
