import util from 'util'
import looksSameLib from 'looks-same'

const looksSame = util.promisify(looksSameLib)

// eslint-disable-next-line import/prefer-default-export
export const compareScreenshot = async (name) => {
  const testImage = `test/e2e/screenshots/${name}.png`
  const baseImage = `test/e2e/fixtures/screenshots/${name}.png`
  const response = await looksSame(
    baseImage,
    testImage,
    { tolerance: 5 },
  )

  if (!response.equal) {
    await looksSame.createDiff({
      reference: baseImage,
      current: testImage,
      diff: `test/e2e/screenshots/${name}-diff.png`,
      highlightColor: '#ff00ff',
      tolerance: 5,
    })

    throw new Error('Screenshot compare failed!')
  }
}
