import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  type CharacterFace,
  OutfitBodyEnum,
  type SharedCharacterFace,
} from "@/services/fyApi";

const NOW = "2026-11-08T12:00:00Z";

const file = (name: string) => ({
  url: `/rails/active_storage/blobs/${name}`,
  name,
  contentType: "application/octet-stream",
  size: 4096,
});

const face = (overrides: Partial<CharacterFace>): CharacterFace => ({
  id: "face-1",
  name: "Macken",
  token: "token-1",
  body: OutfitBodyEnum.MALE,
  dnaStamp: "68c929ba",
  genderHash: "f6676cdd",
  formatVersion: 7,
  gameVersion: "4.10.197",
  file: file("Macken.chf"),
  createdAt: NOW,
  updatedAt: NOW,
  ...overrides,
});

const characters = ref<CharacterFace[]>([
  face({}),
  face({
    id: "face-2",
    name: "Meg",
    token: "token-2",
    body: OutfitBodyEnum.FEMALE,
  }),
]);
const create = vi.fn(() =>
  Promise.resolve(face({ id: "face-3", token: "token-3" })),
);
const destroy = vi.fn(() => Promise.resolve({ success: true }));

const mutation = (mutateAsync: unknown) => ({
  mutateAsync,
  isPending: ref(false),
});

const displayAlert = vi.fn();
const displaySuccess = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayAlert,
    displaySuccess,
    displayConfirm: ({ onConfirm }: { onConfirm: () => void }) => onConfirm(),
  }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCharacterFaces: () => ({ data: characters, isLoading: ref(false) }),
  useCreateCharacterFace: () => mutation(create),
  useDestroyCharacterFace: () => mutation(destroy),
}));

const { default: Characters } = await import("./index.vue");

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
  beforeEach(() => {
    create.mockClear();
    destroy.mockClear();
  });

  it("asks to sign in before it offers an upload, and still shows a shared character", async () => {
    const shown = {
      token: "shared",
      name: "Recco",
      body: OutfitBodyEnum.MALE,
      file: file("Recco.chf"),
      character: null,
    } as SharedCharacterFace;
    const wrapper = await mount({ token: "shared", shown }, false);

    expect(wrapper.text()).toContain("Sign in to upload your own character.");
    expect(
      wrapper.find('[data-test="dressing-room-upload-character"]').exists(),
    ).toBe(false);
    const shared = wrapper.find('[data-test="dressing-room-shared-character"]');
    expect(shared.text()).toContain("Recco");
    expect(shared.find("a").attributes("href")).toBe(
      "/rails/active_storage/blobs/Recco.chf",
    );
  });

  it("uploads a file for the body being dressed and puts it on", async () => {
    const wrapper = await mount({});
    const input = wrapper.find('[data-test="dressing-room-character-file"]');
    const chf = new File(["BB"], "Macken.chf");
    Object.defineProperty(input.element, "files", {
      value: [chf],
      configurable: true,
    });

    await input.trigger("change");
    await flushPromises();

    expect(create).toHaveBeenCalledWith({
      data: { file: chf, body: OutfitBodyEnum.MALE },
    });
    expect(wrapper.emitted("select")).toEqual([["token-3"]]);
  });

  it("puts on one of the user's characters, but not one for the other body", async () => {
    const wrapper = await mount({});

    await wrapper
      .find('[data-test="dressing-room-character-face-1"]')
      .trigger("click");
    expect(wrapper.emitted("select")).toEqual([["token-1"]]);
    expect(
      wrapper
        .find('[data-test="dressing-room-character-face-2"]')
        .attributes("disabled"),
    ).toBeDefined();
  });

  it("takes the character off when the one on the figure is deleted", async () => {
    const wrapper = await mount({ token: "token-1" });

    await wrapper
      .find('[data-test="dressing-room-delete-character-face-1"]')
      .trigger("click");
    await flushPromises();

    expect(destroy).toHaveBeenCalledWith({ id: "face-1" });
    expect(wrapper.emitted("select")).toEqual([[undefined]]);
  });

  it("says when the character in the link cannot be drawn", async () => {
    const wrapper = await mount({ token: "gone", unavailable: true });

    expect(wrapper.text()).toContain(
      "The character in this link cannot be shown on this body.",
    );
  });
});
