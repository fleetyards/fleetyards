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
