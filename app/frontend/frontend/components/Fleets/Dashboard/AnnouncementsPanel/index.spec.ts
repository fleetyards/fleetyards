import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed } from "vue";
import type { Fleet, FleetAnnouncement } from "@/services/fyApi";
import Component from "./index.vue";

let items: FleetAnnouncement[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetAnnouncements: () => ({ data: computed(() => ({ items })) }),
  };
});

const announcement = (id: string): FleetAnnouncement => ({
  id,
  body: `Announcement ${id}`,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

const mount = (canManage = false) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet, canManage },
  });

const shown = (subject: Awaited<ReturnType<typeof mount>>) =>
  subject.findAll("[data-test='fleet-dashboard-announcement']").length;

describe("FleetDashboardAnnouncementsPanel", () => {
  beforeEach(() => {
    items = [];
  });

  it("draws nothing while nothing is announced", async () => {
    const subject = await mount();

    expect(
      subject.find("[data-test='fleet-dashboard-announcements']").exists(),
    ).toBe(false);
  });

  // Every standing announcement stays reachable, or one past the third could
  // never be read or taken down.
  it("opens with three and shows the rest on request", async () => {
    items = ["a", "b", "c", "d"].map(announcement);

    const subject = await mount();

    expect(shown(subject)).toBe(3);

    await subject
      .find("[data-test='fleet-dashboard-announcements-more']")
      .trigger("click");

    expect(shown(subject)).toBe(4);
  });

  it("offers editing only to whoever may manage announcements", async () => {
    items = [announcement("a")];

    expect(
      (await mount())
        .find("[data-test='fleet-dashboard-announcement-edit']")
        .exists(),
    ).toBe(false);
    expect(
      (await mount(true))
        .find("[data-test='fleet-dashboard-announcement-edit']")
        .exists(),
    ).toBe(true);
  });
});
