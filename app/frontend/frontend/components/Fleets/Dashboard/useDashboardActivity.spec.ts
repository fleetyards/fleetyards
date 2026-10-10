import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, ref, type Ref } from "vue";
import { FleetActivityCategoryEnum } from "@/services/fyApi/models/FleetActivityCategoryEnum";
import type { FleetActivity } from "@/services/fyApi";

const items = ref<Partial<FleetActivity>[]>([]);
const calls: Ref<{ limit: number; perCategory: boolean }>[] = [];

vi.mock("@/services/fyApi", async () => {
  const categories = await vi.importActual(
    "@/services/fyApi/models/FleetActivityCategoryEnum.ts",
  );

  return {
    ...categories,
    useFleetActivity: (
      _slug: unknown,
      params: Ref<{ limit: number; perCategory: boolean }>,
    ) => {
      calls.push(params);

      return {
        data: computed(() => ({ items: items.value })),
        isLoading: ref(false),
      };
    },
  };
});

const { useDashboardActivity } = await import("./useDashboardActivity");

const entry = (
  id: string,
  category: string,
  minutesAgo = 0,
): Partial<FleetActivity> => ({
  id,
  category: category as FleetActivity["category"],
  occurredAt: new Date(Date.now() - minutesAgo * 60_000).toISOString(),
});

describe("useDashboardActivity", () => {
  beforeEach(() => {
    items.value = [];
    calls.length = 0;
  });

  it("asks once, limited per category, for every panel", () => {
    useDashboardActivity("maru", [FleetActivityCategoryEnum.MEMBERS]);

    expect(calls).toHaveLength(1);
    expect(calls[0].value).toEqual({ limit: 20, perCategory: true });
  });

  it("splits the answer and leaves the feed what no panel tells", () => {
    items.value = [
      entry("e", FleetActivityCategoryEnum.EVENTS),
      entry("i", FleetActivityCategoryEnum.INVENTORY),
      entry("m", FleetActivityCategoryEnum.MEMBERS),
    ];

    const activity = useDashboardActivity("maru", [
      FleetActivityCategoryEnum.MEMBERS,
      FleetActivityCategoryEnum.INVENTORY,
    ]);

    expect(activity.feed.value.map(({ id }) => id)).toEqual(["e"]);
    expect(activity.inventory.value?.map(({ id }) => id)).toEqual(["i"]);
    expect(activity.newMembers.value?.map(({ id }) => id)).toEqual(["m"]);
  });

  // A full category may have more past its oldest entry. Past that edge the
  // merged feed would skip them and show the others' older entries instead.
  it("stops the feed at the edge of a category that came back full", () => {
    items.value = [
      ...Array.from({ length: 20 }, (_, index) =>
        entry(`e${index}`, FleetActivityCategoryEnum.EVENTS, index),
      ),
      entry("recent", FleetActivityCategoryEnum.CONTRACTS, 5),
      entry("old", FleetActivityCategoryEnum.CONTRACTS, 60 * 24 * 30),
    ].sort((a, b) => (b.occurredAt ?? "").localeCompare(a.occurredAt ?? ""));

    const activity = useDashboardActivity("maru", []);

    expect(activity.feed.value.map(({ id }) => id)).toContain("recent");
    expect(activity.feed.value.map(({ id }) => id)).not.toContain("old");
    expect(activity.hasMore.value).toBe(true);
  });

  it("asks for more once the feed runs past that edge, and stops at fifty", () => {
    items.value = Array.from({ length: 20 }, (_, index) =>
      entry(`e${index}`, FleetActivityCategoryEnum.EVENTS, index),
    );

    const activity = useDashboardActivity("maru", []);

    expect(activity.feed.value).toHaveLength(15);

    activity.showMore();
    expect(calls[0].value.limit).toBe(50);

    items.value = Array.from({ length: 30 }, (_, index) =>
      entry(`e${index}`, FleetActivityCategoryEnum.EVENTS, index),
    );
    activity.showMore();
    activity.showMore();

    expect(activity.feed.value).toHaveLength(30);
    expect(activity.hasMore.value).toBe(false);
  });

  it("offers no more once a short answer is all shown", () => {
    items.value = [entry("e", FleetActivityCategoryEnum.EVENTS)];

    expect(useDashboardActivity("maru", []).hasMore.value).toBe(false);
  });
});
