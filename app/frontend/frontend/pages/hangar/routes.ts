import type { RouteLocationNormalized, RouteRecordRaw } from "vue-router";
import { routes as vehicleRoutes } from "@/frontend/pages/hangar/[username]/[segment]/routes";
import { routes as publicHangarRoutes } from "@/frontend/pages/hangar/[username]/routes";
import { FeatureFlagName, getShowVehicleQueryOptions } from "@/services/fyApi";
import { featuresQueryOptions } from "@/frontend/composables/useFeatures";
import { ensureQueryData } from "@/frontend/utils/RouteGuards/queryData";
import { useSessionStore } from "@/frontend/stores/session";
import {
  VEHICLE_SEGMENT_PATTERN,
  type VehicleRouteName,
  vehicleRoute,
} from "@/frontend/utils/vehicleSegment";

// The overview is the ship's front page once it is rolled out; until then the
// loadouts are. A redirect cannot wait for the flags, so the index decides
// before it is entered.
const vehicleIndexGuard = async (to: RouteLocationNormalized) => {
  let name = "hangar-vehicle-loadouts";

  try {
    const features = await ensureQueryData(featuresQueryOptions());

    if (features?.includes(FeatureFlagName.VEHICLE_OVERVIEW)) {
      name = "hangar-vehicle-overview";
    }
  } catch {
    // Fall through to the tab the page opened on before the overview.
  }

  return { name, params: to.params, query: to.query, replace: true };
};

// Vehicle pages are their owner's alone. Signed out, the session guard sends
// the visitor to log in first, so only a signed-in reader is turned away here.
const vehicleOwnerGuard = (to: RouteLocationNormalized) => {
  const username = useSessionStore().currentUser?.username;
  const owner = String(to.params.username);

  if (!username || owner.toLowerCase() === username.toLowerCase()) return;

  return { name: "hangar-public", params: { username: owner } };
};

// Never rendered: the guard always leaves for the vehicle's current address.
const legacyVehicleShell = () => import("@/frontend/pages/404.vue");

const legacyVehicleGuard =
  (name: VehicleRouteName, query: Record<string, string> = {}) =>
  async (to: RouteLocationNormalized) => {
    const username = useSessionStore().currentUser?.username;
    if (!username) return;

    try {
      const vehicle = await ensureQueryData(
        getShowVehicleQueryOptions(String(to.params.id)),
      );
      const { id: _id, ...params } = to.params as Record<string, string>;

      return {
        ...vehicleRoute(name, vehicle, username, params),
        query: { ...to.query, ...query },
        hash: to.hash,
        replace: true,
      };
    } catch {
      return { name: "404" };
    }
  };

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "hangar",
    component: () => import("@/frontend/pages/hangar/index.vue"),
    meta: {
      mobileBack: true,
      needsAuthentication: true,
      title: "hangar.index",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "wishlist/",
    name: "hangar-wishlist",
    component: () => import("@/frontend/pages/hangar/wishlist.vue"),
    meta: {
      mobileBack: true,
      needsAuthentication: true,
      title: "hangar.wishlist",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "preview/",
    name: "hangar-preview",
    component: () => import("@/frontend/pages/hangar/preview.vue"),
    meta: {
      title: "hangar.preview",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "fleetchart/",
    name: "hangar-fleetchart",
    redirect: {
      name: "hangar",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "transfers/",
    name: "hangar-transfers",
    component: () => import("@/frontend/pages/hangar/transfers.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.transfers",
      backgroundImage: "bg-5",
    },
  },
  {
    // Was a route of its own; the view moved into the query so switching
    // to it keeps the page. The path stays so shared links resolve.
    path: "transfers/outgoing/",
    redirect: (to) => ({
      name: "hangar-transfers",
      params: to.params,
      query: { ...to.query, direction: "outgoing" },
    }),
  },
  {
    path: "inventories/",
    name: "hangar-inventories",
    component: () => import("@/frontend/pages/hangar/inventories/index.vue"),
    meta: {
      mobileBack: true,
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    // Was a route of its own; the view moved into the query so switching
    // to it keeps the page. The path stays so shared links resolve.
    path: "transactions/",
    redirect: (to) => ({
      name: "hangar-inventories",
      params: to.params,
      query: { ...to.query, tab: "log" },
    }),
  },
  {
    path: "inventories/:inventory/",
    name: "hangar-inventory",
    component: () =>
      import("@/frontend/pages/hangar/inventories/[inventory].vue"),
    meta: {
      mobileBack: true,
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    // Was a route of its own; the view moved into the query so switching
    // to it keeps the page. The path stays so shared links resolve.
    path: "inventories/:inventory/transactions/",
    redirect: (to) => ({
      name: "hangar-inventory",
      params: to.params,
      query: { ...to.query, tab: "log" },
    }),
  },
  {
    path: "inventories/:inventory/items/:item/",
    name: "hangar-inventory-item",
    component: () =>
      import("@/frontend/pages/hangar/inventories/[inventory]/[item].vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    path: "imports/",
    name: "hangar-imports",
    component: () => import("@/frontend/pages/hangar/imports.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.imports",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "buybacks/",
    name: "hangar-buybacks",
    component: () => import("@/frontend/pages/hangar/buybacks.vue"),
    meta: {
      mobileBack: true,
      needsAuthentication: true,
      title: "hangar.buybacks",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "paints/",
    name: "hangar-paints",
    component: () => import("@/frontend/pages/hangar/paints.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.paints",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "flair/",
    name: "hangar-flair",
    component: () => import("@/frontend/pages/hangar/flair.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.flair",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "equipment/",
    name: "hangar-equipment",
    component: () => import("@/frontend/pages/hangar/equipment.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.equipment",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "upgrades/",
    name: "hangar-upgrades",
    component: () => import("@/frontend/pages/hangar/upgrades.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.upgrades",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "stats/",
    name: "hangar-stats",
    component: () => import("@/frontend/pages/hangar/stats.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.stats",
      backgroundImage: "bg-5",
    },
  },
  {
    path: ":username/",
    component: () => import("@/frontend/pages/hangar/[username].vue"),
    children: publicHangarRoutes,
    redirect: { name: publicHangarRoutes[0].name },
  },
  // Outside the vehicle's tab shell on purpose: everything under it becomes a
  // tab, and a single cargo position is a page you drill into rather than a
  // fifth place to stand. Same shape as /hangar/inventories/:inventory/:item.
  {
    path: `:username/:segment(${VEHICLE_SEGMENT_PATTERN})/cargo/:item/`,
    name: "hangar-vehicle-cargo-item",
    component: () =>
      import("@/frontend/pages/hangar/[username]/[segment]/cargo/[item].vue"),
    beforeEnter: vehicleOwnerGuard,
    meta: {
      needsAuthentication: true,
      title: "hangar.vehicleCargo",
      backgroundImage: "bg-5",
      customTitle: true,
      feature: FeatureFlagName.SHIP_INVENTORIES,
    },
  },
  // A loadout's page, outside the tab shell like a cargo position, and outside
  // the owner guard: a ship its owner shows in a public hangar shows its
  // loadouts too, read-only, and the page reads the owner's or the public
  // endpoints by who is looking.
  {
    path: `:username/:segment(${VEHICLE_SEGMENT_PATTERN})/loadouts/:loadout/`,
    name: "hangar-vehicle-loadout",
    component: () =>
      import("@/frontend/pages/hangar/[username]/[segment]/loadouts/[loadout].vue"),
    meta: {
      title: "hangar.vehicleLoadout",
      backgroundImage: "bg-5",
      customTitle: true,
    },
  },
  {
    path: `:username/:segment(${VEHICLE_SEGMENT_PATTERN})/`,
    component: () => import("@/frontend/pages/hangar/[username]/[segment].vue"),
    beforeEnter: vehicleOwnerGuard,
    children: [
      {
        path: "",
        name: "hangar-vehicle",
        component: () =>
          import("@/frontend/pages/hangar/[username]/[segment]/loadouts.vue"),
        beforeEnter: vehicleIndexGuard,
      },
      ...vehicleRoutes,
    ],
    meta: {
      needsAuthentication: true,
    },
  },
  // Where a vehicle lived before its address carried the owner: by id, or by a
  // serial of any shape. Kept so bookmarks and shared links still arrive.
  {
    path: ":id/cargo/:item/",
    component: legacyVehicleShell,
    beforeEnter: legacyVehicleGuard("hangar-vehicle-cargo-item"),
    meta: { needsAuthentication: true },
  },
  ...vehicleRoutes
    .filter((tab) => tab.name)
    .map((tab) => ({
      path: `:id/${tab.path}`,
      component: legacyVehicleShell,
      beforeEnter: legacyVehicleGuard(tab.name as VehicleRouteName),
      meta: { needsAuthentication: true },
    })),
  {
    path: ":id/cargo/transactions/",
    component: legacyVehicleShell,
    beforeEnter: legacyVehicleGuard("hangar-vehicle-cargo", { tab: "log" }),
    meta: { needsAuthentication: true },
  },
];
