import { post } from '@/frontend/api/client'
import BaseCollection from './Base'

export class TwoFactorCollection extends BaseCollection {
  async generateBackupCodes() {
    const response = await post('users/two-factor/generate-backup-codes')

    if (!response.error) {
      return {
        data: response.data,
        error: null,
      }
    }

    return {
      data: null,
      error: this.extractErrorCode(response.error),
    }
  }

  async enable(code) {
    const response = await post('users/two-factor/enable', {
      twoFactorCode: code,
    })

    if (!response.error) {
      return {
        data: response.data,
        error: null,
      }
    }

    return {
      data: null,
      error: this.extractErrorCode(response.error),
    }
  }

  async disable(code) {
    const response = await post('users/two-factor/disable', {
      twoFactorCode: code,
    })

    if (!response.error) {
      return {
        data: true,
        error: null,
      }
    }

    return {
      data: false,
      error: this.extractErrorCode(response.error),
    }
  }
}
export default new TwoFactorCollection()
