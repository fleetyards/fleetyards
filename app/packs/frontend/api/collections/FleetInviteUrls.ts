import { get, post, destroy } from 'frontend/api/client'
import BaseCollection from './Base'

export class FleetInviteUrlsCollection extends BaseCollection {
  primaryKey: string = 'token'

  records: FleetInviteUrl[] = []

  params: FleetInviteUrlParams | null = null

  async findAll(
    params: FleetInviteUrlParams | null
  ): Promise<FleetInviteUrl[]> {
    const response = await get(`fleets/${params?.fleetSlug}/invite-urls/`)

    this.params = params

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async checkToken(fleetSlug: string, token: string): Promise<boolean> {
    const response = await get(
      `fleets/${fleetSlug}/invite-urls/${token}/exists`
    )

    if (!response.error) {
      return true
    }

    return false
  }

  async findByToken(
    fleetSlug: string,
    token: string
  ): Promise<FleetInviteUrl | null> {
    const response = await get(`fleets/${fleetSlug}/invite-urls/${token}`)

    if (!response.error) {
      return response.data
    }

    return null
  }

  async create(form: InviteUrlForm, refetch: boolean = false) {
    const response = await post(`fleets/${form.fleetSlug}/invite-urls`, form)

    if (!response.error) {
      if (refetch) {
        this.findAll(this.params)
      }

      return response.data
    }

    return null
  }

  async destroy(fleetSlug: string, token: string, refetch: boolean = false) {
    const response = await destroy(`fleets/${fleetSlug}/invite-urls/${token}`)

    if (!response.error) {
      if (refetch) {
        this.findAll(this.params)
      }

      return response.data
    }

    return null
  }
}

export default new FleetInviteUrlsCollection()
