import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import type { FleetOption, FleetOptions } from "@/services/fyAdminApi";

const fleetOptions = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyAdminApi", () => ({ fleetOptions }));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import FleetActorSearch from "./index.vue";

const fleet = (fid: string, overrides: Partial<FleetOption> = {}) => ({
  id: `id-${fid}`,
  fid,
  name: fid,
  slug: fid.toLowerCase(),
  memberCount: 3,
  ...overrides,
});

const page = (
  items: FleetOption[],
  currentPage = 1,
  totalPages = 1,
): FleetOptions => ({
  items,
  meta: {
    pagination: {
      currentPage,
      totalPages,
      perPage: 25,
      totalCount: items.length,
    },
  },
});

const mountSearch = (enabledIds: string[] = []) =>
  mount(FleetActorSearch, {
    props: { enabledIds },
    global: {
      stubs: {
        FormInput: {
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template:
            "<input :value='modelValue' @input=\"$emit('update:modelValue', $event.target.value)\" />",
        },
        Btn: {
          emits: ["click"],
          template: "<button @click=\"$emit('click')\"><slot /></button>",
        },
      },
    },
  });

const searchFor = async (
  wrapper: ReturnType<typeof mountSearch>,
  term: string,
) => {
  await wrapper.find("input").setValue(term);
  await vi.runAllTimersAsync();
  await flushPromises();
};

const rows = (wrapper: ReturnType<typeof mountSearch>) =>
  wrapper
    .findAll('[data-test="fleet-actor-result"]')
    .map((row) => row.find(".fleet-actor-result-fid").text());

describe("FeatureFleetActorSearch", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    fleetOptions.mockReset();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("asks the ranked search and keeps the order it answers in", async () => {
    fleetOptions.mockResolvedValue(
      page([fleet("Test100", { name: "Test" }), fleet("1test")]),
    );
    const wrapper = mountSearch();

    await searchFor(wrapper, " test ");

    expect(fleetOptions).toHaveBeenCalledWith({
      page: "1",
      q: { search: "test" },
    });
    expect(rows(wrapper)).toEqual(["Test100", "1test"]);
  });

  it("offers a fleet that already has the feature as enabled, not addable", async () => {
    fleetOptions.mockResolvedValue(page([fleet("A"), fleet("B")]));
    const wrapper = mountSearch(["id-A"]);

    await searchFor(wrapper, "x");

    const [first, second] = wrapper.findAll('[data-test="fleet-actor-result"]');
    expect(first.find('[data-test="fleet-actor-enabled"]').exists()).toBe(true);
    expect(first.find('[data-test="fleet-actor-add"]').exists()).toBe(false);

    await second.find('[data-test="fleet-actor-add"]').trigger("click");

    expect(wrapper.emitted("add")?.[0]).toEqual([fleet("B")]);
  });

  it("appends the next page below the first", async () => {
    fleetOptions
      .mockResolvedValueOnce(page([fleet("A")], 1, 2))
      .mockResolvedValueOnce(page([fleet("B")], 2, 2));
    const wrapper = mountSearch();

    await searchFor(wrapper, "x");
    await wrapper
      .find('[data-test="fleet-actor-search-more"]')
      .trigger("click");
    await flushPromises();

    expect(fleetOptions).toHaveBeenLastCalledWith({
      page: "2",
      q: { search: "x" },
    });
    expect(rows(wrapper)).toEqual(["A", "B"]);
    expect(wrapper.find('[data-test="fleet-actor-search-more"]').exists()).toBe(
      false,
    );
  });

  it("does not let an older search overwrite a newer one", async () => {
    let answerFirst: (value: FleetOptions) => void = () => {};
    fleetOptions
      .mockReturnValueOnce(
        new Promise<FleetOptions>((resolve) => {
          answerFirst = resolve;
        }),
      )
      .mockResolvedValueOnce(page([fleet("NEW")]));
    const wrapper = mountSearch();

    await searchFor(wrapper, "old");
    await searchFor(wrapper, "new");
    answerFirst(page([fleet("OLD")]));
    await flushPromises();

    expect(rows(wrapper)).toEqual(["NEW"]);
  });

  it("drops a search in flight when the box is cleared", async () => {
    let answer: (value: FleetOptions) => void = () => {};
    fleetOptions.mockReturnValueOnce(
      new Promise<FleetOptions>((resolve) => {
        answer = resolve;
      }),
    );
    const wrapper = mountSearch();

    await searchFor(wrapper, "slow");
    await searchFor(wrapper, "");
    answer(page([fleet("LATE")], 1, 2));
    await flushPromises();

    expect(rows(wrapper)).toEqual([]);
    expect(wrapper.find('[data-test="fleet-actor-search-more"]').exists()).toBe(
      false,
    );
  });

  it("says so when nothing matches", async () => {
    fleetOptions.mockResolvedValue(page([]));
    const wrapper = mountSearch();

    await searchFor(wrapper, "nothing");

    expect(
      wrapper.find('[data-test="fleet-actor-search-empty"]').exists(),
    ).toBe(true);
  });
});
