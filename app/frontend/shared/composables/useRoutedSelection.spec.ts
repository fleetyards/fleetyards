import { beforeEach, describe, expect, it } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { createRouter, createWebHistory } from "vue-router";
import { useRoutedSelection } from "./useRoutedSelection";

const setup = async (phone: boolean, path = "/list") => {
  // Web history rather than memory history: only it records which entry is
  // behind the current one.
  const router = createRouter({
    history: createWebHistory(),
    routes: [{ path: "/list", component: { render: () => null } }],
  });

  await router.replace(path);

  const mobile = ref(phone);
  let selection!: ReturnType<typeof useRoutedSelection>;

  mount(
    defineComponent({
      setup() {
        selection = useRoutedSelection({ key: "open", mobile });

        return () => null;
      },
    }),
    { global: { plugins: [router] } },
  );

  return { router, mobile, selection };
};

const nextNavigation = (router: Awaited<ReturnType<typeof setup>>["router"]) =>
  new Promise((resolve) => {
    const stop = router.afterEach(() => {
      stop();
      resolve(undefined);
    });
  });

const travel = async (
  router: Awaited<ReturnType<typeof setup>>["router"],
  delta: number,
) => {
  const arrived = nextNavigation(router);

  router.go(delta);
  await arrived;
  await flushPromises();
};

beforeEach(() => {
  window.history.replaceState(null, "", "/");
});

describe("useRoutedSelection", () => {
  it("keeps the URL out of it beside the list", async () => {
    const { router, selection } = await setup(false);

    selection.open("a");
    await flushPromises();

    expect(selection.selectedId.value).toBe("a");
    expect(router.currentRoute.value.query.open).toBeUndefined();
  });

  it("takes a history entry on a phone and gives it back on close", async () => {
    const { router, selection } = await setup(true);

    selection.open("a");
    await flushPromises();

    expect(router.currentRoute.value.query.open).toBe("a");

    const closed = nextNavigation(router);
    selection.close();
    await closed;

    expect(selection.selectedId.value).toBeUndefined();
    expect(router.currentRoute.value.fullPath).toBe("/list");
  });

  it("closes when the back gesture removes the entry", async () => {
    const { router, selection } = await setup(true);

    selection.open("a");
    await flushPromises();
    await travel(router, -1);

    expect(selection.selectedId.value).toBeUndefined();
  });

  it("starts from the URL, and replaces that entry on close", async () => {
    const { router, selection } = await setup(true, "/list?open=b");

    expect(selection.selectedId.value).toBe("b");

    selection.close();
    await flushPromises();

    expect(router.currentRoute.value.fullPath).toBe("/list");
  });

  it("keeps a search typed while open, and only drops the key on close", async () => {
    const { router, selection } = await setup(true);

    selection.open("a");
    await flushPromises();
    await router.push({ query: { open: "a", q: "ship" } });
    await flushPromises();

    selection.close();
    await flushPromises();

    expect(router.currentRoute.value.fullPath).toBe("/list?q=ship");
  });

  it("steps back over the entry after a back and forward gesture too", async () => {
    const { router, selection } = await setup(true);

    selection.open("a");
    await flushPromises();
    await travel(router, -1);
    await travel(router, 1);

    expect(selection.selectedId.value).toBe("a");

    const closed = nextNavigation(router);
    selection.close();
    await closed;

    expect(router.currentRoute.value.fullPath).toBe("/list");
    expect(router.options.history.state.forward).toBe("/list?open=a");
  });

  it("steps back over the entry on a list with a hash", async () => {
    const { router, selection } = await setup(true, "/list#top");

    selection.open("a");
    await flushPromises();

    const closed = nextNavigation(router);
    selection.close();
    await closed;

    expect(router.currentRoute.value.fullPath).toBe("/list#top");
    expect(router.options.history.state.forward).not.toBeNull();
  });
});
