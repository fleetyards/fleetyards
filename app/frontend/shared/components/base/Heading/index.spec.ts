import { describe, expect, it, vi } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { defineComponent, h } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { FeatureFlagName } from "@/services/fyApi";
import { PAGE_FEATURE } from "@/shared/utils/BetaFeatures";
import Heading from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => {
  const original = await importOriginal<typeof import("@/services/fyApi")>();
  const { ref } = await import("vue");

  return {
    ...original,
    useBetaFeatures: () => ({
      data: ref([
        original.FeatureFlagName.DRESSING_ROOM,
        original.FeatureFlagName.HANGAR_PLANNER,
        original.FeatureFlagName.HOMEPAGE_DASHBOARD,
        original.FeatureFlagName.FLEET_LOGISTICS,
      ]),
    }),
  };
});

const Empty = defineComponent({ render: () => null });

const routerAt = async (feature?: FeatureFlagName) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/", component: Empty, meta: { feature } }],
  });
  await router.push("/");

  return router;
};

const mount = async (
  props: Record<string, unknown>,
  feature?: FeatureFlagName,
) =>
  mountWithDefaults(Heading, {
    props,
    slots: { default: () => [h("span", "Title")] },
    plugins: [await routerAt(feature)],
  });

const hasBadge = (wrapper: {
  find: (selector: string) => { exists: () => boolean };
}) => wrapper.find('[data-test="beta-badge"]').exists();

describe("Heading", () => {
  it("marks a page hero on a beta route", async () => {
    const wrapper = await mount({ hero: true }, FeatureFlagName.HANGAR_PLANNER);

    expect(hasBadge(wrapper)).toBe(true);
    expect(wrapper.text()).toContain("Title");
  });

  it("leaves a heading that is not the page hero alone", async () => {
    expect(
      hasBadge(
        await mount(
          { hero: true, level: "h2" },
          FeatureFlagName.HANGAR_PLANNER,
        ),
      ),
    ).toBe(false);
    expect(hasBadge(await mount({}, FeatureFlagName.HANGAR_PLANNER))).toBe(
      false,
    );
  });

  it("leaves a hero on a route nobody can switch on, or an unflagged one, alone", async () => {
    expect(hasBadge(await mount({ hero: true }, FeatureFlagName.STARMAP))).toBe(
      false,
    );
    expect(hasBadge(await mount({ hero: true }))).toBe(false);
  });

  it("keeps the title unwrapped on a flagged page that is not beta", async () => {
    const wrapper = await mount({ hero: true }, FeatureFlagName.STARMAP);

    expect(wrapper.find(".beta-badge-around").exists()).toBe(false);
  });

  it("describes the pill with the hint instead of naming the heading after it", async () => {
    const wrapper = await mount({ hero: true }, FeatureFlagName.HANGAR_PLANNER);
    const pill = wrapper.find('[data-test="beta-badge"]');

    expect(pill.attributes("aria-label")).toBeUndefined();
    expect(
      wrapper.find(`#${pill.attributes("aria-describedby")}`).text(),
    ).toContain("feedback");
  });

  it("takes the flag from its prop", async () => {
    expect(
      hasBadge(
        await mount({
          hero: true,
          feature: FeatureFlagName.HOMEPAGE_DASHBOARD,
        }),
      ),
    ).toBe(true);
  });

  it("takes the flag a wrapper provides", async () => {
    const Wrapper = defineComponent({
      provide: { [PAGE_FEATURE as symbol]: FeatureFlagName.FLEET_LOGISTICS },
      render: () => h(Heading, { hero: true }, () => "Title"),
    });

    const wrapper = await mountWithDefaults(Wrapper, {
      plugins: [await routerAt()],
    });

    expect(hasBadge(wrapper)).toBe(true);
  });
});
