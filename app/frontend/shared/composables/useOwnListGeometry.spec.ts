import { flushPromises, mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it } from "vitest";
import { defineComponent, ref, type Component } from "vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import { useOwnListGeometry } from "./useOwnListGeometry";
import { useListGeometryStore } from "@/shared/stores/listGeometry";

// A real store rather than the testing one: what is under test is the round
// trip through it, and the testing pinia stubs the action that writes.
beforeEach(() => {
  setActivePinia(createPinia());
});

type Record = { id: string };

// Stands in for a page with a grid of its own: no FilteredList anywhere, so the
// page is the only thing that can frame it.
const host = (records: Record[], loading: boolean) =>
  defineComponent({
    components: { GridSkeleton: GridSkeleton as unknown as Component },
    setup() {
      const { count } = useOwnListGeometry(
        "inventories",
        ref(records),
        ref(loading),
      );

      return { count, loading };
    },
    template: `
      <GridSkeleton v-if="loading" variant="summary" />
      <span class="count">{{ count }}</span>
    `,
  });

const render = async (component: Component) => {
  const wrapper = mount(component, {
    global: { directives: { Tooltip: {} } },
  });

  await flushPromises();

  return wrapper;
};

describe("useOwnListGeometry", () => {
  it("reserves a short list until this one has been seen", async () => {
    const wrapper = await render(host([], true));

    expect(wrapper.get(".count").text()).toBe("3");
    expect(wrapper.findAll(".grid-skeleton__panel")).toHaveLength(3);
  });

  it("remembers what the answer held and reserves that next time", async () => {
    await render(
      host([{ id: "a" }, { id: "b" }, { id: "c" }, { id: "d" }], false),
    );

    expect(useListGeometryStore().countByKey("inventories")).toBe(4);

    const next = await render(host([], true));

    expect(next.get(".count").text()).toBe("4");
    expect(next.findAll(".grid-skeleton__panel")).toHaveLength(4);
  });

  // A list read mid-load is empty for a reason that says nothing about its size.
  it("takes no reading while the answer is still on its way", async () => {
    await render(host([], true));

    expect(useListGeometryStore().countByKey("inventories")).toBeUndefined();
  });

  // Zero is a reading like any other: a reader with no inventories should have
  // nothing reserved for them.
  it("keeps a list known to be empty at nothing", async () => {
    await render(host([], false));

    expect(useListGeometryStore().countByKey("inventories")).toBe(0);

    const next = await render(host([], true));

    expect(next.get(".count").text()).toBe("0");
    expect(next.findAll(".grid-skeleton__panel")).toHaveLength(0);
  });
});
