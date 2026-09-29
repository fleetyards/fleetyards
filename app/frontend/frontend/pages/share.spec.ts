import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";

const query: Record<string, string> = {};

const replace = vi.fn(() => Promise.resolve());

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () => ({ query }),
  useRouter: () => ({ replace }),
}));

const { default: SharePage } = await import("./share.vue");

const open = async (shared: Record<string, string>) => {
  Object.assign(query, shared);
  mount(SharePage, { global: { stubs: { Loader: true } } });
  await flushPromises();
};

describe("SharePage", () => {
  const locationReplace = vi.fn();

  beforeEach(() => {
    window.FRONTEND_ENDPOINT = "https://fleetyards.net";
    window.SHORT_DOMAIN = "fltyrd.net";
    vi.stubGlobal("location", { ...window.location, replace: locationReplace });
  });

  afterEach(() => {
    Object.keys(query).forEach((key) => delete query[key]);
    replace.mockClear();
    locationReplace.mockClear();
    vi.unstubAllGlobals();
  });

  it("opens a shared Fleetyards page in place of itself", async () => {
    await open({ url: "https://fleetyards.net/ships/carrack/" });

    expect(replace).toHaveBeenCalledWith("/ships/carrack/");
  });

  it("leaves a short link to the server", async () => {
    await open({ text: "Join us https://fltyrd.net/fi/abc123" });

    expect(locationReplace).toHaveBeenCalledWith(
      "https://fltyrd.net/fi/abc123",
    );
    expect(replace).not.toHaveBeenCalled();
  });

  it("searches ships for shared words", async () => {
    await open({ text: "Hull C" });

    expect(replace).toHaveBeenCalledWith({
      name: "ships",
      query: { searchCont: "Hull C" },
    });
  });

  it("goes home when nothing usable was shared", async () => {
    await open({});

    expect(replace).toHaveBeenCalledWith({ name: "home" });
  });
});
