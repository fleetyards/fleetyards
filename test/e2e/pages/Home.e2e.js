import { Selector } from 'testcafe'
import { visitPage, screenshotPath } from '../helpers'
import { compareScreenshot } from '../compareScreenshots'

visitPage('Home', '/')

test('Loads', async (t) => {
  const path = screenshotPath('home')

  await t.expect(
    Selector('#home-welcome', { visibilityCheck: true }).exists,
  ).ok()
    .expect(
      Selector('.home-scroll-to-more', { visibilityCheck: true }).exists,
    ).ok()
    .takeScreenshot(path)

  await compareScreenshot('home')
})

test('Search', async (t) => {
  await t.typeText('input[name=search]', '600i')
    .click(Selector('#search-submit'))
    .expect(
      Selector('.panel .panel-title'),
    )
    .ok()
    .expect(
      Selector('.panel .panel-title').textContent,
    )
    .contains('600i Explorer')
})

test('Latest Ships', async (t) => {
  const path = screenshotPath('home-ships')

  await t.expect(
    Selector('.home-ships', { visibilityCheck: true }).exists,
  ).ok().expect(
    Selector('.home-ships .model-panel').count,
  ).eql(9)
    .wait(1000)
    .takeElementScreenshot('.home-ships', path)

  await compareScreenshot('home-ships')
})

test('Random Images', async (t) => {
  const path = screenshotPath('home-images')

  await t.expect(
    Selector('.home-images', { visibilityCheck: true }).exists,
  ).ok().expect(
    Selector('.home-images .image', { visibilityCheck: true }).count,
  ).eql(16)
    .wait(1000)
    .takeElementScreenshot('.home-images', path)

  await compareScreenshot('home-images')
})
