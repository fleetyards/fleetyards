import { get } from '@/frontend/api/client'

export class PublicUserCollection {
  record = null

  async findByUsername(username) {
    const response = await get(`users/${username}`)

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new PublicUserCollection()
