import type { MediaFile } from "@/services/fyApi";
import type {
  RelationshipDirectionEnum,
  RelationshipStateEnum,
} from "@/services/fyApi";

// One row shape for friendships and fleet alliances alike. The two differ only
// in what the other party is called and how it is addressed, and normalising
// that here is what lets the table and the view be written once.
export type RelationshipRow = {
  id: string;
  // Username or slug: how the API addresses this relationship. There is no id
  // in any of the routes.
  handle: string;
  label: string;
  avatar?: MediaFile;
  // Optional on purpose: the same row renders a fleet on the alliances view,
  // and a fleet is not online. Left unset there, and unset as well for a
  // friendship nobody has accepted yet.
  userId?: string;
  online?: boolean;
  lastActiveAt?: string | null;
  state: RelationshipStateEnum;
  direction: RelationshipDirectionEnum;
  createdAt: string;
};

export type RelationshipTab = "accepted" | "incoming" | "outgoing" | "ignored";

export type RelationshipTabRoutes = Record<RelationshipTab, string>;
