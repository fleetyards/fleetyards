import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import MobileSelectionHeader from "./index.vue";

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

const headerLeft = () => document.getElementById("header-left")!;

const barProps = {
  selectedCount: 2,
  matchingCount: 10,
  pageSelected: false,
  pagePartiallySelected: true,
  canSelectAllMatching: false,
  allMatchingSelected: false,
};

let mounted: { unmount: () => void } | undefined;

const mount = async (selecting: boolean) => {
  const wrapper = await mountWithDefaults(MobileSelectionHeader, {
    props: { ...barProps, selecting },
    attachTo: document.getElementById("app")!,
  });

  await flushPromises();
  mounted = wrapper;

  return wrapper;
};

beforeEach(() => {
  document.body.innerHTML = '<div id="header-left"></div><div id="app"></div>';
});

afterEach(() => {
  mounted?.unmount();
  mounted = undefined;
});

describe("MobileSelectionHeader", () => {
  it("stays above the list on a desktop", async () => {
    setViewport(false);
    const wrapper = await mount(false);

    expect(wrapper.find('[data-test="bulk-selection-bar"]').exists()).toBe(
      true,
    );
    expect(headerLeft().children).toHaveLength(0);
  });

  it("renders nothing on a phone until a selection starts", async () => {
    setViewport(true);
    const wrapper = await mount(false);

    expect(wrapper.find('[data-test="bulk-selection-bar"]').exists()).toBe(
      false,
    );
    expect(headerLeft().children).toHaveLength(0);
  });

  it("takes the header over with a way out while selecting", async () => {
    setViewport(true);
    const wrapper = await mount(true);

    expect(
      headerLeft().querySelector(".navigation-header-takeover"),
    ).not.toBeNull();
    expect(
      headerLeft().querySelector('[data-test="bulk-selection-count"]')
        ?.textContent,
    ).toContain("2");

    (
      headerLeft().querySelector('[data-test="bulk-exit"]') as HTMLElement
    ).click();

    expect(wrapper.emitted("clear")).toHaveLength(1);
  });
});
