import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetOnlineMembersList } from "@/services/fyApi";
import Component from "./index.vue";

let online: FleetOnlineMembersList | undefined;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetOnlineMembers: () => ({ data: computed(() => online) }),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const mount = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/m/:slug", name: "fleet-members-index", component: Stub },
    ],
  });
  await router.push("/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet },
    plugins: [router],
  });
};

describe("FleetDashboardOnlineMembersPanel", () => {
  beforeEach(() => {
    online = undefined;
  });

  it("draws nothing while nobody else is online", async () => {
    online = { totalCount: 0, items: [] };

    const subject = await mount();

    expect(subject.find("[data-test='fleet-dashboard-online']").exists()).toBe(
      false,
    );
  });

  it("marks friends and says how many more there are", async () => {
    online = {
      totalCount: 3,
      items: [
        { username: "zulu", friend: true },
        { username: "alpha", friend: false },
      ],
    };

    const subject = await mount();

    expect(
      subject.findAll("[data-test='fleet-dashboard-online-friend']"),
    ).toHaveLength(1);
    expect(subject.find(".online-members__more").text()).toContain("1");
  });
});
