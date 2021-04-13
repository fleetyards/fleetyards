import { post, destroy } from 'frontend/api/client'

export class SessionCollection {
  record: Session | null = null

  create(params: SessionParams): Promise<any> {
    return post('sessions', params, true)
  }

  async destroy(): Promise<boolean> {
    const response = await destroy('sessions')

    if (!response.error) {
      return true
    }

    return false
  }

  async confirmAccess(password): Promise<boolean> {
    const response = await post('sessions/confirm-access', {
      password,
    })

    if (!response.error) {
      return true
    }

    return false
  }
}

export default new SessionCollection()
