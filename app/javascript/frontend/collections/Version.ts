import { get } from 'frontend/lib/ApiClient'

export class VersionCollection {
  record: Version | null = null

  async current(): Promise<Version | null> {
    const response = await get('version', {}, true)

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new VersionCollection()
