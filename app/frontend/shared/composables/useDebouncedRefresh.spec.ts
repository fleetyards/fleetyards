import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useDebouncedRefresh, REFRESH_WAIT_MS } from "./useDebouncedRefresh";

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

// A component, because the composable hangs its clean-up off the surrounding
// scope.
const render = (refresh: () => unknown) => {
  let debounced: ReturnType<typeof useDebouncedRefresh> | undefined;

  const wrapper = mount(
    defineComponent({
      setup() {
        debounced = useDebouncedRefresh(refresh);

        return () => h("div");
      },
    }),
  );

  return { wrapper, call: () => debounced?.() };
};

describe("useDebouncedRefresh", () => {
  it("collapses a burst of calls into one refresh", () => {
    const refresh = vi.fn();

    const { call } = render(refresh);

    call();
    call();
    call();

    expect(refresh).not.toHaveBeenCalled();

    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).toHaveBeenCalledOnce();
  });

  /*
   * Unsubscribing from a channel cancels no timer, so a broadcast that lands
   * just before a navigation would refetch into a page that has gone away.
   */
  it("drops a pending refresh when the component goes away", () => {
    const refresh = vi.fn();

    const { wrapper, call } = render(refresh);

    call();
    wrapper.unmount();

    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).not.toHaveBeenCalled();
  });
});
