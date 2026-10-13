import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { Model } from "@/services/fyApi";

const ar = vi.hoisted(() => ({
  mayHaveAr: true,
  quickLook: false,
  canActivate: true,
  activateAR: vi.fn(() => Promise.resolve()),
  openQuickLook: vi.fn((_url: string, _wanted?: () => boolean): Promise<void> =>
    Promise.resolve(),
  ),
}));

vi.mock("@/frontend/utils/arViewer", () => ({
  mayHaveAr: () => ar.mayHaveAr,
  usesQuickLook: () => ar.quickLook,
  openQuickLook: ar.openQuickLook,
  prepareAr: vi.fn(async () =>
    ar.canActivate
      ? Object.assign(document.createElement("div"), {
          activateAR: ar.activateAR,
          canActivateAR: true,
        })
      : undefined,
  ),
}));

const displayAlert = vi.hoisted(() => vi.fn());

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert }),
}));

const mockFlag = ref(true);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => mockFlag.value }),
}));

const { default: Component } = await import("./index.vue");

const model = (overrides: Partial<Model> = {}): Model =>
  ({
    slug: "sabre-raven",
    holoToScale: true,
    media: { holo: { url: "https://fleetyards.test/files/holo.glb" } },
    ...overrides,
  }) as Model;

const HOLO = "https://fleetyards.test/files/holo.glb";

const mount = async (props: {
  model: Model;
  active?: boolean;
  displayedHoloUrl?: string;
}) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { active: true, displayedHoloUrl: HOLO, ...props },
  });
  await flushPromises();
  return wrapper;
};

const button = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.find('[data-test="view-in-ar"]');

describe("ViewInArBtn", () => {
  beforeEach(() => {
    mockFlag.value = true;
    ar.mayHaveAr = true;
    ar.quickLook = false;
    ar.canActivate = true;
    ar.activateAR.mockClear();
    ar.openQuickLook.mockReset();
    ar.openQuickLook.mockResolvedValue(undefined);
  });

  it("offers AR for a holo exported to scale", async () => {
    expect(button(await mount({ model: model() })).exists()).toBe(true);
  });

  it("hides AR while the feature is off", async () => {
    mockFlag.value = false;

    expect(button(await mount({ model: model() })).exists()).toBe(false);
  });

  it("offers AR once the flag arrives while the 3D view is open", async () => {
    mockFlag.value = false;
    const wrapper = await mount({ model: model() });

    mockFlag.value = true;
    await flushPromises();

    expect(button(wrapper).exists()).toBe(true);
  });

  it("hides AR while the 3D view shows another pose's holo", async () => {
    const wrapper = await mount({
      model: model(),
      displayedHoloUrl: "https://fleetyards.test/files/landed.glb",
    });

    expect(button(wrapper).exists()).toBe(false);
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

  it("fetches nothing until the 3D view is open", async () => {
    const { prepareAr } = await import("@/frontend/utils/arViewer");
    vi.mocked(prepareAr).mockClear();

    const wrapper = await mount({ model: model(), active: false });

    expect(prepareAr).not.toHaveBeenCalled();
    expect(button(wrapper).exists()).toBe(false);

    await wrapper.setProps({ active: true });
    await flushPromises();

    expect(prepareAr).toHaveBeenCalledOnce();
    expect(button(wrapper).exists()).toBe(true);
  });

  it("opens AR straight from the tap", async () => {
    const wrapper = await mount({ model: model() });

    await button(wrapper).trigger("click");

    expect(ar.activateAR).toHaveBeenCalledOnce();
  });

  it("keeps the viewer of the holo it was last asked for", async () => {
    const { prepareAr } = await import("@/frontend/utils/arViewer");
    const late = { resolve: (_: unknown) => {} };
    const stale = Object.assign(document.createElement("div"), {
      activateAR: vi.fn(),
      canActivateAR: true,
    });
    vi.mocked(prepareAr).mockImplementationOnce(
      () => new Promise((resolve) => (late.resolve = resolve)) as never,
    );

    const wrapper = await mount({ model: model() });
    await wrapper.setProps({
      model: model({
        media: { holo: { url: "https://fleetyards.test/files/other.glb" } },
      } as Partial<Model>),
      displayedHoloUrl: "https://fleetyards.test/files/other.glb",
    });
    await flushPromises();
    late.resolve(stale);
    await flushPromises();

    await button(wrapper).trigger("click");

    expect(ar.activateAR).toHaveBeenCalledOnce();
    expect(stale.activateAR).not.toHaveBeenCalled();
  });

  describe("with Quick Look", () => {
    beforeEach(() => {
      ar.quickLook = true;
      vi.stubGlobal(
        "requestAnimationFrame",
        (callback: FrameRequestCallback) => {
          callback(0);
          return 0;
        },
      );
    });

    afterEach(() => {
      vi.unstubAllGlobals();
    });

    it("loads no AR viewer beside the open 3D view", async () => {
      const { prepareAr } = await import("@/frontend/utils/arViewer");
      vi.mocked(prepareAr).mockClear();

      const wrapper = await mount({ model: model() });

      expect(prepareAr).not.toHaveBeenCalled();
      expect(button(wrapper).exists()).toBe(true);
    });

    it("frees the 3D view before it loads the holo for Quick Look", async () => {
      const wrapper = await mount({ model: model() });
      const freedFirst = vi.fn();
      ar.openQuickLook.mockImplementationOnce(async () => {
        freedFirst(wrapper.emitted("quickLook")?.length);
      });

      await button(wrapper).trigger("click");
      await flushPromises();

      expect(freedFirst).toHaveBeenCalledWith(1);
      expect(ar.openQuickLook).toHaveBeenCalledWith(HOLO, expect.any(Function));
    });

    it("never loads model-viewer for Quick Look", async () => {
      const { prepareAr } = await import("@/frontend/utils/arViewer");
      vi.mocked(prepareAr).mockClear();

      const wrapper = await mount({ model: model() });
      await button(wrapper).trigger("click");
      await flushPromises();

      expect(prepareAr).not.toHaveBeenCalled();
    });

    it("keeps the button while the holo converts, with the 3D view gone", async () => {
      const late = { resolve: () => {} };
      ar.openQuickLook.mockImplementationOnce(
        () => new Promise<void>((resolve) => (late.resolve = resolve)),
      );

      const wrapper = await mount({ model: model() });
      await button(wrapper).trigger("click");
      await wrapper.setProps({ active: false });
      await flushPromises();

      expect(button(wrapper).exists()).toBe(true);
      expect(button(wrapper).attributes("disabled")).toBeDefined();

      late.resolve();
      await flushPromises();

      expect(button(wrapper).exists()).toBe(false);
    });

    it("says when Quick Look is done, so 3D may come back", async () => {
      const wrapper = await mount({ model: model() });
      await button(wrapper).trigger("click");
      await flushPromises();

      expect(wrapper.emitted("quickLookEnd")).toHaveLength(1);
    });

    it("says so when Quick Look fails, and still ends", async () => {
      ar.openQuickLook.mockRejectedValueOnce(new Error("decode"));
      displayAlert.mockClear();

      const wrapper = await mount({ model: model() });
      await button(wrapper).trigger("click");
      await flushPromises();

      expect(displayAlert).toHaveBeenCalled();
      expect(wrapper.emitted("quickLookEnd")).toHaveLength(1);
    });

    it("converts once for a second tap while the first is running", async () => {
      ar.openQuickLook.mockImplementationOnce(
        () => new Promise<void>(() => {}),
      );

      const wrapper = await mount({ model: model() });
      await button(wrapper).trigger("click");
      await button(wrapper).trigger("click");
      await flushPromises();

      expect(ar.openQuickLook).toHaveBeenCalledOnce();
    });

    it("no longer wants Quick Look once the ship changed", async () => {
      const wrapper = await mount({ model: model() });
      await button(wrapper).trigger("click");
      await flushPromises();

      const wanted = ar.openQuickLook.mock.calls[0][1]!;
      expect(wanted()).toBe(true);

      await wrapper.setProps({
        model: model({
          media: { holo: { url: "https://fleetyards.test/files/other.glb" } },
        } as Partial<Model>),
      });

      expect(wanted()).toBe(false);
    });

    it("no longer wants Quick Look once the page is left", async () => {
      const wrapper = await mount({ model: model() });
      await button(wrapper).trigger("click");
      await flushPromises();

      const wanted = ar.openQuickLook.mock.calls[0][1]!;
      wrapper.unmount();

      expect(wanted()).toBe(false);
    });
  });
});
