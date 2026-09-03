import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./AccessCheck.vue";

const Page = defineComponent({ render: () => h("div") });

const restrictedRouter = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/",
        name: "admin-models",
        component: Page,
        meta: { access: ["models"] },
      },
      // NotAuthorized links back to it, so resolving the denied state needs it.
      { path: "/home", name: "home", component: Page },
    ],
  });

  await router.push("/");
  await router.isReady();

  return router;
};

const mount = async (props: InstanceType<typeof Component>["$props"]) =>
  mountWithDefaults<typeof Component>(Component, {
    props,
    slots: { granted: () => [h("div", { class: "page" })] },
    plugins: [await restrictedRouter()],
  });

describe("AdminAccessCheck", () => {
  it("waits instead of denying while the current user is still unknown", async () => {
    const wrapper = await mount({ loading: true });

    expect(wrapper.findComponent({ name: "NotAuthorized" }).exists()).toBe(
      false,
    );
    expect(wrapper.find(".page").exists()).toBe(false);
  });

  it("denies once the user is known to lack the privilege", async () => {
    const wrapper = await mount({ resourceAccess: ["users"] });

    expect(wrapper.findComponent({ name: "NotAuthorized" }).exists()).toBe(
      true,
    );
  });

  it("renders the page for a user holding the privilege", async () => {
    const wrapper = await mount({ resourceAccess: ["models"] });

    expect(wrapper.find(".page").exists()).toBe(true);
  });

  it("renders the page for a super admin", async () => {
    const wrapper = await mount({ superAdmin: true });

    expect(wrapper.find(".page").exists()).toBe(true);
  });
});
