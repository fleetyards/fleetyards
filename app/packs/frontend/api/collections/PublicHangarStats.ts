import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class PublicHangarStatsCollection extends BaseCollection {
  async quickStats(username: string): Promise<HangarStats | null> {
    const response = await get(`vehicles/${username}/quick-stats`)

    if (!response.error) {
      return response.data
    }

    return null
  }

  async modelsByClassification(username: string): Promise<any[]> {
    const response = await get(
      `vehicles/${username}/stats/models-by-classification`,
    )

    if (!response.error) {
      return response.data
    }

    return []
  }

  async modelsBySize(username: string): Promise<any[]> {
    const response = await get(`vehicles/${username}/stats/models-by-size`)

    if (!response.error) {
      return response.data
    }

    return []
  }

  async modelsByManufacturer(username: string): Promise<any[]> {
    const response = await get(
      `vehicles/${username}/stats/models-by-manufacturer`,
    )

    if (!response.error) {
      return response.data
    }

    return []
  }

  async modelsByProductionStatus(username: string): Promise<any[]> {
    const response = await get(
      `vehicles/${username}/stats/models-by-production-status`,
    )

    if (!response.error) {
      return response.data
    }

    return []
  }
}

export default new PublicHangarStatsCollection()
