import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Ship', '/ships')

test('Loads', async (t) => {
  await t.click(Selector('.panel-title a span').withText('100i')).expect(
    Selector('h1', { visibilityCheck: true }).withText('100i').exists,
  ).ok()
})
