import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  MessageTypesEnum,
  type AppNotification,
} from "@/shared/components/AppNotifications/types";
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

const mountMessage = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      { path: "/target", name: "target", component: { template: "<div />" } },
    ],
  });

  const push = vi.spyOn(router, "push");

  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { message },
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
});
