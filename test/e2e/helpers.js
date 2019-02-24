import { host } from './config'

// eslint-disable-next-line import/prefer-default-export
export const visitPage = async (page, path) => {
  fixture(page).page(`${host}${path}`)
}
