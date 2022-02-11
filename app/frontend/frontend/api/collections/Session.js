import { post, destroy } from '@/frontend/api/client'

export class SessionCollection {
  record = null

  create(params) {
    return post('sessions', params, true)
  }

  async destroy() {
    const response = await destroy('sessions')

    if (!response.error) {
      return true
    }

    return false
  }

  async confirmAccess(password) {
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
