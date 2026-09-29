import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { Model } from "@/services/fyApi";

const ar = vi.hoisted(() => ({
  mayHaveAr: true,
  canActivate: true,
  activateAR: vi.fn(() => Promise.resolve()),
}));

vi.mock("@/frontend/utils/arViewer", () => ({
  mayHaveAr: () => ar.mayHaveAr,
  prepareAr: vi.fn(async () =>
    ar.canActivate
      ? Object.assign(document.createElement("div"), {
          activateAR: ar.activateAR,
          canActivateAR: true,
        })
      : undefined,
  ),
}));

const { default: Component } = await import("./index.vue");

const model = (overrides: Partial<Model> = {}): Model =>
  ({
    slug: "sabre-raven",
    holoToScale: true,
    media: { holo: { url: "https://fleetyards.test/files/holo.glb" } },
    ...overrides,
  }) as Model;

const mount = async (props: { model: Model }) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props,
  });
  await flushPromises();
  return wrapper;
};

const button = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.find('[data-test="view-in-ar"]');

describe("ViewInArBtn", () => {
  beforeEach(() => {
    ar.mayHaveAr = true;
    ar.canActivate = true;
    ar.activateAR.mockClear();
  });

  it("offers AR for a holo exported to scale", async () => {
    expect(button(await mount({ model: model() })).exists()).toBe(true);
  });

  it("hides AR for a holo that is not to scale", async () => {
    const wrapper = await mount({ model: model({ holoToScale: false }) });

    expect(button(wrapper).exists()).toBe(false);
  });

  it("hides AR where model-viewer cannot open it", async () => {
    ar.canActivate = false;

    expect(button(await mount({ model: model() })).exists()).toBe(false);
  });

  it("hides AR on a device without an AR viewer", async () => {
    ar.mayHaveAr = false;

    expect(button(await mount({ model: model() })).exists()).toBe(false);
  });

  it("opens AR straight from the tap", async () => {
    const wrapper = await mount({ model: model() });

    await button(wrapper).trigger("click");

    expect(ar.activateAR).toHaveBeenCalledOnce();
  });
});
