import { put } from 'frontend/lib/ApiClient'

export class SessionCollection {
  record: Session | null = null

  async renew(): Promise<Session | null> {
    const response = await put('sessions/renew')

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new SessionCollection()
