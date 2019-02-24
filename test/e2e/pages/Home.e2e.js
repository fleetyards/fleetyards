import { Selector } from 'testcafe'
import { visitPage } from '../helpers'

visitPage('Home', '/')

test('Loads', async (t) => {
  await t.expect(
    Selector('#home-welcome', { visibilityCheck: true }).exists,
  ).ok()
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
  await t.expect(
    Selector('.home-ships', { visibilityCheck: true }).exists,
  ).ok().expect(
    Selector('.home-ships .model-panel').count,
  ).eql(9)
})

test('Random Images', async (t) => {
  await t.expect(
    Selector('.home-images', { visibilityCheck: true }).exists,
  ).ok().expect(
    Selector('.home-images .image', { visibilityCheck: true }).count,
  ).eql(16)
})
