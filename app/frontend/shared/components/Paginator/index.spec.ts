import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { BaseList } from "@/services/fyApi";

const listWith = (pagination: Partial<BaseList["meta"]["pagination"]>) =>
  ({
    meta: {
      pagination: {
        totalCount: 0,
        currentPage: 1,
        totalPages: 0,
        perPage: 25,
        ...pagination,
      },
    },
  }) as BaseList;

const mount = (queryResultRef: BaseList | undefined) =>
  mountWithDefaults(Component, {
    props: { queryResultRef, updatePerPage: () => {} },
  });

// A page link renders as an anchor once it leads anywhere, so the arrows are
// only countable as components.
const arrows = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAllComponents({ name: "BaseBtn" });

describe("Paginator", () => {
  it("holds its place while the list is still loading", async () => {
    const wrapper = await mount(undefined);

    expect(wrapper.get(".pagination__pages").text()).toBe("1 of –");
    expect(arrows(wrapper).every((arrow) => arrow.props("disabled"))).toBe(
      true,
    );
  });

  it("waits for the response before offering per-page steps", async () => {
    const wrapper = await mount(undefined);

    expect(wrapper.findComponent({ name: "PerPageDropdown" }).exists()).toBe(
      false,
    );
  });

  it("counts an empty result as one page rather than none", async () => {
    const wrapper = await mount(listWith({ totalCount: 0, totalPages: 0 }));

    expect(wrapper.get(".pagination__pages").text()).toBe("1 of 1");
    expect(arrows(wrapper)).toHaveLength(0);
  });

  it("drops the arrows on a result that fits one page", async () => {
    const wrapper = await mount(listWith({ totalCount: 8, totalPages: 1 }));

    expect(wrapper.get(".pagination__pages").text()).toBe("1 of 1");
    expect(arrows(wrapper)).toHaveLength(0);
  });

  it("offers the way forward but not back on the first of many pages", async () => {
    const wrapper = await mount(listWith({ totalCount: 248, totalPages: 10 }));

    expect(wrapper.get(".pagination__pages").text()).toBe("1 of 10");

    const [previous, next] = arrows(wrapper);

    expect(previous.props("disabled")).toBe(true);
    expect(next.props("disabled")).toBe(false);
  });

  it("renders nothing for an endpoint that does not paginate", async () => {
    const wrapper = await mount({ meta: {} } as BaseList);

    expect(wrapper.find(".pagination").exists()).toBe(false);
  });

  describe("page size", () => {
    const withSteps = listWith({
      totalCount: 248,
      totalPages: 5,
      defaultPerPage: 60,
      perPageSteps: [15, 30, 60, 90],
    });

    const mountWithSize = (perPage?: string) => {
      const updatePerPage = vi.fn();

      return mountWithDefaults(Component, {
        props: { queryResultRef: withSteps, updatePerPage, perPage },
      }).then((wrapper) => ({ wrapper, updatePerPage }));
    };

    const pick = (wrapper: Awaited<ReturnType<typeof mount>>, step: number) =>
      wrapper
        .findComponent({ name: "PerPageDropdown" })
        .vm.$emit("change", step);

    it("offers the steps to a handler bound as a prop", async () => {
      const { wrapper } = await mountWithSize();

      expect(wrapper.findComponent({ name: "PerPageDropdown" }).exists()).toBe(
        true,
      );
    });

    it("offers the steps to a handler bound as a listener", async () => {
      const onUpdatePerPage = vi.fn();
      const wrapper = await mountWithDefaults(Component, {
        props: { queryResultRef: withSteps, onUpdatePerPage },
      });

      await pick(wrapper, 30);

      expect(onUpdatePerPage).toHaveBeenCalledWith(30);
    });

    it("falls back to the default when the size in use is no step", async () => {
      const { updatePerPage } = await mountWithSize("25");

      expect(updatePerPage).toHaveBeenCalledWith(60);
    });

    it("keeps a size in use that is a step", async () => {
      const { updatePerPage } = await mountWithSize("90");

      expect(updatePerPage).not.toHaveBeenCalled();
    });

    it("passes on a new size", async () => {
      const { wrapper, updatePerPage } = await mountWithSize();

      await pick(wrapper, 30);

      expect(updatePerPage).toHaveBeenCalledWith(30);
    });

    it("ignores the default size picked again", async () => {
      const { wrapper, updatePerPage } = await mountWithSize();

      await pick(wrapper, 60);

      expect(updatePerPage).not.toHaveBeenCalled();
    });

    it("ignores the size from the URL picked again", async () => {
      const { wrapper, updatePerPage } = await mountWithSize("30");

      await pick(wrapper, 30);

      expect(updatePerPage).not.toHaveBeenCalled();
    });

    it("marks the size from the URL as the active step", async () => {
      const { wrapper } = await mountWithSize("30");

      const active = wrapper
        .findAllComponents({ name: "BaseBtn" })
        .filter((btn) => btn.props("active"));

      expect(active.map((btn) => btn.text())).toEqual(["30"]);
    });
  });
});
