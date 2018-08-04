import mountVM from './helpers/mountVM'

jest.mock('@lib/Store/plugins')

global.mountVM = mountVM
