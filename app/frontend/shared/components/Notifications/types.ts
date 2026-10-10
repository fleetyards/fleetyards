// The frontend and admin notification centres share the row and the reading
// pane, but their records come from different clients and their copy from
// different translation scopes.
export type NotificationScope = "notifications" | "adminNotifications";

export type NotificationRecord = {
  id: string;
  title: string;
  body?: string;
  icon?: string;
  read: boolean;
  archived: boolean;
  createdAt: string;
};
