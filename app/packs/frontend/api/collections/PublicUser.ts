import { get } from 'frontend/api/client'

export class PublicUserCollection {
  record: User | null = null

  async findByUsername(username: string): Promise<User | null> {
    const response = await get(`users/${username}`)

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new PublicUserCollection()
