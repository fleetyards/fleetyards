import type { RouteRecordRaw } from "vue-router";
import { routes as eventEditRoutes } from "@/frontend/pages/fleets/[slug]/events/[event]/edit/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-events",
    component: () => import("@/frontend/pages/fleets/[slug]/events/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.events.index",
      needsAuthentication: true,
      access: ["fleet:events:read", "fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: "new/",
    name: "fleet-event-new",
    component: () => import("@/frontend/pages/fleets/[slug]/events/new.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.events.create",
      needsAuthentication: true,
      access: ["fleet:events:create", "fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: ":event/edit/",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit.vue"),
    children: eventEditRoutes,
    redirect: { name: eventEditRoutes[0].name as string },
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.events.edit",
      needsAuthentication: true,
      access: ["fleet:events:update", "fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: ":event/",
    name: "fleet-event",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event].vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.events.show",
      needsAuthentication: true,
      access: ["fleet:events:read", "fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
];
