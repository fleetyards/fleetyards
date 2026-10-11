import { describe, expect, it } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import { useRoutedSelection } from "./useRoutedSelection";

const setup = async (phone: boolean, path = "/list") => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/list", component: { render: () => null } }],
  });

  await router.push(path);

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

    selection.close();
    await flushPromises();

    expect(selection.selectedId.value).toBeUndefined();
    expect(router.currentRoute.value.fullPath).toBe("/list");
  });

  it("closes when the back gesture removes the entry", async () => {
    const { router, selection } = await setup(true);

    selection.open("a");
    await flushPromises();
    router.back();
    await flushPromises();

    expect(selection.selectedId.value).toBeUndefined();
  });

  it("starts from the URL, and replaces that entry on close", async () => {
    const { router, selection } = await setup(true, "/list?open=b");

    expect(selection.selectedId.value).toBe("b");

    selection.close();
    await flushPromises();

    expect(router.currentRoute.value.fullPath).toBe("/list");
  });
});
