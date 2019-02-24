import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Stats', '/')

test('Loads', async (t) => {
  await t.click(Selector('.nav-toggle'))
    .click(Selector('nav a').withText('Stats')).expect(
      Selector('.panel', { visibilityCheck: true }).count,
    ).eql(5)
})
