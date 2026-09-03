import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref, type Ref } from "vue";
import { useMinimumDuration } from "./useMinimumDuration";

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

// A component, because the composable registers a watcher and hangs its
// clean-up off the surrounding scope.
const render = async (source: Ref<boolean>, minimum?: number) => {
  const held = ref(false);

  const wrapper = mount(
    defineComponent({
      setup() {
        const flag = useMinimumDuration(() => source.value, minimum);

        return () => {
          held.value = flag.value;

          return h("div");
        };
      },
    }),
  );

  await flushPromises();

  return { held, wrapper };
};

const advance = async (ms: number) => {
  vi.advanceTimersByTime(ms);

  await flushPromises();
};

describe("useMinimumDuration", () => {
  it("goes up the moment the source does", async () => {
    const source = ref(false);
    const { held } = await render(source);

    expect(held.value).toBe(false);

    source.value = true;

    await flushPromises();

    expect(held.value).toBe(true);
  });

  it("holds an answer that arrives too fast to be seen", async () => {
    const source = ref(true);
    const { held } = await render(source, 400);

    source.value = false;

    await advance(50);

    expect(held.value).toBe(true);

    await advance(400);

    expect(held.value).toBe(false);
  });

  it("lets go the moment a slow answer arrives", async () => {
    const source = ref(true);
    const { held } = await render(source, 400);

    await advance(500);

    expect(held.value).toBe(true);

    source.value = false;

    await flushPromises();

    expect(held.value).toBe(false);
  });

  it("starts the hold again for a second wait", async () => {
    const source = ref(false);
    const { held } = await render(source, 400);

    source.value = true;

    await advance(10);

    source.value = false;

    await advance(200);

    expect(held.value).toBe(true);

    source.value = true;

    await advance(200);

    // The release the first wait scheduled is not allowed to land on the
    // second one.
    expect(held.value).toBe(true);

    source.value = false;

    await advance(400);

    expect(held.value).toBe(false);
  });

  it("drops its pending release with the scope", async () => {
    const source = ref(true);
    const { wrapper } = await render(source, 400);

    source.value = false;

    await flushPromises();

    expect(vi.getTimerCount()).toBe(1);

    wrapper.unmount();

    expect(vi.getTimerCount()).toBe(0);
  });
});
