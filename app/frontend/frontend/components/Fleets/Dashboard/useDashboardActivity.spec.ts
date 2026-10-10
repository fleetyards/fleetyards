import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, ref, type Ref } from "vue";
import { FleetActivityCategoryEnum } from "@/services/fyApi/models/FleetActivityCategoryEnum";
import type { FleetActivity } from "@/services/fyApi";

let items: Partial<FleetActivity>[] = [];
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

      return { data: computed(() => ({ items })), isLoading: ref(false) };
    },
  };
});

const { useDashboardActivity } = await import("./useDashboardActivity");

const entry = (id: string, category: string): Partial<FleetActivity> => ({
  id,
  category: category as FleetActivity["category"],
});

describe("useDashboardActivity", () => {
  beforeEach(() => {
    items = [];
    calls.length = 0;
  });

  it("asks once, limited per category, for every panel", () => {
    useDashboardActivity("maru", [FleetActivityCategoryEnum.MEMBERS]);

    expect(calls).toHaveLength(1);
    expect(calls[0].value).toEqual({ limit: 30, perCategory: true });
  });

  it("splits the answer and leaves the feed what no panel tells", () => {
    items = [
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

  // A category that came back full may hold more than was asked for.
  it("grows the limit once the feed runs past what came back", () => {
    items = Array.from({ length: 30 }, (_, index) =>
      entry(`e${index}`, FleetActivityCategoryEnum.EVENTS),
    );

    const activity = useDashboardActivity("maru", []);

    expect(activity.feed.value).toHaveLength(15);
    expect(activity.hasMore.value).toBe(true);

    activity.showMore();
    expect(calls[0].value.limit).toBe(30);

    activity.showMore();
    expect(calls[0].value.limit).toBe(50);
  });

  it("offers no more once a short answer is all shown", () => {
    items = [entry("e", FleetActivityCategoryEnum.EVENTS)];

    expect(useDashboardActivity("maru", []).hasMore.value).toBe(false);
  });
});
