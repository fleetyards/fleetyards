import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h } from "vue";
import Component from "./index.vue";

let offered: string[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useScDataSources: () => ({
      data: computed(() => ({
        items: offered.map((environment) => ({ environment })),
      })),
    }),
  };
});

vi.mock("@/frontend/components/Home/Dashboard/PatchTile/index.vue", () => ({
  default: defineComponent({
    props: { environment: { type: String, required: true } },
    setup: (props) => () =>
      h("div", { "data-test": "patch-tile" }, props.environment),
  }),
}));

const environments = async () =>
  (await mountWithDefaults(Component))
    .findAll('[data-test="patch-tile"]')
    .map((tile) => tile.text());

describe("HomeDashboardPatchTiles", () => {
  beforeEach(() => {
    offered = ["live"];
  });

  it("shows live alone while there is no preview", async () => {
    expect(await environments()).toEqual(["live"]);
  });

  it("puts the PTU beside live while one is offered", async () => {
    offered = ["live", "ptu"];

    expect(await environments()).toEqual(["live", "ptu"]);
  });
});
