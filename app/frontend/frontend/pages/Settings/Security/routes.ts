import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: "settings-security-status",
    component: () =>
      import("@/frontend/pages/Settings/Security/Status/index.vue"),
    meta: {
      title: "settings.security",
      needsAuthentication: true,
    },
  },
  {
    path: "two-factor/enable/",
    name: "settings-two-factor-enable",
    component: () =>
      import("@/frontend/pages/Settings/Security/TwoFactorEnable/index.vue"),
    meta: {
      title: "settings.twoFactor.enable",
      needsAuthentication: true,
      needsSecurityConfirm: true,
    },
  },
  {
    path: "two-factor/disable/",
    name: "settings-two-factor-disable",
    component: () =>
      import("@/frontend/pages/Settings/Security/TwoFactorDisable/index.vue"),
    meta: {
      title: "settings.twoFactor.disable",
      needsAuthentication: true,
      needsSecurityConfirm: true,
    },
  },
  {
    path: "two-factor/backup-codes/",
    name: "settings-two-factor-backup-codes",
    component: () =>
      import(
        "@/frontend/pages/Settings/Security/TwoFactorBackupCodes/index.vue"
      ),
    meta: {
      title: "settings.twoFactor.backupCodes",
      needsAuthentication: true,
      needsSecurityConfirm: true,
    },
  },
];

export default routes;
