import util from 'util'
import looksSameLib from 'looks-same'
import { screenshotPath } from './helpers'

const looksSame = util.promisify(looksSameLib)

// eslint-disable-next-line import/prefer-default-export
export const compareScreenshot = async (name) => {
  const path = screenshotPath(name)
  const diffPath = screenshotPath(name, true)

  const testImage = `test/e2e/screenshots/${path}`
  const baseImage = `test/e2e/fixtures/screenshots/${path}`
  const response = await looksSame(
    baseImage,
    testImage,
    { tolerance: 5 },
  )

  if (!response.equal) {
    await looksSame.createDiff({
      reference: baseImage,
      current: testImage,
      diff: `test/e2e/screenshots/${diffPath}`,
      highlightColor: '#ff00ff',
      tolerance: 5,
    })

    throw new Error('Screenshot compare failed!')
  }
}
