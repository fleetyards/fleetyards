import { host } from './config'

const system = process.env.CI ? 'ci/' : ''

export const screenshotPath = (name, diff = false) => {
  if (diff) {
    return `${system}${name}-diff.png`
  }

  return `${system}${name}.png`
}

export const visitPage = async (page, path) => fixture(page).page(`${host}${path}`)
