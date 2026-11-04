import { mount } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, nextTick } from "vue";
import { useWebglSupport } from "./useWebglSupport";

const webglAvailable = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable }));

const throwing = (message: string) =>
  defineComponent({
    setup() {
      throw new Error(message);
    },
    render: () => null,
  });

const host = (child = defineComponent({ render: () => null })) =>
  defineComponent({
    components: { child },
    setup: () => useWebglSupport(),
    template: `<child v-if="webglSupported" /><p v-else>fallback</p>`,
  });

describe("useWebglSupport", () => {
  beforeEach(() => {
    webglAvailable.mockReturnValue(true);
  });

  it("keeps the canvas where a context can be created", async () => {
    const wrapper = mount(host());
    await nextTick();

    expect(wrapper.text()).not.toContain("fallback");
  });

  it("falls back where the probe finds no context", async () => {
    webglAvailable.mockReturnValue(false);

    const wrapper = mount(host());
    await nextTick();

    expect(wrapper.text()).toContain("fallback");
  });

  it("falls back where the renderer throws after the probe passed", async () => {
    const wrapper = mount(
      host(throwing("THREE.WebGLRenderer: Error creating WebGL context.")),
    );
    await nextTick();

    expect(wrapper.text()).toContain("fallback");
  });

  it("does not swallow an error that has nothing to do with WebGL", () => {
    expect(() => mount(host(throwing("Something else")))).toThrow(
      "Something else",
    );
  });
});
