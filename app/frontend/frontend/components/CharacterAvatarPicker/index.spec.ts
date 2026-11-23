import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { type User } from "@/services/fyApi";

const update = vi.fn(() => Promise.resolve({}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useUpdateProfile: () => ({ mutateAsync: update, isPending: ref(false) }),
}));

const { default: CharacterAvatarPicker } = await import("./index.vue");

const render = (url: string) => ({ url, smallUrl: url }) as never;

const user = (overrides: Partial<User> = {}) =>
  ({
    username: "torlek",
    avatarSource: "uploaded",
    defaultOutfitId: "outfit-1",
    avatar: render("/uploaded.png"),
    characterAvatarHelmet: render("/helmet.png"),
    characterAvatarBare: render("/bare.png"),
    ...overrides,
  }) as User;

const mount = (props: { user: User }) =>
  mountWithDefaults<typeof CharacterAvatarPicker>(CharacterAvatarPicker, {
    props,
    plugins: [
      createRouter({
        history: createMemoryHistory(),
        routes: [
          { path: "/", name: "home", component: {} },
          { path: "/dressing-room/", name: "dressing-room", component: {} },
        ],
      }),
    ],
  });

describe("CharacterAvatarPicker", () => {
  beforeEach(() => update.mockClear());

  it("points to the dressing room while there is no default outfit to draw", async () => {
    const wrapper = await mount({ user: user({ defaultOutfitId: null }) });

    expect(wrapper.text()).toContain("Mark an outfit as your default");
    expect(wrapper.find('[data-test="avatar-source-uploaded"]').exists()).toBe(
      false,
    );
  });

  it("shows the chosen picture as selected and switches to another", async () => {
    const wrapper = await mount({ user: user() });

    expect(
      wrapper
        .find('[data-test="avatar-source-uploaded"]')
        .attributes("aria-pressed"),
    ).toBe("true");

    await wrapper
      .find('[data-test="avatar-source-character_bare"]')
      .trigger("click");
    await flushPromises();

    expect(update).toHaveBeenCalledWith({
      data: { avatarSource: "character_bare" },
    });
  });

  it("offers no render that has not been drawn", async () => {
    const wrapper = await mount({
      user: user({ characterAvatarHelmet: undefined }),
    });

    expect(
      wrapper
        .find('[data-test="avatar-source-character_helmet"]')
        .attributes("disabled"),
    ).toBeDefined();
  });

  it("sends a default outfit without renders to the dressing room to be drawn", async () => {
    const wrapper = await mount({
      user: user({
        characterAvatarHelmet: undefined,
        characterAvatarBare: undefined,
      }),
    });

    expect(wrapper.text()).toContain("Open your default outfit");
  });
});
