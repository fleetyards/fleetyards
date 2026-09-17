import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  MessageTypesEnum,
  type AppNotification,
} from "@/shared/components/AppNotifications/types";
import MessageBody from "./Body/index.vue";
import Component from "./index.vue";

const hideMessage = vi.fn();

vi.mock("@/shared/stores/notifications", () => ({
  useNotificationsStore: () => ({ hideMessage }),
}));

const message: AppNotification = {
  id: "message-id",
  type: MessageTypesEnum.INFO,
  visible: true,
  persist: false,
  text: "Ship added to your hangar.",
  to: { name: "target" },
};

const CustomBody = defineComponent({
  name: "CustomNotificationBody",
  setup: () => () =>
    h(MessageBody, null, { default: () => h("span", "custom") }),
});

const mountMessage = async (
  overrides: Partial<AppNotification> = {},
  locale = "en",
) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      { path: "/target", name: "target", component: { template: "<div />" } },
    ],
  });

  const push = vi.spyOn(router, "push");

  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { message: { ...message, ...overrides } },
    initialState: { i18n: { locale } },
    plugins: [router],
  });

  return { wrapper, push };
};

describe("AppNotificationsMessage", () => {
  beforeEach(() => {
    hideMessage.mockClear();
  });

  it("dismisses and follows the link when the message is clicked", async () => {
    const { wrapper, push } = await mountMessage();

    await wrapper.get('[data-test="notification-info"]').trigger("click");

    expect(hideMessage).toHaveBeenCalledWith("message-id");
    expect(push).toHaveBeenCalledWith({ name: "target" });
  });

  it("only dismisses when the close button is clicked", async () => {
    const { wrapper, push } = await mountMessage();

    await wrapper.get('[data-test="notification-close"]').trigger("click");

    expect(hideMessage).toHaveBeenCalledWith("message-id");
    expect(push).not.toHaveBeenCalled();
  });

  it("only dismisses when a custom body's close button is clicked", async () => {
    const { wrapper, push } = await mountMessage({
      text: undefined,
      component: () => Promise.resolve(CustomBody),
    });

    await wrapper.get('[data-test="notification-close"]').trigger("click");

    expect(hideMessage).toHaveBeenCalledWith("message-id");
    expect(push).not.toHaveBeenCalled();
  });

  it("names the close button in the active locale", async () => {
    const { wrapper } = await mountMessage({}, "de");

    expect(
      wrapper.get('[data-test="notification-close"]').attributes("aria-label"),
    ).toBe("Schließen");
  });
});
