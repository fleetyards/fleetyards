import { Selector } from 'testcafe'
import { visitPage, screenshotPath } from '../helpers'
import { compareScreenshot } from '../compareScreenshots'

visitPage('Footer', '/')

test('Is Present', async (t) => {
  const path = screenshotPath('footer')

  await t.expect(
    Selector('.app-footer', { visibilityCheck: true }).exists,
  ).ok()
    .takeElementScreenshot('.app-footer .app-footer-inner', path)
    .click(Selector('.app-footer a').nth(0))

  await compareScreenshot('footer')
})
