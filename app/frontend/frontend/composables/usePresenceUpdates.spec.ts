import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { usePresence } from "@/shared/composables/usePresence";
import { useSessionStore } from "@/frontend/stores/session";

interface Handler {
  channel: { identifier?: string };
  received?: (update: unknown) => void;
  connected?: (event: { reconnect?: boolean }) => void;
  disconnected?: () => void;
  enabled?: { value: boolean };
}

const handlers: Handler[] = [];
const perform = vi.fn(() => Promise.resolve());
const visibility = ref<DocumentVisibilityState>("visible");
const idle = ref(false);

vi.mock("@/shared/composables/useSubscription", () => ({
  useSubscription: (options: Handler) => {
    handlers.push(options);

    return { channel: { value: { perform } } };
  },
}));

vi.mock("@vueuse/core", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@vueuse/core")>()),
  useDocumentVisibility: () => visibility,
  useIdle: () => ({ idle }),
}));

const { usePresenceUpdates } = await import("./usePresenceUpdates");

const USER = "11111111-1111-1111-1111-111111111111";

const wrappers: ReturnType<typeof mount>[] = [];

const render = () => {
  const wrapper = mount(
    defineComponent({
      setup() {
        usePresenceUpdates();

        return () => h("div");
      },
    }),
  );

  wrappers.push(wrapper);

  return wrapper;
};

const renderConnected = async () => {
  render();
  handlers[0].connected?.({ reconnect: false });
  await nextTick();
};

beforeEach(() => {
  handlers.length = 0;
  perform.mockClear();
  visibility.value = "visible";
  idle.value = false;
  setActivePinia(createPinia());
  useSessionStore().authenticated = true;
  usePresence().resetPresence();
});

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  vi.useRealTimers();
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

  it("reports activity once connected while in use", async () => {
    await renderConnected();

    expect(perform).toHaveBeenCalledWith("active");
  });

  it("reports nothing before the channel connects", async () => {
    render();
    await nextTick();

    expect(perform).not.toHaveBeenCalled();
  });

  it("reports nothing from a hidden tab", async () => {
    visibility.value = "hidden";
    await renderConnected();

    expect(perform).not.toHaveBeenCalled();
  });

  it("reports nothing when signed out", async () => {
    useSessionStore().authenticated = false;
    await renderConnected();

    expect(perform).not.toHaveBeenCalled();
  });

  it("reports activity when the tab becomes visible", async () => {
    visibility.value = "hidden";
    await renderConnected();

    visibility.value = "visible";
    await nextTick();

    expect(perform).toHaveBeenCalledWith("active");
  });

  it("keeps reporting while the tab is in use", async () => {
    vi.useFakeTimers();
    await renderConnected();
    perform.mockClear();

    vi.advanceTimersByTime(30_000);

    expect(perform).toHaveBeenCalledTimes(1);
    expect(perform).toHaveBeenCalledWith("active");
  });

  it("stops reporting while disconnected", async () => {
    vi.useFakeTimers();
    await renderConnected();

    handlers[0].disconnected?.();
    await nextTick();
    perform.mockClear();

    vi.advanceTimersByTime(60_000);

    expect(perform).not.toHaveBeenCalled();
  });

  it("stops reporting once the tab is hidden, without clearing", async () => {
    vi.useFakeTimers();
    await renderConnected();

    visibility.value = "hidden";
    await nextTick();
    perform.mockClear();

    vi.advanceTimersByTime(60_000);

    expect(perform).not.toHaveBeenCalled();
  });

  it("reports inactive on going idle, then stops reporting", async () => {
    vi.useFakeTimers();
    await renderConnected();

    idle.value = true;
    await nextTick();

    expect(perform).toHaveBeenLastCalledWith("inactive");

    perform.mockClear();
    vi.advanceTimersByTime(60_000);

    expect(perform).not.toHaveBeenCalled();
  });
});
