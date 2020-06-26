import { post, put, destroy } from 'frontend/lib/ApiClient'

export class SessionCollection {
  record: Session | null = null

  async renew(): Promise<Session | null> {
    const response = await put('sessions/renew')

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }

  async create(params: SessionParams): Promise<any> {
    const response = await post('sessions', params)

    if (!response.error) {
      this.record = response.data
    }

    return response
  }

  async destroy(): Promise<boolean> {
    const response = await destroy('sessions')

    if (!response.error) {
      return true
    }

    return false
  }
}

export default new SessionCollection()
