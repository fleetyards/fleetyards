type FleetMember = {
  id: string;
  username: string;
  rsiHandle: string;
  avatar: string;
  role: string;
  status: string;
  roleLabel: string;
  invitedAtLabel: string;
  declinedAtLabel: string;
  requestedAtLabel: string;
  acceptedAtLabel: string;
  homepage: string;
  youtube: string;
  twitch: string;
  guilded: string;
  discord: string;
};

type FleetMemberForm = {
  username: string;
};

type FleetMemberInviteForm = {
  token: string;
  username: string;
};

type FleetMembersFilter = {
  usernameCont: string;
  roleIn: string[];
};

interface FleetMembersParams extends CollectionParams {
  slug: string;
  filters: FleetMembersFilter;
}

type FleetMemberMetrics = {
  totalAdmins: number;
  totalOfficers: number;
  totalMembers: number;
};

type FleetMemberStats = {
  total: number;
  metrics: FleetMemberMetrics;
};
