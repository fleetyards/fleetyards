// The subset of a member every contact surface needs. Kept structural rather
// than tied to FleetMember: a vehicle owner and an inventory manager carry the
// same handles under their own payload shapes.
export interface MemberContact {
  username?: string;
  rsiHandle?: string;
  discordProfileUrl?: string;
  citizenidProfileUrl?: string;
}
