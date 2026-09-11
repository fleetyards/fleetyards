import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, enableAutoUnmount } from "@vue/test-utils";
import { setActivePinia, createPinia } from "pinia";
import { ref, nextTick } from "vue";

const live = { environment: "live", version: "4.9.0", default: true };
const ptu = { environment: "ptu", version: "4.10.0", default: false };
const eptu = { environment: "eptu", version: "4.11.0", default: false };

const sources = ref<{ items: (typeof live)[] } | undefined>(undefined);
vi.mock("@/services/fyApi", () => ({
  useScDataSources: () => ({ data: sources }),
}));

const invalidateQueries = vi.fn();
vi.mock("@tanstack/vue-query", () => ({
  useQueryClient: () => ({ invalidateQueries }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import ScDataSourceSwitch from "./index.vue";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";

const ITEM = ".sc-data-source-switch";
const BUILD = ".sc-data-source-switch__build";
const PREVIEW = ".sc-data-source-switch--preview";

const mountSwitch = async () => {
  const wrapper = mount(ScDataSourceSwitch, {
    global: {
      // Stubbed rather than rendered: the real item reaches for the router and
      // for tooltips, neither of which this component decides anything about.
      // Its slot still renders, because the build's name lives in there.
      stubs: { NavItem: true },
      renderStubDefaultSlot: true,
    },
  });

  await nextTick();

  return wrapper;
};

const item = (wrapper: Awaited<ReturnType<typeof mountSwitch>>) =>
  wrapper.find(ITEM);

const press = async (wrapper: Awaited<ReturnType<typeof mountSwitch>>) => {
  await wrapper.findComponent({ name: "NavItem" }).props("action")();
  await nextTick();
};

// `sources` is a module ref every mounted switch watches, so a wrapper left
// standing keeps answering later tests: it writes the new list into the pinia it
// was mounted with, and whichever store wrote last is the one the test's own
// `useScDataSourceStore()` no longer holds. That made assertions pass against a
// component that had never seen the state under test.
enableAutoUnmount(afterEach);

describe("ScDataSourceSwitch", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    sources.value = undefined;
    invalidateQueries.mockClear();
  });

  it("offers the choice on every page", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountSwitch();

    expect(item(wrapper).exists()).toBe(true);
  });

  // A ptu cycle ends by live catching up, and the server stops offering the
  // preview from that moment -- which is the whole of how the row goes away.
  it("stays out of the navigation when there is only one build", async () => {
    sources.value = { items: [live] };
    const wrapper = await mountSwitch();

    expect(item(wrapper).exists()).toBe(false);
  });

  // The row says which build in words, where every other row has an icon: one
  // glyph cannot tell two builds apart, and this is the one row about which.
  it("names the build being read", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountSwitch();

    expect(wrapper.find(BUILD).text()).toBe("live");
  });

  // Everything cached was fetched against another build, so it all goes --
  // otherwise the old build's data shows under the new label until each query
  // happens to refetch.
  // `clear()` was the first attempt and it made the switch do nothing: it
  // removes the queries, so the mounted observers have none left to refetch and
  // no request goes out. Invalidating is what reloads the page.
  it("invalidates every query when the build changes", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountSwitch();

    await press(wrapper);

    expect(useScDataSourceStore().requestParam).toBe("ptu");
    expect(invalidateQueries).toHaveBeenCalledOnce();
  });

  it("goes back to the default build on the next press", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountSwitch();

    await press(wrapper);
    await press(wrapper);

    expect(useScDataSourceStore().requestParam).toBeUndefined();
    expect(wrapper.find(BUILD).text()).toBe("live");
  });

  // Two states, never a list: a second preview channel would make the switch
  // offer the newer of them rather than turn into a menu.
  it("offers the newest preview when more than one is available", async () => {
    sources.value = { items: [live, ptu, eptu] };
    const wrapper = await mountSwitch();

    await press(wrapper);

    expect(useScDataSourceStore().requestParam).toBe("eptu");
  });

  // The name is the marker and it takes the warning colour through this class.
  // No rail: on every other row that means "this is the open page".
  it("marks the row while the build is not the default one", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountSwitch();

    expect(wrapper.find(PREVIEW).exists()).toBe(false);

    await press(wrapper);

    expect(wrapper.find(PREVIEW).exists()).toBe(true);
    expect(wrapper.find(BUILD).text()).toBe("ptu");
  });
});
