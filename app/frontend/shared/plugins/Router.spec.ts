import { createMemoryHistory } from "vue-router";
import { defineComponent } from "vue";
import { createPinia, setActivePinia } from "pinia";
import { setupRouter } from "@/shared/plugins/Router";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { chunkLoadFailures } from "@/shared/utils/ChunkReload";

const Page = defineComponent({ template: "<div />" });

const routes = [
  { path: "/", name: "home", component: Page },
  { path: "/ships", name: "ships", component: Page },
  {
    path: "/broken",
    name: "broken",
    component: () =>
      Promise.reject(
        new TypeError("Failed to fetch dynamically imported module: x"),
      ),
  },
];

const startRouter = async () => {
  const router = setupRouter({ routes, history: createMemoryHistory() });
  await router.push("/");

  return router;
};

const stubLocation = (location: Partial<Location>) =>
  vi.stubGlobal("location", { ...window.location, ...location });

describe("setupRouter after a failed chunk", () => {
  const assign = vi.fn();
  const reload = vi.fn();

  beforeEach(() => {
    setActivePinia(createPinia());
    assign.mockReset();
    reload.mockReset();
    chunkLoadFailures.value = 0;
    sessionStorage.setItem("fleetyards.chunkReloadAt", "1");
    vi.stubEnv("NODE_ENV", "production");
    vi.spyOn(Date, "now").mockReturnValue(30_000);
    stubLocation({ assign, reload, pathname: "/", search: "" });
  });

  afterEach(() => {
    chunkLoadFailures.value = 0;
    sessionStorage.clear();
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  it("navigates in place while chunks load", async () => {
    const router = await startRouter();

    await router.push("/ships");

    expect(reload).not.toHaveBeenCalled();
    expect(router.currentRoute.value.path).toBe("/ships");
  });

  it("reloads once the navigation has landed on another page", async () => {
    const router = await startRouter();
    chunkLoadFailures.value = 1;

    await router.push("/ships");

    expect(router.currentRoute.value.path).toBe("/ships");
    expect(reload).toHaveBeenCalledTimes(1);
    expect(assign).not.toHaveBeenCalled();
  });

  it.each([
    ["a query change", { path: "/", query: { page: "2" } }],
    ["a trailing slash", "/?"],
  ])("does not reload for %s on the same page", async (_, target) => {
    const router = await startRouter();
    chunkLoadFailures.value = 1;

    await router.push(target);

    expect(reload).not.toHaveBeenCalled();
  });

  it("keeps a one-time secret out of a page load", async () => {
    const router = await startRouter();
    chunkLoadFailures.value = 1;

    await router.push({ path: "/ships", query: { secret: "abc" } });

    expect(reload).not.toHaveBeenCalled();
  });

  it("leaves a success on screen to be read", async () => {
    const router = await startRouter();
    chunkLoadFailures.value = 1;
    useNotificationsStore().addMessage({
      id: "saved",
      type: MessageTypesEnum.SUCCESS,
      visible: true,
      persist: false,
      timeout: 3000,
    });

    await router.push("/ships");

    expect(reload).not.toHaveBeenCalled();
  });

  it("loads the address in full when the navigation itself fails", async () => {
    const router = await startRouter();

    await router.push("/broken").catch(() => undefined);

    expect(assign).toHaveBeenCalledWith("/broken");
  });

  it("does not load the address this document came from again", async () => {
    stubLocation({ assign, reload, pathname: "/broken", search: "" });
    const router = await startRouter();

    await router.push("/broken").catch(() => undefined);

    expect(assign).not.toHaveBeenCalled();
  });
});
