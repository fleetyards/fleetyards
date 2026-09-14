import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

// Reading the board is what claiming rides on, so every route here asks for
// `fleet:contracts:read` and the writes are refused by the policy rather than
// by the router.
const READ_ACCESS = [
  "fleet:contracts:read",
  "fleet:contracts:manage",
  "fleet:manage",
];

const WRITE_ACCESS = [
  "fleet:contracts:create",
  "fleet:contracts:manage",
  "fleet:manage",
];

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-contracts",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/contracts/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.contracts.index",
      needsAuthentication: true,
      access: READ_ACCESS,
      feature: FeatureFlagName.FLEET_CONTRACTS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  // The other three boards. One component, one route each, the way the
  // logistics ledger and the transfers list are built -- `nav: "hidden"` keeps
  // them out of the fleet nav, which names the section once.
  {
    path: "closed/",
    name: "fleet-contracts-closed",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/contracts/index.vue"),
    meta: {
      nav: "hidden",
      activeTab: "fleet-contracts",
      backgroundImage: "bg-8",
      title: "fleets.contracts.closed",
      needsAuthentication: true,
      access: READ_ACCESS,
      feature: FeatureFlagName.FLEET_CONTRACTS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: "mine/",
    name: "fleet-contracts-mine",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/contracts/index.vue"),
    meta: {
      nav: "hidden",
      activeTab: "fleet-contracts",
      backgroundImage: "bg-8",
      title: "fleets.contracts.mine",
      needsAuthentication: true,
      access: READ_ACCESS,
      feature: FeatureFlagName.FLEET_CONTRACTS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: "completed/",
    name: "fleet-contracts-completed",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/contracts/index.vue"),
    meta: {
      nav: "hidden",
      activeTab: "fleet-contracts",
      backgroundImage: "bg-8",
      title: "fleets.contracts.completed",
      needsAuthentication: true,
      access: READ_ACCESS,
      feature: FeatureFlagName.FLEET_CONTRACTS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: "new/",
    name: "fleet-contract-new",
    component: () => import("@/frontend/pages/fleets/[slug]/contracts/new.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.contracts.create",
      needsAuthentication: true,
      access: WRITE_ACCESS,
      feature: FeatureFlagName.FLEET_CONTRACTS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: ":contract/edit/",
    name: "fleet-contract-edit",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/contracts/[contract]/edit.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.contracts.edit",
      needsAuthentication: true,
      access: [
        "fleet:contracts:update",
        "fleet:contracts:manage",
        "fleet:manage",
      ],
      feature: FeatureFlagName.FLEET_CONTRACTS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: ":contract/",
    name: "fleet-contract",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/contracts/[contract].vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.contracts.show",
      needsAuthentication: true,
      access: READ_ACCESS,
      feature: FeatureFlagName.FLEET_CONTRACTS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
];
