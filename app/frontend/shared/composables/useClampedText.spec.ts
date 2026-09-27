import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, ref } from "vue";
import { useClampedText } from "./useClampedText";

const clampedHeight = 80;
let fullHeight = 0;

beforeEach(() => {
  vi.spyOn(HTMLElement.prototype, "clientHeight", "get").mockImplementation(
    () => clampedHeight,
  );
  vi.spyOn(HTMLElement.prototype, "scrollHeight", "get").mockImplementation(
    () => fullHeight,
  );
});

afterEach(() => {
  vi.restoreAllMocks();
});

const render = async (height: number) => {
  fullHeight = height;
  const text = ref("first");

  const wrapper = mount(
    defineComponent({
      setup() {
        const el = ref<HTMLElement>();

        return { el, text, ...useClampedText(el, () => text.value) };
      },
      template: `<p ref="el">{{ text }}</p>`,
    }),
  );

  await flushPromises();

  return { wrapper, text };
};

describe("useClampedText", () => {
  it("reports no overflow when the text fits the clamp", async () => {
    const { wrapper } = await render(clampedHeight);

    expect(wrapper.vm.overflows).toBe(false);
  });

  it("reports overflow when the text is longer than the clamp", async () => {
    const { wrapper } = await render(200);

    expect(wrapper.vm.overflows).toBe(true);
  });

  it("measures again when the text changes at the same clamped height", async () => {
    const { wrapper, text } = await render(clampedHeight);

    fullHeight = 200;
    text.value = "second";
    await flushPromises();

    expect(wrapper.vm.overflows).toBe(true);
  });

  it("collapses again when the text changes", async () => {
    const { wrapper, text } = await render(200);

    wrapper.vm.expanded = true;
    text.value = "second";
    await flushPromises();

    expect(wrapper.vm.expanded).toBe(false);
  });
});
