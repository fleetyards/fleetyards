import { type UserPublic } from "@/services/fyApi";

type NamedUser = Pick<UserPublic, "username" | "displayName">;

const possessive = (name: string) =>
  /[sxz]$/i.test(name) ? name : `${name}'s`;

// A display name is written as its owner chose it; only a username, which is
// a URL slug, is capitalised for a title.
export const shownName = (user: NamedUser) =>
  user.displayName || user.username[0].toUpperCase() + user.username.slice(1);

export const possessiveName = (user: NamedUser) => possessive(shownName(user));
