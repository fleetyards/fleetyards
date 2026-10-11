import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createCommentVNode } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Btn from "@/shared/components/base/Btn/index.vue";
import PageActions from "./index.vue";

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

const headerRight = () => document.getElementById("header-right")!;

let mounted: { unmount: () => void } | undefined;

const mount = async (props: { menuTour?: string } = {}, available = true) => {
  const wrapper = await mountWithDefaults(PageActions, {
    props,
    slots: {
      default: () =>
        available
          ? [h(Btn, { "data-test": "action" }, () => "Mark all read")]
          : [createCommentVNode("v-if")],
    },
    attachTo: document.getElementById("app")!,
  });

  await flushPromises();
  mounted = wrapper;

  return wrapper;
};

beforeEach(() => {
  document.body.innerHTML = '<div id="header-right"></div><div id="app"></div>';
});

afterEach(() => {
  mounted?.unmount();
  mounted = undefined;
});

describe("PageActions", () => {
  it("puts the buttons in the header at the header's size on a desktop", async () => {
    setViewport(false);
    await mount();

    const action = headerRight().querySelector('[data-test="action"]');

    expect(action?.classList.contains("btn--md")).toBe(true);
    expect(
      headerRight().querySelector('[data-test="page-actions-menu"]'),
    ).toBeNull();
  });

  it("folds them into one menu on a phone", async () => {
    setViewport(true);
    await mount();

    expect(
      headerRight().querySelector('[data-test="page-actions-menu"]'),
    ).not.toBeNull();
    expect(
      headerRight().querySelector(".navigation-header-pinned"),
    ).not.toBeNull();
  });

  it("hands a tour step the menu on a phone", async () => {
    setViewport(true);
    await mount({ menuTour: "invite" });

    expect(headerRight().querySelector('[data-tour="invite"]')).not.toBeNull();
  });

  it("shows no menu on a phone when no action is available", async () => {
    setViewport(true);
    await mount({}, false);

    expect(
      headerRight().querySelector('[data-test="page-actions-menu"]'),
    ).toBeNull();
  });
});
