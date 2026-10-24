import { mount, type VueWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { useRedirectBack } from "./useRedirectBack";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";

const page = { render: () => null };

let wrapper: VueWrapper | undefined;

const setup = async (fallbackRoute?: { name: string }) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: page },
      { path: "/login", name: "login", component: page },
      { path: "/hangar", name: "hangar", component: page },
    ],
  });

  await router.replace({ name: "login" });

  let redirect!: ReturnType<typeof useRedirectBack>;

  wrapper = mount(
    defineComponent({
      setup() {
        redirect = useRedirectBack(fallbackRoute);

        return () => null;
      },
    }),
    { global: { plugins: [router] } },
  );

  return { router, redirect };
};

describe("useRedirectBack", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
  });

  it("returns to the stored route and clears it", async () => {
    useRedirectBackStore().setBackRoute({ name: "hangar" });
    const { router, redirect } = await setup();

    await redirect.handleRedirect();

    expect(router.currentRoute.value.name).toBe("hangar");
    expect(useRedirectBackStore().backRoute).toBeUndefined();
  });

  it("falls back home when the stored route no longer exists", async () => {
    useRedirectBackStore().setBackRoute({ name: "renamed-long-ago" });
    const { router, redirect } = await setup();

    await redirect.handleRedirect();

    expect(router.currentRoute.value.name).toBe("home");
    expect(useRedirectBackStore().backRoute).toBeUndefined();
  });

  it("uses the given fallback when the stored route no longer exists", async () => {
    useRedirectBackStore().setBackRoute({ name: "renamed-long-ago" });
    const { router, redirect } = await setup({ name: "hangar" });

    await redirect.handleRedirect();

    expect(router.currentRoute.value.name).toBe("hangar");
  });
});
