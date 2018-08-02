import { Selector } from 'testcafe'

fixture('Home').page(global.baseUrl)

test('Searches for Origin', async (t) => {
  await t
    .typeText('input[name="search"]', 'Origin')
    .click('.btn-default')
    .expect(Selector('.panel-title a').innerText).eql('300i')
})
