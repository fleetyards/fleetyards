type TFleetMember = {
  id: string;
  username: string;
  primary: boolean;
  shipsFilter: string;
  hangarGroupId: string;
};

type TFleetMemberForm = {
  username: string;
};

type TFleetMembershipForm = {
  primary: boolean;
  shipsFilter: string | null;
  hangarGroupId: string | null;
};

type TFleetMemberInviteForm = {
  token: string;
  username: string;
};

type TFleetMembersFilter = {
  usernameCont: string;
  roleIn: string[];
};

interface TFleetMembersParams extends TCollectionParams<TFleetMembersFilter> {
  slug: string;
}

type TFleetMemberMetrics = {
  totalAdmins: number;
  totalOfficers: number;
  totalMembers: number;
};

type TFleetMemberStats = {
  total: number;
  metrics: TFleetMemberMetrics;
};
