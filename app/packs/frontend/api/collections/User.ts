import { get, put, destroy } from 'frontend/api/client'
import BaseCollection from './Base'

export class UserCollection extends BaseCollection {
  record: User | null = null

  async current(): Promise<RecordResponse<User>> {
    const response = await get('users/current')

    if (!response.error) {
      this.record = response.data
    }

    return {
      data: this.record,
      error: this.extractErrorCode(response.error),
    }
  }

  async updateProfile(form: UserForm): Promise<RecordResponse<User>> {
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

  async updateAccount(form: UserAccountForm): Promise<RecordResponse<User>> {
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

  async destroy(): Promise<RecordResponse<boolean>> {
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
