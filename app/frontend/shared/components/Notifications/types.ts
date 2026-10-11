// The frontend and admin notification centres share the row and the reading
// pane, but their records come from different clients and their copy from
// different translation scopes, so each centre hands in its own keys.
export interface NotificationLabels {
  select: string;
  unread: string;
  archive: string;
  unarchive: string;
  noBody: string;
  selectPrompt: string;
}

export interface NotificationEntry {
  id: string;
  title: string;
  body?: string;
  icon?: string;
  read: boolean;
  archived: boolean;
  createdAt: string;
}
