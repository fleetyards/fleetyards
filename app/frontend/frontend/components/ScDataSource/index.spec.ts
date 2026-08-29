import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { setActivePinia, createPinia } from "pinia";
import { ref, nextTick } from "vue";

const live = { environment: "live", version: "1.0.0", default: true };
const ptu = { environment: "ptu", version: "1.1.0", default: false };

const sources = ref<{ items: (typeof live)[] } | undefined>(undefined);
vi.mock("@/services/fyApi", () => ({
  useScDataSources: () => ({ data: sources }),
}));

const clear = vi.fn();
const refetchQueries = vi.fn();
vi.mock("@tanstack/vue-query", () => ({
  useQueryClient: () => ({ clear, refetchQueries }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import ScDataSourceBar from "./index.vue";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";

// The teleport waits for `onMounted`, so the first render carries nothing.
const mountBar = async () => {
  const wrapper = mount(ScDataSourceBar, {
    global: {
      stubs: {
        // Rendered in place: the bar teleports into the header, which does not
        // exist in a mounted component's own tree.
        Teleport: true,
        Btn: { template: "<button><slot /></button>" },
        BtnGroup: { template: "<div><slot /></div>" },
      },
    },
  });

  await nextTick();

  return wrapper;
};

describe("ScDataSourceBar", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    sources.value = undefined;
    clear.mockClear();
    refetchQueries.mockClear();
  });

  it("stays out of the way when there is only one build", async () => {
    sources.value = { items: [live] };
    const wrapper = await mountBar();

    expect(wrapper.find(".sc-data-source").exists()).toBe(false);
  });

  it("offers every build the server named", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountBar();

    expect(wrapper.find(".sc-data-source").exists()).toBe(true);
    expect(wrapper.text()).toContain("live");
    expect(wrapper.text()).toContain("ptu");
  });

  // Everything cached was fetched against another build, so it all goes --
  // otherwise the old build's data shows under the new label until each query
  // happens to refetch.
  it("throws the cache away when the build changes", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountBar();

    await wrapper.findAll("button")[1].trigger("click");

    expect(useScDataSourceStore().requestParam).toBe("ptu");
    expect(clear).toHaveBeenCalledOnce();
    expect(refetchQueries).toHaveBeenCalledOnce();
  });

  it("does nothing when the build already selected is picked again", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountBar();

    await wrapper.findAll("button")[0].trigger("click");

    expect(clear).not.toHaveBeenCalled();
  });

  it("says so when the build is not the default one", async () => {
    sources.value = { items: [live, ptu] };
    const wrapper = await mountBar();

    expect(wrapper.find(".sc-data-source-off-default").exists()).toBe(false);

    await wrapper.findAll("button")[1].trigger("click");

    expect(wrapper.find(".sc-data-source-off-default").exists()).toBe(true);
  });
});
