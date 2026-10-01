import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const { installed } = vi.hoisted(() => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const vue = require("vue");

  return { installed: vue.ref(true) };
});

vi.mock("@vueuse/core", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@vueuse/core")>()),
  useMediaQuery: () => installed,
}));

import BackButton from "./index.vue";

const Stub = { render: () => null };

const mountAfter = async (paths: string[]) => {
  // Web history rather than memory history: only it records `state.back`.
  const router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/ships/:slug", name: "ship", component: Stub },
      { path: "/components/:slug", name: "component", component: Stub },
    ],
  });

  await router.replace(paths[0]);
  for (const path of paths.slice(1)) {
    await router.push(path);
  }
  await router.isReady();

  const wrapper = await mountWithDefaults(BackButton, { plugins: [router] });

  return { wrapper, router };
};

const backButton = (
  wrapper: Awaited<ReturnType<typeof mountAfter>>["wrapper"],
) => wrapper.find('[data-test="app-navigation-back"]');

describe("AppNavigationBackButton", () => {
  beforeEach(() => {
    installed.value = true;
    window.history.replaceState(null, "", "/");
  });

  it("is hidden on the first page of an installed app", async () => {
    const { wrapper } = await mountAfter(["/ships/carrack"]);

    expect(backButton(wrapper).exists()).toBe(false);
  });

  it("appears once a cross link has been followed", async () => {
    const { wrapper } = await mountAfter([
      "/ships/carrack",
      "/components/size-4-quantum-drive",
    ]);

    expect(backButton(wrapper).exists()).toBe(true);
  });

  it("is hidden in a browser tab, which has its own back button", async () => {
    installed.value = false;

    const { wrapper } = await mountAfter([
      "/ships/carrack",
      "/components/size-4-quantum-drive",
    ]);

    expect(backButton(wrapper).exists()).toBe(false);
  });

  it("goes back to the page the link was on", async () => {
    const { wrapper, router } = await mountAfter([
      "/ships/carrack",
      "/components/size-4-quantum-drive",
    ]);
    const back = vi.spyOn(router, "back");

    await backButton(wrapper).trigger("click");

    expect(back).toHaveBeenCalled();
  });
});
