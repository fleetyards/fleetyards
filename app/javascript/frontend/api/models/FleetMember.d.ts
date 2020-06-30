type FleetMember = {
  id: string
  username: string
}

type FleetMembersFilter = {
  usernameCont: string
  roleIn: string[]
}

interface FleetMembersParams extends CollectionParams {
  slug: string
  filters: FleetMembersFilter
}

type FleetMemberMetrics = {
  totalAdmins: number
  totalOfficers: number
  totalMembers: number
}

type FleetMemberStats = {
  total: number
  metrics: FleetMemberMetrics
}
