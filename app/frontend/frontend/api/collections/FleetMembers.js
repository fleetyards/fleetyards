import { get, post, put } from '@/frontend/api/client'
import BaseCollection from './Base'

export class FleetMembersCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  record = null

  stats = null

  params = null

  async findAll(params) {
    const response = await get(`fleets/${params?.slug}/members`, {
      page: params?.page,
      q: params?.filters,
    })

    this.params = params

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findStats(params) {
    const response = await get(`fleets/${params?.slug}/member-quick-stats`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.stats = response.data
    }

    return this.stats
  }

  async findByFleet(slug) {
    const response = await get(`fleets/${slug}/members/current`)

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }

  async create(slug, form, refetch = false) {
    const response = await post(`fleets/${slug}/members`, form)

    if (!response.error) {
      if (refetch) {
        this.findAll(this.params)
      }

      return {
        data: response.data,
        error: null,
      }
    }

    return {
      data: null,
      error: this.extractErrorCode(response.error),
    }
  }

  async acceptRequest(slug, username, refetch = false) {
    const response = await put(
      `fleets/${slug}/members/${username}/accept-request`
    )

    if (!response.error) {
      if (refetch) {
        this.findAll(this.params)
      }

      return response.data
    }

    return null
  }

  async declineRequest(slug, username, refetch = false) {
    const response = await put(
      `fleets/${slug}/members/${username}/decline-request`
    )

    if (!response.error) {
      if (refetch) {
        this.findAll(this.params)
      }

      return response.data
    }

    return null
  }
}

export default new FleetMembersCollection()
