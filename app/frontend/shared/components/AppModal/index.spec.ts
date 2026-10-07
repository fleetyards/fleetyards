import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineComponent, h, onBeforeUnmount } from "vue";
import { useComlink } from "@/shared/composables/useComlink";
import Component from "./index.vue";

const DirtyForm = defineComponent({
  setup(_, { expose }) {
    expose({ dirty: true });
    return () => h("form");
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

const openDirty = async () => {
  vi.useFakeTimers();
  wrapper = await mountWithDefaults<typeof Component>(Component, {});

  const confirm = vi.fn();
  stopListening = useComlink().on("show-confirm", confirm);

  const modal = wrapper.vm as unknown as {
    open: (options: object) => Promise<void>;
    close: (force?: boolean) => Promise<void>;
  };

  await modal.open({ component: () => Promise.resolve(DirtyForm) });
  vi.runAllTimers();
  await flushPromises();

  return { modal, confirm };
};

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
});
