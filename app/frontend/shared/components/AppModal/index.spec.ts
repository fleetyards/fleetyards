import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { useComlink } from "@/shared/composables/useComlink";
import Component from "./index.vue";
import { useModalDirty } from "./dirty";
import { createMemoryHistory, createRouter } from "vue-router";

const DirtyForm = defineComponent({
  setup(_, { expose }) {
    expose({ dirty: true });
    return () => h("form");
  },
});

const PlainForm = defineComponent({
  setup() {
    return () =>
      h("div", [
        h(
          "form",
          { "data-test": "form", onSubmit: (e: Event) => e.preventDefault() },
          [h("input", { "data-test": "field" })],
        ),
        h("input", { "data-test": "search" }),
      ]);
  },
});

const reportsDirty = { value: true };

const NestedPicker = defineComponent({
  setup() {
    useModalDirty(() => reportsDirty.value);
    return () => h("input", { "data-test": "picker-search" });
  },
});

// Wrapped, the way a picker sits inside its caller's modal.
const WrappedPicker = defineComponent({
  setup() {
    return () => h("form", [h(NestedPicker)]);
  },
});

let wrapper: VueWrapper | undefined;
let stopListening: (() => void) | undefined;

afterEach(() => {
  stopListening?.();
  wrapper?.unmount();
  wrapper = undefined;
  vi.useRealTimers();
});

const openWith = async (content: object) => {
  vi.useFakeTimers();
  wrapper = await mountWithDefaults<typeof Component>(Component, {});

  const confirm = vi.fn();
  stopListening = useComlink().on("show-confirm", confirm);

  const modal = wrapper.vm as unknown as {
    open: (options: object) => Promise<void>;
    close: (force?: boolean) => Promise<void>;
  };

  await modal.open({ component: () => Promise.resolve(content) });
  vi.runAllTimers();
  await flushPromises();

  return { modal, confirm };
};

const openDirty = () => openWith(DirtyForm);

describe("AppModal", () => {
  it("asks before closing over unsaved input", async () => {
    const { modal, confirm } = await openDirty();

    await modal.close();

    expect(confirm).toHaveBeenCalledTimes(1);
  });

  // A modal that saved closes itself with force; what was typed is not lost.
  it("closes without asking when the modal closes itself after saving", async () => {
    const { modal, confirm } = await openDirty();

    await modal.close(true);
    vi.runAllTimers();
    await flushPromises();

    expect(confirm).not.toHaveBeenCalled();
    expect(wrapper?.find('[data-test="modal"]').exists()).toBe(false);
  });

  it("reports itself closed only once its content has unmounted", async () => {
    vi.useFakeTimers();
    wrapper = await mountWithDefaults<typeof Component>(Component, {});

    const order: string[] = [];
    const Content = defineComponent({
      setup() {
        onBeforeUnmount(() => order.push("unmounted"));
        return () => h("div");
      },
    });
    stopListening = useComlink().on("modal-closed", () => {
      order.push("closed");
    });

    const modal = wrapper.vm as unknown as {
      open: (options: object) => Promise<void>;
      close: (force?: boolean) => Promise<void>;
    };
    await modal.open({ component: () => Promise.resolve(Content) });
    vi.runAllTimers();
    await flushPromises();

    await modal.close(true);
    vi.runAllTimers();
    await flushPromises();

    expect(order).toEqual(["unmounted", "closed"]);
  });

  describe("on a page change", () => {
    const Page = { template: "<div />" };

    const mountOnRouter = async () => {
      vi.useFakeTimers();

      const router = createRouter({
        history: createMemoryHistory(),
        routes: [
          { path: "/one/", component: Page },
          { path: "/two/", component: Page },
        ],
      });
      await router.push("/one/");

      wrapper = await mountWithDefaults<typeof Component>(Component, {
        plugins: [router],
      });

      const modal = wrapper.vm as unknown as {
        open: (options: object) => Promise<void>;
      };

      return { router, modal };
    };

    const settle = async () => {
      await flushPromises();
      vi.runAllTimers();
      await flushPromises();
    };

    it("closes, unsaved input or not", async () => {
      const { router, modal } = await mountOnRouter();
      const confirm = vi.fn();
      stopListening = useComlink().on("show-confirm", confirm);

      await modal.open({ component: () => Promise.resolve(DirtyForm) });
      await settle();

      await router.push("/two/");
      await settle();

      expect(confirm).not.toHaveBeenCalled();
      expect(wrapper?.find('[data-test="modal"]').exists()).toBe(false);
    });

    it("keeps a modal the new page opens on arrival", async () => {
      const { router, modal } = await mountOnRouter();

      await modal.open({ component: () => Promise.resolve(DirtyForm) });
      await settle();

      await router.push("/two/");
      await flushPromises();
      await modal.open({ component: () => Promise.resolve(DirtyForm) });
      await settle();

      expect(wrapper?.find('[data-test="modal"]').exists()).toBe(true);
    });

    it("stays open while the address still asks for it", async () => {
      const { router, modal } = await mountOnRouter();

      await router.push("/one/?modal=support");
      await modal.open({ component: () => Promise.resolve(DirtyForm) });
      await settle();

      await router.push("/two/?modal=support");
      await settle();

      expect(wrapper?.find('[data-test="modal"]').exists()).toBe(true);
    });

    it("stays open when only the query changes", async () => {
      const { router, modal } = await mountOnRouter();

      await modal.open({ component: () => Promise.resolve(DirtyForm) });
      await settle();

      await router.push("/one/?tab=log");
      await settle();

      expect(wrapper?.find('[data-test="modal"]').exists()).toBe(true);
    });
  });
  describe("without a dirty flag of its own", () => {
    it("asks once something in a form was edited", async () => {
      const { modal, confirm } = await openWith(PlainForm);

      await wrapper!.get("[data-test='field']").trigger("input");
      await modal.close();

      expect(confirm).toHaveBeenCalledTimes(1);
    });

    it("closes without asking once the form was submitted", async () => {
      const { modal, confirm } = await openWith(PlainForm);

      await wrapper!.get("[data-test='field']").trigger("input");
      await wrapper!.get("[data-test='form']").trigger("submit");
      await modal.close();

      expect(confirm).not.toHaveBeenCalled();
    });

    it("ignores input outside a form", async () => {
      const { modal, confirm } = await openWith(PlainForm);

      await wrapper!.get("[data-test='search']").trigger("input");
      await modal.close();

      expect(confirm).not.toHaveBeenCalled();
    });
  });
  describe("with a nested component that reports its own state", () => {
    it("asks while it reports unsaved state", async () => {
      reportsDirty.value = true;
      const { modal, confirm } = await openWith(WrappedPicker);

      await modal.close();

      expect(confirm).toHaveBeenCalledTimes(1);
    });

    it("trusts it over form events", async () => {
      reportsDirty.value = false;
      const { modal, confirm } = await openWith(WrappedPicker);

      await wrapper!.get("[data-test='picker-search']").trigger("input");
      await modal.close();

      expect(confirm).not.toHaveBeenCalled();
    });
  });
});
