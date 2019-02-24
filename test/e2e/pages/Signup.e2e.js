import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Signup', '/')

test('Loads', async (t) => {
  await t.click(Selector('.nav-toggle'))
    .click(Selector('nav a').withText('Sign up'))
    .typeText('input#username', 'TestUser')
    .click(Selector('button[type=submit]'))
})
