import { get, put, destroy } from '@/frontend/api/client'
import BaseCollection from './Base'

export class UserCollection extends BaseCollection {
  record = null

  async current() {
    const response = await get('users/current')

    if (!response.error) {
      this.record = response.data
    }

    return {
      data: this.record,
      error: this.extractErrorCode(response.error),
    }
  }

  async updateProfile(form) {
    const response = await put('users/current', form)

    if (!response.error) {
      return {
        data: response.data,
      }
    }

    return {
      error: this.extractErrorCode(response.error),
    }
  }

  async updateAccount(form) {
    const response = await put('users/current-account', form)

    if (!response.error) {
      return {
        data: response.data,
      }
    }

    return {
      error: this.extractErrorCode(response.error),
    }
  }

  async destroy() {
    const response = await destroy('users/current')

    if (!response.error) {
      return {
        data: true,
      }
    }

    return {
      error: this.extractErrorCode(response.error),
    }
  }
}

export default new UserCollection()
