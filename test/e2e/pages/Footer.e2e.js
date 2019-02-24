import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Footer', '/')

test('Is Present', async (t) => {
  await t.expect(
    Selector('.app-footer', { visibilityCheck: true }).exists,
  ).ok()
})
