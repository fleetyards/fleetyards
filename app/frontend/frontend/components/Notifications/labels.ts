import type { NotificationLabels } from "@/shared/components/Notifications/types";

// Spelled out rather than built from the scope, so a search for a key finds the
// code that reads it and a locale clean-up cannot take it for unused.
export const NOTIFICATION_LABELS: NotificationLabels = {
  select: "actions.notifications.select",
  unread: "actions.notifications.unread",
  archive: "actions.notifications.archive",
  unarchive: "actions.notifications.unarchive",
  noBody: "labels.notifications.noBody",
  selectPrompt: "labels.notifications.selectPrompt",
};
