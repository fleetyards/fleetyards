import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Images', '/')

test('Loads', async (t) => {
  await t.click(Selector('.nav-toggle'))
    .click(Selector('nav a').withText('Images')).expect(
      Selector('.images a', { visibilityCheck: true }).count,
    ).eql(16)
})
