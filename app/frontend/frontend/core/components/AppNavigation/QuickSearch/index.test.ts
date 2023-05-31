import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

import Component from "./index.vue";

describe("AppNavigtation QuickSearch", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });
});
