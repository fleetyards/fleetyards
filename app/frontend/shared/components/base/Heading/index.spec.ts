import { describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { defineComponent, h } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { FeatureFlagName } from "@/services/fyApi";
import { PAGE_FEATURE } from "@/shared/utils/BetaFeatures";
import Heading from "./index.vue";

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
        await mount({ hero: true, level: "h2" }, FeatureFlagName.STARMAP),
      ),
    ).toBe(false);
    expect(hasBadge(await mount({}, FeatureFlagName.STARMAP))).toBe(false);
  });

  it("leaves a hero on a permanent or unflagged route alone", async () => {
    expect(
      hasBadge(await mount({ hero: true }, FeatureFlagName.OAUTH_APPLICATIONS)),
    ).toBe(false);
    expect(hasBadge(await mount({ hero: true }))).toBe(false);
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
