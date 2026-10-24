import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { useRedirectBack } from "./useRedirectBack";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";

const page = { render: () => null };

const setup = async () => {
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

  mount(
    defineComponent({
      setup() {
        redirect = useRedirectBack();

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
});
