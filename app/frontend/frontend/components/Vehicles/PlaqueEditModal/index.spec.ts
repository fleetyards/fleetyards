import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeAll, describe, expect, it, vi } from "vitest";
import { defineRule } from "vee-validate";
import { max, required } from "@vee-validate/rules";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import { type Vehicle } from "@/services/fyApi";

const mutateAsync = vi.fn(() => Promise.resolve());

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync, isPending: ref(false) }),
  }),
}));

const NOW = "2026-10-13T12:00:00Z";

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    alternativeNames: [],
    hangarGroupIds: [],
    hangarGroups: [],
    modelModuleIds: [],
    modelUpgradeIds: [],
    modelPaintIds: [],
    manufacturerCode: "DRAK",
    model: {
      id: "model-1",
      name: "Corsair",
      slug: "corsair",
      media: {},
      manufacturer: {
        name: "Drake Interplanetary",
        slug: "drake",
        code: "DRAK",
        createdAt: NOW,
        updatedAt: NOW,
      },
    },
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  }) as Vehicle;

// The upsell links to the support page, which the test router has to know.
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/support", name: "support", component: { template: "<div />" } },
  ],
});

const mount = (supporter: boolean) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { vehicle: vehicle() },
    initialState: { session: { currentUser: { supporter } } },
    plugins: [router],
  });

const openStyles = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
  await wrapper
    .find('[data-test="vehicle-plaque-styles-open"]')
    .trigger("click");
};

const styleTile = (wrapper: Awaited<ReturnType<typeof mount>>, style: string) =>
  wrapper.find(`[data-test="vehicle-plaque-style-${style}"]`);

describe("VehiclePlaqueEditModal", () => {
  // The app registers its rules globally; a spec mounts the form without them.
  beforeAll(() => {
    defineRule("max", max);
    defineRule("required", required);
  });

  it("previews every style on a page of its own", async () => {
    const wrapper = await mount(true);
    await openStyles(wrapper);

    expect(
      wrapper.findAll(
        '[data-test="vehicle-plaque-styles"] [data-test="vehicle-plaque"]',
      ),
    ).toHaveLength(10);
  });

  it("leaves a non-supporter brass and greys out the rest", async () => {
    const wrapper = await mount(false);
    await openStyles(wrapper);

    expect(styleTile(wrapper, "brass").attributes("aria-disabled")).toBe(
      "false",
    );
    expect(styleTile(wrapper, "neon").attributes("aria-disabled")).toBe("true");
    expect(wrapper.find('[data-test="vehicle-plaque-upsell"]').exists()).toBe(
      true,
    );

    expect(wrapper.find(".plaque-style-picker__locked--open").exists()).toBe(
      false,
    );

    await styleTile(wrapper, "neon").trigger("click");

    expect(wrapper.find(".plaque-style-picker__locked--open").exists()).toBe(
      true,
    );

    expect(styleTile(wrapper, "neon").attributes("aria-pressed")).toBe("false");
    expect(styleTile(wrapper, "brass").attributes("aria-pressed")).toBe("true");
  });

  it("starts a supporter on the maker's own style", async () => {
    const wrapper = await mount(true);
    await openStyles(wrapper);

    expect(styleTile(wrapper, "manufacturer").attributes("aria-pressed")).toBe(
      "true",
    );
    expect(wrapper.find('[data-test="vehicle-plaque-upsell"]').exists()).toBe(
      false,
    );
  });

  it("saves a supporter's new plaque in the maker's style it was shown in", async () => {
    mutateAsync.mockClear();
    const wrapper = await mount(true);

    await wrapper
      .find('[data-test="vehicle-plaque-dedication-input"] textarea')
      .setValue("To boldly go");
    await wrapper.find("#vehicle-plaque-form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ plaqueStyle: "manufacturer" }),
      }),
    );
  });

  it("saves a plaque in English until it is translated into the app's language", async () => {
    const mountIn = () =>
      mountWithDefaults<typeof Component>(Component, {
        props: { vehicle: vehicle() },
        initialState: {
          session: { currentUser: { supporter: false } },
          i18n: { locale: "de" },
        },
        plugins: [router],
      });
    const save = async (wrapper: Awaited<ReturnType<typeof mountIn>>) => {
      await wrapper
        .find('[data-test="vehicle-plaque-dedication-input"] textarea')
        .setValue("To boldly go");
      await wrapper.find("#vehicle-plaque-form").trigger("submit");
      await flushPromises();
    };

    mutateAsync.mockClear();
    await save(await mountIn());

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ plaqueLocale: null }),
      }),
    );

    mutateAsync.mockClear();
    const wrapper = await mountIn();
    const toggle = wrapper.find<HTMLInputElement>(
      '[data-test="vehicle-plaque-translated-input"] input',
    );
    toggle.element.checked = true;
    await toggle.trigger("change");
    await save(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ plaqueLocale: "de" }),
      }),
    );
  });

  it("saves the verse with the plaque", async () => {
    mutateAsync.mockClear();
    const wrapper = await mount(true);

    await wrapper
      .find('[data-test="vehicle-plaque-dedication-input"] textarea')
      .setValue("To boldly go");
    await wrapper
      .find('[data-test="vehicle-plaque-dedication-verse-input"] textarea')
      .setValue("When the charts run out,\nlook for the light.");
    await wrapper.find("#vehicle-plaque-form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          dedicationVerse: "When the charts run out,\nlook for the light.",
        }),
      }),
    );
  });

  it("leaves an existing plaque's style out when it is not changed", async () => {
    mutateAsync.mockClear();
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        vehicle: vehicle({ dedication: "To boldly go", plaqueStyle: "neon" }),
      },
      initialState: { session: { currentUser: { supporter: true } } },
      plugins: [router],
    });

    await wrapper.find("#vehicle-plaque-form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.not.objectContaining({ plaqueStyle: expect.anything() }),
      }),
    );
  });

  it("offers to take a plaque down, as the dedication can no longer be emptied", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { vehicle: vehicle({ dedication: "To boldly go" }) },
      initialState: { session: { currentUser: { supporter: false } } },
      plugins: [router],
    });

    expect(wrapper.find('[data-test="vehicle-plaque-remove"]').exists()).toBe(
      true,
    );
  });

  it("warns a lapsed supporter that saving switches their plaque to brass", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        vehicle: vehicle({ dedication: "To boldly go", plaqueStyle: "neon" }),
      },
      initialState: { session: { currentUser: { supporter: false } } },
      plugins: [router],
    });

    expect(
      wrapper.find('[data-test="vehicle-plaque-kept-style"]').exists(),
    ).toBe(true);

    await wrapper.find("#vehicle-plaque-form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ plaqueStyle: "brass" }),
      }),
    );
  });

  it("keeps a supporter's style without a warning", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        vehicle: vehicle({ dedication: "To boldly go", plaqueStyle: "neon" }),
      },
      initialState: { session: { currentUser: { supporter: true } } },
      plugins: [router],
    });

    expect(
      wrapper.find('[data-test="vehicle-plaque-kept-style"]').exists(),
    ).toBe(false);
  });

  it("keeps what was typed while a style is picked", async () => {
    const wrapper = await mount(true);

    await wrapper
      .find('[data-test="vehicle-plaque-dedication-input"] textarea')
      .setValue("Built rough");
    await openStyles(wrapper);
    await styleTile(wrapper, "neon").trigger("click");
    await wrapper
      .find('[data-test="vehicle-plaque-styles-back"]')
      .trigger("click");
    await flushPromises();

    expect(
      (
        wrapper.find('[data-test="vehicle-plaque-dedication-input"] textarea')
          .element as HTMLTextAreaElement
      ).value,
    ).toBe("Built rough");
  });

  describe("captain", () => {
    const mountAs = (currentUser: Record<string, unknown>) =>
      mountWithDefaults<typeof Component>(Component, {
        props: { vehicle: vehicle({ dedication: "To boldly go" }) },
        initialState: { session: { currentUser } },
        plugins: [router],
      });

    const previewCaptain = (wrapper: Awaited<ReturnType<typeof mountAs>>) =>
      wrapper
        .find(
          '[data-test="vehicle-plaque-preview"] [data-test="vehicle-plaque-captain"]',
        )
        .text();

    it("names the owner by their display name", async () => {
      const wrapper = await mountAs({
        username: "torlek",
        displayName: "Torlek Maru",
      });

      expect(previewCaptain(wrapper)).toBe("Captain Torlek Maru");
    });

    it("names whoever is typed in the owner's place, and saves it", async () => {
      mutateAsync.mockClear();
      const wrapper = await mountAs({
        username: "torlek",
        displayName: "Torlek Maru",
      });

      await wrapper
        .find('[data-test="vehicle-plaque-captain-input"] input')
        .setValue("Maru");
      await flushPromises();

      expect(previewCaptain(wrapper)).toBe("Captain Maru");

      await wrapper.find("form").trigger("submit");
      await flushPromises();

      expect(mutateAsync).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ plaqueCaptain: "Maru" }),
        }),
      );
    });

    it("leaves a hidden owner off the plaque", async () => {
      const wrapper = await mountAs({
        username: "torlek",
        displayName: "Torlek Maru",
        hideOwner: true,
      });

      expect(
        wrapper
          .find(
            '[data-test="vehicle-plaque-preview"] [data-test="vehicle-plaque-captain"]',
          )
          .exists(),
      ).toBe(false);
    });
  });
});
