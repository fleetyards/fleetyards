import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import type { MyFleetSummary } from "@/services/fyApi";
import Component from "./index.vue";

let summaries: MyFleetSummary[] = [];

const answer = <T>(value: () => T) => ({
  data: computed(value),
  isLoading: ref(false),
  isFetching: ref(false),
  isLoadingError: ref(false),
});

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useMyFleetSummaries: () => answer(() => ({ items: summaries })),
    useFleet: (slug: { value: string }) =>
      answer(() => (slug.value ? { slug: slug.value } : undefined)),
  };
});

vi.mock(
  "@/frontend/components/Fleets/Dashboard/ContractsPanel/index.vue",
  () => ({
    default: defineComponent({
      props: { fleet: { type: Object, required: true } },
      setup: (props) => () =>
        h("div", { "data-test": "fleet-contracts" }, String(props.fleet.slug)),
    }),
  }),
);

const summary = (contractsEnabled: boolean): MyFleetSummary => ({
  id: "f1",
  name: "Black Sun Logistics",
  slug: "black-sun",
  primary: true,
  memberCount: 84,
  contractsEnabled,
});

describe("HomeDashboardContractsPanel", () => {
  beforeEach(() => {
    summaries = [];
  });

  it("shows the board of a fleet that runs contracts", async () => {
    summaries = [summary(true)];

    const subject = await mountWithDefaults(Component);

    expect(subject.find('[data-test="fleet-contracts"]').text()).toBe(
      "black-sun",
    );
  });

  it("shows nothing for a fleet without contracts", async () => {
    summaries = [summary(false)];

    const subject = await mountWithDefaults(Component);

    expect(subject.find('[data-test="fleet-contracts"]').exists()).toBe(false);
  });
});
