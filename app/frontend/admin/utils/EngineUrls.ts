/*
 * Rails engines mounted beside the admin app, not routes of it. They live under
 * `/admin` only when the admin is served from a path rather than its own
 * subdomain, which is why the prefix is read from the window and not hardcoded.
 */
const prefix = window.ON_SUBDOMAIN ? "" : "/admin";

export const engineUrls = {
  workers: `${prefix}/workers`,
  pghero: `${prefix}/pghero`,
  maintenanceTasks: `${prefix}/maintenance_tasks`,
};
