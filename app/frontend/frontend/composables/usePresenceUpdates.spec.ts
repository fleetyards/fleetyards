import { mount } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { usePresence } from "@/shared/composables/usePresence";

interface Handler {
  channel: { identifier?: string };
  received?: (update: unknown) => void;
  connected?: (event: { reconnect?: boolean }) => void;
  enabled?: { value: boolean };
}

const handlers: Handler[] = [];
const perform = vi.fn(() => Promise.resolve());
const visibility = ref<DocumentVisibilityState>("visible");

vi.mock("@/shared/composables/useSubscription", () => ({
  useSubscription: (options: Handler) => {
    handlers.push(options);

    return { channel: { value: { perform } } };
  },
}));

vi.mock("@vueuse/core", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@vueuse/core")>()),
  useDocumentVisibility: () => visibility,
}));

const { usePresenceUpdates } = await import("./usePresenceUpdates");

const USER = "11111111-1111-1111-1111-111111111111";

const render = () =>
  mount(
    defineComponent({
      setup() {
        usePresenceUpdates();

        return () => h("div");
      },
    }),
  );

beforeEach(() => {
  handlers.length = 0;
  perform.mockClear();
  visibility.value = "visible";
  setActivePinia(createPinia());
  usePresence().resetPresence();
});

describe("usePresenceUpdates", () => {
  it("subscribes to the presence channel", () => {
    render();

    expect(handlers).toHaveLength(1);
    expect(handlers[0].channel.identifier).toBe("UserPresenceChannel");
  });

  it("writes what arrives into the shared map", () => {
    render();

    handlers[0].received?.({ userId: USER, online: true });

    expect(usePresence().isOnline(USER, false)).toBe(true);
  });

  it("drops the map on a reconnect, since nothing is replayed", () => {
    render();

    handlers[0].received?.({ userId: USER, online: true });
    handlers[0].connected?.({ reconnect: true });

    expect(usePresence().isOnline(USER, false)).toBe(false);
  });

  it("keeps the map on the first connect", () => {
    render();

    handlers[0].received?.({ userId: USER, online: true });
    handlers[0].connected?.({ reconnect: false });

    expect(usePresence().isOnline(USER, false)).toBe(true);
  });

  it("reports activity on connect while visible", () => {
    render();

    handlers[0].connected?.({ reconnect: false });

    expect(perform).toHaveBeenCalledWith("active");
  });

  it("reports nothing from a hidden tab", () => {
    visibility.value = "hidden";
    render();

    handlers[0].connected?.({ reconnect: false });

    expect(perform).not.toHaveBeenCalled();
  });

  it("reports activity when the tab becomes visible", async () => {
    visibility.value = "hidden";
    render();

    visibility.value = "visible";
    await nextTick();

    expect(perform).toHaveBeenCalledWith("active");
  });

  it("keeps reporting while the tab stays visible", () => {
    vi.useFakeTimers();
    render();

    vi.advanceTimersByTime(30_000);

    expect(perform).toHaveBeenCalledTimes(1);

    vi.useRealTimers();
  });
});
