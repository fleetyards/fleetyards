import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { OutfitBodyEnum, type SharedCharacterFace } from "@/services/fyApi";

const comlink = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: comlink }),
}));

const { default: Characters } = await import("./index.vue");

const shown = {
  token: "shared",
  name: "Recco",
  body: OutfitBodyEnum.MALE,
  file: {
    url: "/rails/active_storage/blobs/Recco.chf",
    name: "Recco.chf",
    contentType: "application/octet-stream",
    size: 4096,
  },
  character: null,
} as SharedCharacterFace;

const mount = (props: Record<string, unknown>, signedIn = true) =>
  mountWithDefaults<typeof Characters>(Characters, {
    props: { body: OutfitBodyEnum.MALE, ...props } as never,
    initialState: {
      session: signedIn
        ? { authenticated: true, currentUser: { username: "torlek" } }
        : {},
    },
  });

describe("DressingRoomCharacters", () => {
  it("shows the game's default character with nothing to reset", async () => {
    const wrapper = await mount({});

    expect(
      wrapper.find('[data-test="dressing-room-current-character"]').text(),
    ).toContain("Game default");
    expect(
      wrapper.find('[data-test="dressing-room-take-off-character"]').exists(),
    ).toBe(false);
  });

  it("shows the character on the figure with its download, and resets to the default", async () => {
    const wrapper = await mount({ token: "shared", shown });
    const current = wrapper.find(
      '[data-test="dressing-room-current-character"]',
    );

    expect(current.text()).toContain("Recco");
    expect(current.find("a").attributes("href")).toBe(
      "/rails/active_storage/blobs/Recco.chf",
    );

    await wrapper
      .find('[data-test="dressing-room-take-off-character"]')
      .trigger("click");
    expect(wrapper.emitted("select")).toEqual([[undefined]]);
  });

  it("opens the characters to pick from in a modal", async () => {
    const wrapper = await mount({ token: "shared", shown });

    await wrapper
      .find('[data-test="dressing-room-choose-character"]')
      .trigger("click");

    expect(comlink).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: expect.objectContaining({ body: OutfitBodyEnum.MALE }),
      }),
    );
  });

  it("asks to sign in before it offers to change the character", async () => {
    const wrapper = await mount({}, false);

    expect(wrapper.text()).toContain("Sign in to upload your own character.");
    expect(
      wrapper.find('[data-test="dressing-room-choose-character"]').exists(),
    ).toBe(false);
  });

  it("says when the character in the link cannot be drawn, or not yet", async () => {
    expect(
      (await mount({ token: "gone", unavailable: true })).text(),
    ).toContain("The character in this link cannot be shown on this body.");
    expect(
      (await mount({ token: "token-1", notReady: true }))
        .find('[data-test="dressing-room-character-not-ready"]')
        .exists(),
    ).toBe(true);
  });
});
