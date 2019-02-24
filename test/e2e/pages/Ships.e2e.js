import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Ships', '/')

test('Loads', async (t) => {
  await t.click(Selector('.nav-toggle'))
    .click(Selector('nav a').withText('Ships')).expect(
      Selector('.panel-title a span', { visibilityCheck: true }).withText('100i').exists,
    ).ok()
})
