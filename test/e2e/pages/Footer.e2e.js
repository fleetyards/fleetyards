import { Selector } from 'testcafe'
import { visitPage } from '../helpers'
import { compareScreenshot } from '../compareScreenshots'

visitPage('Footer', '/')

test('Is Present', async (t) => {
  await t.expect(
    Selector('.app-footer', { visibilityCheck: true }).exists,
  ).ok()
    .takeElementScreenshot('.app-footer .app-footer-inner', 'footer.png')
    .click(Selector('.app-footer a').nth(0))

  await compareScreenshot('footer')
})
