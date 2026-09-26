import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const addMessage = vi.fn();
const emit = vi.fn();

vi.mock("@/shared/stores/notifications", () => ({
  useNotificationsStore: () => ({ addMessage }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

// The prompt state lives at module level, like the browser event it holds, so
// every test gets a fresh copy of the module.
const load = async () => {
  vi.resetModules();
  return import("./useInstallPrompt");
};

const fireBeforeInstallPrompt = (outcome: "accepted" | "dismissed") => {
  const event = new Event("beforeinstallprompt", { cancelable: true });
  const prompt = vi.fn().mockResolvedValue(undefined);
  Object.assign(event, {
    prompt,
    userChoice: Promise.resolve({ outcome }),
  });
  window.dispatchEvent(event);
  return { event, prompt };
};

// A visit that is not the first: the stored first sighting predates it.
const returningVisitor = () => {
  localStorage.setItem(
    "fy.install-prompt",
    JSON.stringify({ firstSeenAt: "2026-01-01T00:00:00.000Z" }),
  );
};

const setUserAgent = (userAgent: string) => {
  vi.spyOn(navigator, "userAgent", "get").mockReturnValue(userAgent);
};

beforeEach(() => {
  localStorage.clear();
  sessionStorage.clear();
  addMessage.mockReset();
  emit.mockReset();
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("useInstallPrompt", () => {
  it("cannot install before the browser offers it", async () => {
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();

    expect(useInstallPrompt().canInstall.value).toBe(false);
  });

  it("holds on to the browser's prompt and keeps its own banner away", async () => {
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();

    const { event } = fireBeforeInstallPrompt("accepted");

    expect(event.defaultPrevented).toBe(true);
    expect(useInstallPrompt().canInstall.value).toBe(true);
  });

  it("shows the browser's prompt once and forgets it after", async () => {
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();
    const { prompt } = fireBeforeInstallPrompt("accepted");

    const { install, canInstall } = useInstallPrompt();

    await expect(install()).resolves.toBe("accepted");
    expect(prompt).toHaveBeenCalledOnce();
    expect(canInstall.value).toBe(false);
  });

  it("explains the share sheet on iOS, which has no prompt", async () => {
    setUserAgent(
      "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15",
    );
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();

    const { canInstall, install } = useInstallPrompt();

    expect(canInstall.value).toBe(true);

    await install();

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ component: expect.any(Function) }),
    );
  });

  it("never offers on the first visit", async () => {
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();
    fireBeforeInstallPrompt("accepted");

    expect(useInstallPrompt().offer("eventSignup")).toBe(false);
    expect(addMessage).not.toHaveBeenCalled();
  });

  it("offers on a later visit, then stays quiet through the cooldown", async () => {
    returningVisitor();
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();
    fireBeforeInstallPrompt("accepted");

    const { offer } = useInstallPrompt();

    expect(offer("eventSignup")).toBe(true);
    expect(addMessage).toHaveBeenCalledOnce();

    expect(offer("eventSignup")).toBe(false);
    expect(addMessage).toHaveBeenCalledOnce();
  });

  it("remembers the cooldown across reloads", async () => {
    returningVisitor();
    let module = await load();
    module.captureInstallPrompt();
    fireBeforeInstallPrompt("accepted");
    module.useInstallPrompt().offer("eventSignup");

    module = await load();
    module.captureInstallPrompt();
    fireBeforeInstallPrompt("accepted");

    expect(module.useInstallPrompt().offer("eventSignup")).toBe(false);
  });

  it("never offers once the app is installed", async () => {
    returningVisitor();
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();
    window.dispatchEvent(new Event("appinstalled"));
    fireBeforeInstallPrompt("accepted");

    expect(useInstallPrompt().offer("eventSignup")).toBe(false);
  });

  it("counts a dismissed browser prompt against the cooldown", async () => {
    returningVisitor();
    const { captureInstallPrompt, useInstallPrompt } = await load();
    captureInstallPrompt();
    fireBeforeInstallPrompt("dismissed");

    const { install, offer } = useInstallPrompt();
    await install();
    fireBeforeInstallPrompt("dismissed");

    expect(offer("eventSignup")).toBe(false);
  });
});
