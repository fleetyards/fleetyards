import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { ref, nextTick } from "vue";

const CATALOGUE = '[data-test="build-compare-catalogue"]';
const NOT_RECORDED = '[data-test="build-compare-not-recorded"]';
const ENTRY = '[data-test="build-compare-entry"]';
const CHANGE = '[data-test="build-compare-change"]';
const MORE = '[data-test="build-compare-more"]';

const empty = () => ({
  recorded: true,
  counts: { appeared: 0, vanished: 0, changed: 0 },
  appeared: [],
  vanished: [],
  changed: [],
});

const builds = ref<{ items: unknown[] } | undefined>(undefined);
const comparison = ref<unknown>(undefined);

vi.mock("@/services/fyApi", () => ({
  useScDataBuilds: () => ({ data: builds, isPending: ref(false) }),
  useScDataCompare: () => ({
    data: comparison,
    isPending: ref(false),
    isError: ref(false),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, params?: Record<string, unknown>) =>
      params ? `${key}:${JSON.stringify(params)}` : key,
  }),
}));

import BuildComparePage from "./build-compare.vue";

const mountPage = async () => {
  const wrapper = mount(BuildComparePage, {
    global: {
      stubs: {
        Heading: { template: "<div><slot /></div>" },
        HeadingSmall: { template: "<div><slot /></div>" },
        BasePanel: { template: "<div><slot /></div>" },
        BasePill: { template: "<span><slot /></span>" },
        BaseSelect: true,
        SmallLoader: true,
      },
    },
  });

  await nextTick();

  return wrapper;
};

const catalogueNamed = (
  wrapper: Awaited<ReturnType<typeof mountPage>>,
  name: string,
) =>
  wrapper
    .findAll(CATALOGUE)
    .find((panel) => panel.attributes("data-catalogue") === name)!;

describe("BuildComparePage", () => {
  beforeEach(() => {
    builds.value = {
      items: [
        { environment: "ptu", version: "4.10.1-ptu", default: false },
        { environment: "live", version: "4.10.0-live", default: true },
      ],
    };
    comparison.value = undefined;
  });

  it("names what appeared and vanished rather than listing identifiers", async () => {
    comparison.value = {
      from: { environment: "live", version: "4.10.0-live" },
      to: { environment: "ptu", version: "4.10.1-ptu" },
      catalogues: {
        components: {
          recorded: true,
          counts: { appeared: 1, vanished: 1, changed: 0 },
          appeared: [{ id: "a-uuid", name: "Arrived" }],
          vanished: [{ id: "b-uuid", name: "Departed" }],
          changed: [],
        },
        equipment: empty(),
        commodities: empty(),
        models: empty(),
      },
    };

    const wrapper = await mountPage();
    const names = catalogueNamed(wrapper, "components")
      .findAll(ENTRY)
      .map((entry) => entry.text());

    expect(names).toEqual(["Arrived", "Departed"]);
  });

  // A build row need not carry a name, and an empty row is worse than an ugly
  // one: it gives a reader nothing at all to look up.
  it("falls back to the identifier when a record has no name", async () => {
    comparison.value = {
      from: { environment: "live", version: "4.10.0-live" },
      to: { environment: "ptu", version: "4.10.1-ptu" },
      catalogues: {
        components: {
          recorded: true,
          counts: { appeared: 1, vanished: 0, changed: 0 },
          appeared: [{ id: "a-uuid", name: null }],
          vanished: [],
          changed: [],
        },
        equipment: empty(),
        commodities: empty(),
        models: empty(),
      },
    };

    const wrapper = await mountPage();

    expect(catalogueNamed(wrapper, "components").find(ENTRY).text()).toBe(
      "a-uuid",
    );
  });

  // The distinction the endpoint exists to make: a catalogue nobody recorded for
  // one of the two builds must not read as one where nothing changed.
  it("says a catalogue was not recorded instead of showing empty lists", async () => {
    comparison.value = {
      from: { environment: "live", version: "4.10.0-live" },
      to: { environment: "ptu", version: "4.10.1-ptu" },
      catalogues: {
        components: empty(),
        equipment: empty(),
        commodities: {
          recorded: false,
          counts: { appeared: 0, vanished: 0, changed: 0 },
          appeared: [],
          vanished: [],
          changed: [],
        },
        models: empty(),
      },
    };

    const wrapper = await mountPage();

    expect(
      catalogueNamed(wrapper, "commodities").find(NOT_RECORDED).exists(),
    ).toBe(true);
    expect(
      catalogueNamed(wrapper, "components").find(NOT_RECORDED).exists(),
    ).toBe(false);
  });

  it("caps a long list and says how much it left out", async () => {
    comparison.value = {
      from: { environment: "live", version: "4.10.0-live" },
      to: { environment: "ptu", version: "4.10.1-ptu" },
      catalogues: {
        components: {
          recorded: true,
          counts: { appeared: 0, vanished: 0, changed: 40 },
          appeared: [],
          vanished: [],
          changed: Array.from({ length: 40 }, (_unused, index) => ({
            id: `id-${index}`,
            name: `Component ${index}`,
            fields: ["name"],
          })),
        },
        equipment: empty(),
        commodities: empty(),
        models: empty(),
      },
    };

    const wrapper = await mountPage();
    const panel = catalogueNamed(wrapper, "components");

    expect(panel.findAll(CHANGE)).toHaveLength(25);
    expect(panel.find(MORE).text()).toContain('"count":15');
  });
});
