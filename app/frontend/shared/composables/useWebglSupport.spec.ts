import { mount } from "@vue/test-utils";
import { useWebglSupport } from "./useWebglSupport";

const webglAvailable = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable }));

const canvasSetup = vi.fn();

const canvas = defineComponent({
  setup: canvasSetup,
  render: () => null,
});

const host = defineComponent({
  setup: () => useWebglSupport(),
  template: `<canvas-stub v-if="webglSupported" /><p v-else>fallback</p>`,
});

const mountHost = () =>
  mount(host, { global: { components: { CanvasStub: canvas } } });

describe("useWebglSupport", () => {
  beforeEach(() => {
    webglAvailable.mockReturnValue(true);
    canvasSetup.mockReset();
  });

  it("keeps the canvas where a context can be created", () => {
    expect(mountHost().text()).not.toContain("fallback");
    expect(canvasSetup).toHaveBeenCalledOnce();
  });

  it("never tries the canvas where the probe finds no context", () => {
    webglAvailable.mockReturnValue(false);

    expect(mountHost().text()).toContain("fallback");
    expect(canvasSetup).not.toHaveBeenCalled();
  });

  it("falls back where the renderer throws after the probe passed", async () => {
    canvasSetup.mockImplementation(() => {
      throw new Error("THREE.WebGLRenderer: Error creating WebGL context.");
    });

    const wrapper = mountHost();
    await nextTick();

    expect(wrapper.text()).toContain("fallback");
  });

  it("does not swallow an error that has nothing to do with WebGL", () => {
    canvasSetup.mockImplementation(() => {
      throw new Error("Something else");
    });

    expect(mountHost).toThrow("Something else");
  });
});
