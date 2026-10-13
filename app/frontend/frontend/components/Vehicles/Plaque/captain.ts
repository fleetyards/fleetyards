import { type User, type VehiclePublic } from "@/services/fyApi";

// The owner as a plaque names them to the public: by their display name, and
// not at all once they hide themselves from what they own.
export const ownerCaptain = (
  user?: Pick<User, "username" | "displayName" | "hideOwner">,
) => (!user || user.hideOwner ? undefined : user.displayName || user.username);

// A public payload leaves both names out for an owner who hides themselves.
export const publicOwnerCaptain = (
  vehicle: Pick<VehiclePublic, "username" | "userDisplayName">,
) => vehicle.userDisplayName || vehicle.username;
