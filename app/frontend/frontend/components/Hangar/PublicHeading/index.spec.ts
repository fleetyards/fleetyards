import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { UserPublic } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => false }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const user = (attributes: Partial<UserPublic>) =>
  ({
    username: "alice",
    publicHangarLoaners: true,
    publicHangarStats: true,
    publicWishlist: true,
    supporter: false,
    ...attributes,
  }) as UserPublic;

const mountWith = (attributes: Partial<UserPublic>) =>
  mount(Component, {
    props: { user: user(attributes) },
    global: {
      stubs: {
        Avatar: true,
        RsiProfileLink: true,
        Heading: { template: "<div><slot /></div>" },
        RouterLink: { props: ["to"], template: "<a><slot /></a>" },
      },
      directives: { tooltip: () => {} },
    },
  });

describe("HangarPublicHeading", () => {
  it("badges a supporter", () => {
    const wrapper = mountWith({ supporter: true });

    expect(wrapper.get('[data-test="pill"]').text()).toContain(
      "labels.supporter.badge",
    );
  });

  // Same insignia as the top supporter band, but its own label: a maintainer
  // is not shown as a supporter.
  it("badges a maintainer with the top insignia under their own label", () => {
    const wrapper = mountWith({
      supporter: true,
      maintainer: true,
      supporterTier: 3,
    });
    const pills = wrapper.findAll('[data-test="pill"]');
    const pill = pills[0];

    expect(pills).toHaveLength(1);

    expect(pill.text()).toContain("labels.maintainer.badge");
    expect(pill.text()).not.toContain("labels.supporter.badge");
    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(true);
  });

  it("leaves a non-supporter unbadged", () => {
    const wrapper = mountWith({ supporter: false });

    expect(wrapper.find('[data-test="pill"]').exists()).toBe(false);
  });

  // The insignia stands in for the heart rather than sitting beside it: the
  // pill already says "supporter", and which band is the only thing left for a
  // mark to add.
  it("puts the tier insignia in place of the heart", () => {
    const wrapper = mountWith({ supporter: true, supporterTier: 2 });
    const pill = wrapper.get('[data-test="pill"]');

    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(true);
    expect(pill.find(".fa-heart").exists()).toBe(false);
  });

  // Below the first band there is no insignia to stand in, so the heart it
  // replaces has to come back rather than leaving the pill wordless.
  it("falls back to the heart below the first band", () => {
    const wrapper = mountWith({ supporter: true, supporterTier: 0 });
    const pill = wrapper.get('[data-test="pill"]');

    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(false);
    expect(pill.find(".fa-heart").exists()).toBe(true);
  });

  // Below the first band there is no insignia, recurring or not: the pill
  // carries the heart, as for any supporter without one.
  it("shows the heart for a supporter below the first band", () => {
    const wrapper = mountWith({
      supporter: true,
      supporterTier: 0,
      supporterRecurring: true,
    });
    const pill = wrapper.get('[data-test="pill"]');

    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(false);
    expect(pill.find(".fa-heart").exists()).toBe(true);
  });

  it("shows the character portrait and the flagship under the name", () => {
    const wrapper = mountWith({
      characterPortrait: { smallUrl: "/portrait.png" },
      flagship: {
        modelName: "Carrack",
        modelSlug: "carrack",
        manufacturerName: "Anvil Aerospace",
        angledView: { largeUrl: "/carrack.png" },
        angledViewColored: { largeUrl: "/carrack-colored.png" },
      },
    } as Partial<UserPublic>);

    expect(
      wrapper
        .get('[data-test="hangar-public-character"] img')
        .attributes("src"),
    ).toBe("/portrait.png");
    expect(
      wrapper.get('[data-test="hangar-public-flagship-name"]').text(),
    ).toBe("Carrack");
    expect(
      wrapper.get('[data-test="hangar-public-flagship"]').text(),
    ).toContain("Anvil Aerospace");
    expect(wrapper.get(".hangar-public-heading__ship").attributes("src")).toBe(
      "/carrack-colored.png",
    );
  });

  it("falls back to the plain angled view and names the model under a ship name", () => {
    const wrapper = mountWith({
      flagship: {
        name: "Endeavour",
        modelName: "Carrack",
        modelSlug: "carrack",
        angledView: { largeUrl: "/carrack.png" },
      },
    } as Partial<UserPublic>);

    expect(wrapper.get(".hangar-public-heading__ship").attributes("src")).toBe(
      "/carrack.png",
    );
    expect(
      wrapper.get('[data-test="hangar-public-flagship-name"]').text(),
    ).toBe("Endeavour");
    expect(
      wrapper.get('[data-test="hangar-public-flagship"]').text(),
    ).toContain("Carrack");
  });

  it("leaves the flagship out without one", () => {
    expect(
      mountWith({}).find('[data-test="hangar-public-flagship"]').exists(),
    ).toBe(false);
  });

  it("lists the character portrait among the profile links", () => {
    const wrapper = mountWith({
      discord: "discord.gg/alice",
      characterPortrait: { smallUrl: "/portrait.png" },
    } as Partial<UserPublic>);
    const links = wrapper.get('[data-test="hangar-public-links"]');

    expect(
      links.get('[data-test="hangar-public-character"] img').attributes("src"),
    ).toBe("/portrait.png");
    expect(links.find(".fa-discord").exists()).toBe(true);
  });
});
