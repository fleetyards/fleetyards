import { createMemoryHistory } from "vue-router";
import { defineComponent } from "vue";
import { createPinia, setActivePinia } from "pinia";
import { setupRouter } from "@/shared/plugins/Router";
import { chunkLoadFailed } from "@/shared/utils/ChunkReload";

const Page = defineComponent({ template: "<div />" });

const routes = [
  { path: "/", name: "home", component: Page },
  { path: "/ships", name: "ships", component: Page },
];

const startRouter = async () => {
  const router = setupRouter({ routes, history: createMemoryHistory() });
  await router.push("/");

  return router;
};

describe("setupRouter after a failed chunk", () => {
  const assign = vi.fn();

  beforeEach(() => {
    setActivePinia(createPinia());
    assign.mockReset();
    chunkLoadFailed.value = false;
    vi.stubGlobal("location", { ...window.location, assign });
  });

  afterEach(() => {
    chunkLoadFailed.value = false;
    vi.unstubAllGlobals();
  });

  it("navigates in place while chunks load", async () => {
    const router = await startRouter();

    await router.push("/ships");

    expect(assign).not.toHaveBeenCalled();
    expect(router.currentRoute.value.path).toBe("/ships");
  });

  it("turns the next link into a full page load", async () => {
    const router = await startRouter();
    chunkLoadFailed.value = true;

    await router.push({ path: "/ships", query: { page: "2" } });

    expect(assign).toHaveBeenCalledWith("/ships?page=2");
    expect(router.currentRoute.value.path).toBe("/");
  });

  it("does not load the page for a query change on the same page", async () => {
    const router = await startRouter();
    chunkLoadFailed.value = true;

    await router.push({ path: "/", query: { page: "2" } });

    expect(assign).not.toHaveBeenCalled();
  });

  it("keeps a one-time secret out of a page load", async () => {
    const router = await startRouter();
    chunkLoadFailed.value = true;

    await router.push({ path: "/ships", query: { secret: "abc" } });

    expect(assign).not.toHaveBeenCalled();
  });
});
