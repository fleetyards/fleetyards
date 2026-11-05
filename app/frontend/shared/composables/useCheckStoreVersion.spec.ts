import { defineComponent, h } from "vue";
import { mount } from "@vue/test-utils";
import { useCheckStoreVersion } from "./useCheckStoreVersion";
import type { FltYrdsStore } from "@/shared/stores/types";

const refetch = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", () => ({
  useVersion: () => ({ data: ref(undefined), refetch }),
}));

const mountComposable = (checkOnResume = true) =>
  mount(
    defineComponent({
      setup() {
        useCheckStoreVersion(
          {
            storeVersion: window.STORE_VERSION,
            updateVersion: vi.fn(),
            $reset: vi.fn(),
            $patch: vi.fn(),
          } as unknown as FltYrdsStore,
          { checkOnResume },
        );

        return () => h("div");
      },
    }),
  );

const becomeVisible = (state: DocumentVisibilityState = "visible") => {
  vi.spyOn(document, "visibilityState", "get").mockReturnValue(state);
  document.dispatchEvent(new Event("visibilitychange"));
};

describe("useCheckStoreVersion", () => {
  beforeEach(() => {
    refetch.mockReset();
    refetch.mockResolvedValue({ isError: false });
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it("checks the version when the app comes back from the background", () => {
    const wrapper = mountComposable();

    vi.advanceTimersByTime(60_000);
    becomeVisible();

    expect(refetch).toHaveBeenCalledTimes(1);
    wrapper.unmount();
  });

  it("does not check when the app goes to the background", () => {
    const wrapper = mountComposable();

    vi.advanceTimersByTime(60_000);
    becomeVisible("hidden");

    expect(refetch).not.toHaveBeenCalled();
    wrapper.unmount();
  });

  it("does not check again on a quick switch between apps", () => {
    const wrapper = mountComposable();

    vi.advanceTimersByTime(60_000);
    becomeVisible();
    vi.advanceTimersByTime(59_999);
    becomeVisible();

    expect(refetch).toHaveBeenCalledTimes(1);
    wrapper.unmount();
  });

  it("tries again on the next return after a failed check", async () => {
    refetch.mockResolvedValueOnce({ isError: true });
    const wrapper = mountComposable();

    vi.advanceTimersByTime(60_000);
    becomeVisible();
    await vi.advanceTimersByTimeAsync(1);
    becomeVisible();

    expect(refetch).toHaveBeenCalledTimes(2);
    wrapper.unmount();
  });

  it("leaves resuming alone unless asked to check", () => {
    const wrapper = mountComposable(false);

    vi.advanceTimersByTime(60_000);
    becomeVisible();

    expect(refetch).not.toHaveBeenCalled();
    wrapper.unmount();
  });

  it("stops listening once unmounted", () => {
    mountComposable().unmount();

    vi.advanceTimersByTime(60_000);
    becomeVisible();

    expect(refetch).not.toHaveBeenCalled();
  });
});
