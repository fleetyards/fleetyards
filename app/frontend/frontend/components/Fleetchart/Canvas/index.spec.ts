import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import FleetchartCanvas from "./index.vue";
import type { FleetchartEntry } from "@/frontend/components/Fleetchart/geometry";
import {
  FleetchartFacings,
  FleetchartLayouts,
  useFleetchartStore,
} from "@/shared/stores/fleetchart";

const panzoomInstance = {
  on: vi.fn(),
  dispose: vi.fn(),
  zoomAbs: vi.fn(),
  moveTo: vi.fn(),
  getTransform: () => ({ x: 0, y: 0, scale: 1 }),
};

vi.mock("panzoom", () => ({ default: vi.fn(() => panzoomInstance) }));

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () => ({ query: {} }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ on: () => () => {} }),
}));

const entry = (id: string, length = 100): FleetchartEntry =>
  ({
    id,
    slug: id,
    name: id,
    productionStatus: "flight-ready",
    manufacturer: { code: "RSI" },
    metrics: { fleetchartOffsetLength: length },
    media: {
      portView: {
        url: `${id}.png`,
        largeUrl: `${id}-large.png`,
        mediumUrl: `${id}-medium.png`,
        width: 1000,
        height: 500,
      },
    },
  }) as unknown as FleetchartEntry;

const canvasStubs = {
  BtnDropdown: { template: "<div><slot name='label' /><slot /></div>" },
  Btn: { template: "<button><slot /></button>" },
  DownloadScreenshotBtn: true,
  FleetChartStatusBtn: true,
  CommunityLogo: true,
};

const mounted: { unmount: () => void }[] = [];

const track = <T extends { unmount: () => void }>(wrapper: T) => {
  mounted.push(wrapper);

  return wrapper;
};

const mountCanvas = (items: FleetchartEntry[]) =>
  track(
    mount(FleetchartCanvas, {
      props: { namespace: "hangar", items, canArrange: true },
      global: {
        stubs: canvasStubs,
        directives: { tooltip: {} },
      },
    }),
  );

const showInColumns = () => {
  useFleetchartStore().updateLayout({
    namespace: "hangar",
    layout: FleetchartLayouts.COLUMNS,
  });
};

const shipPositions = (wrapper: ReturnType<typeof mountCanvas>) =>
  wrapper.findAll("[data-test='fleetchart-ship']").map((ship) => {
    const { left, top } = (ship.element as HTMLElement).style;

    return { left: parseFloat(left), top: parseFloat(top) };
  });

describe("FleetchartCanvas", () => {
  afterEach(() => {
    mounted.splice(0).forEach((wrapper) => wrapper.unmount());
  });

  beforeEach(() => {
    setActivePinia(createPinia());
    window.innerWidth = 1600;
    window.innerHeight = 900;
  });

  it("draws every ship with views at its real size", () => {
    const wrapper = mountCanvas([entry("a", 100), entry("b", 50)]);
    const ships = wrapper.findAll("[data-test='fleetchart-ship']");

    expect(ships).toHaveLength(2);
    expect(
      ships.map((ship) => (ship.element as HTMLElement).style.width).sort(),
    ).toEqual(["200px", "400px"]);
  });

  it("leaves out a ship whose views have not arrived", () => {
    const wrapper = mountCanvas([
      entry("a"),
      { ...entry("b"), media: {} } as FleetchartEntry,
    ]);

    expect(wrapper.findAll("[data-test='fleetchart-ship']")).toHaveLength(1);
  });

  it("gives the scene an explicit size that contains every ship", () => {
    const wrapper = mountCanvas([entry("a"), entry("b")]);
    const scene = wrapper.get("#fleetchart").element as HTMLElement;

    const width = parseFloat(scene.style.width);
    const height = parseFloat(scene.style.height);

    shipPositions(wrapper).forEach(({ left, top }) => {
      expect(left).toBeGreaterThanOrEqual(0);
      expect(top).toBeGreaterThanOrEqual(0);
      expect(left + 400).toBeLessThanOrEqual(width);
      expect(top + 200).toBeLessThanOrEqual(height);
    });
  });

  it("rearranges the same ships when the layout changes", async () => {
    showInColumns();

    const wrapper = mountCanvas(
      Array.from({ length: 6 }, (_, index) => entry(`${index}`)),
    );
    const columns = shipPositions(wrapper);

    useFleetchartStore().updateLayout({
      namespace: "hangar",
      layout: FleetchartLayouts.CLASSIC,
    });
    await nextTick();

    const classic = shipPositions(wrapper);

    expect(classic).toHaveLength(columns.length);
    expect(classic).not.toEqual(columns);
  });

  it("starts a newly chosen layout from the top left", async () => {
    mountCanvas([entry("a")]);
    panzoomInstance.moveTo.mockClear();

    useFleetchartStore().updateLayout({
      namespace: "hangar",
      layout: FleetchartLayouts.CLASSIC,
    });
    await nextTick();

    expect(panzoomInstance.moveTo).toHaveBeenCalledWith(0, 0);
  });

  it("turns a ship and lays it out by its turned size", async () => {
    const wrapper = mountCanvas([entry("a", 100)]);

    useFleetchartStore().updateOptions({
      namespace: "hangar",
      options: { facing: FleetchartFacings.TOP },
    });
    await nextTick();

    const ship = wrapper.get("[data-test='fleetchart-ship']");
    const { width, height } = (ship.element as HTMLElement).style;

    expect(width).toBe("200px");
    expect(height).toBe("400px");
    expect(ship.find(".fleetchart-canvas-item__frame--top").exists()).toBe(
      true,
    );
  });

  it("mirrors a ship facing right, keeping its size", async () => {
    const wrapper = mountCanvas([entry("a", 100)]);

    useFleetchartStore().updateOptions({
      namespace: "hangar",
      options: { facing: FleetchartFacings.RIGHT },
    });
    await nextTick();

    const ship = wrapper.get("[data-test='fleetchart-ship']");

    expect((ship.element as HTMLElement).style.width).toBe("400px");
    expect(ship.find(".fleetchart-canvas-item__frame--right").exists()).toBe(
      true,
    );
  });

  it("takes less room packed than in columns", async () => {
    showInColumns();

    const wrapper = mountCanvas([
      entry("large", 400),
      ...Array.from({ length: 8 }, (_, index) => entry(`small-${index}`, 20)),
    ]);
    const area = () => {
      const { width, height } = (
        wrapper.get("#fleetchart").element as HTMLElement
      ).style;

      return parseFloat(width) * parseFloat(height);
    };
    const columnsArea = area();

    useFleetchartStore().updateLayout({
      namespace: "hangar",
      layout: FleetchartLayouts.PACKED,
    });
    await nextTick();

    expect(area()).toBeLessThan(columnsArea);
  });

  it("opens a packed chart zoomed out to fit the screen", () => {
    panzoomInstance.zoomAbs.mockClear();

    mountCanvas([entry("large", 2000)]);

    const [, , scale] = panzoomInstance.zoomAbs.mock.lastCall as number[];

    expect(scale).toBeLessThan(1);
    expect(8000 * scale).toBeLessThanOrEqual(window.innerWidth);
  });

  it("keeps the view when a toggle leaves the chart's size alone", async () => {
    mountCanvas([entry("a")]);
    panzoomInstance.zoomAbs.mockClear();

    useFleetchartStore().updateOptions({
      namespace: "hangar",
      options: { scaleBar: true },
    });
    await nextTick();

    expect(panzoomInstance.zoomAbs).not.toHaveBeenCalled();
  });

  it("ignores a saved position when opening packed", () => {
    useFleetchartStore().updateZoomData({
      namespace: "hangar",
      zoomData: { x: -5000, y: -5000, scale: 3 },
    });
    panzoomInstance.moveTo.mockClear();

    mountCanvas([entry("a")]);

    const [x] = panzoomInstance.moveTo.mock.lastCall as number[];

    expect(x).toBeGreaterThan(-5000);
  });

  describe("free layout", () => {
    const mountFree = async () => {
      useFleetchartStore().updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });

      const wrapper = mountCanvas([entry("a"), entry("b")]);

      await nextTick();

      return wrapper;
    };

    const placement = (id: string) =>
      useFleetchartStore().fleetchartPlacements("hangar")[id];

    const drag = async (
      wrapper: ReturnType<typeof mountCanvas>,
      distance: number,
    ) => {
      const ship = wrapper.findAll("[data-test='fleetchart-ship']")[0];

      const down = new Event("pointerdown", { bubbles: true });
      Object.assign(down, {
        button: 0,
        pointerType: "mouse",
        clientX: 0,
        clientY: 0,
      });
      ship.element.dispatchEvent(down);

      const move = new Event("pointermove");
      Object.assign(move, { clientX: distance, clientY: 0 });
      window.dispatchEvent(move);
      window.dispatchEvent(new Event("pointerup"));
      await nextTick();
    };

    it("gives every ship a place, starting from the layout before it", async () => {
      await mountFree();

      expect(placement("a")).toBeDefined();
      expect(placement("b")).toBeDefined();
    });

    it("waits for the whole fleet before placing anything", async () => {
      useFleetchartStore().updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });

      const wrapper = track(
        mount(FleetchartCanvas, {
          props: {
            namespace: "hangar",
            items: [entry("a")],
            canArrange: true,
            arrangeReady: false,
          },
          global: { stubs: canvasStubs, directives: { tooltip: {} } },
        }),
      );

      await nextTick();
      expect(placement("a")).toBeUndefined();

      await wrapper.setProps({ arrangeReady: true });
      expect(placement("a")).toBeDefined();
    });

    it("leaves the arrangement alone on a chart that cannot arrange", async () => {
      useFleetchartStore().updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });

      const wrapper = track(
        mount(FleetchartCanvas, {
          props: { namespace: "hangar", items: [entry("a")] },
          global: { stubs: canvasStubs, directives: { tooltip: {} } },
        }),
      );

      await drag(wrapper, 40);

      expect(placement("a")).toBeUndefined();
    });

    it("keeps the place of a ship hidden by a filter on reset", async () => {
      const store = useFleetchartStore();
      store.updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });
      store.updatePlacements({
        namespace: "hangar",
        placements: { hidden: { x: 500, y: 500 }, a: { x: 1, y: 1 } },
      });

      const wrapper = mountCanvas([entry("a")]);

      await wrapper
        .get("[data-test='fleetchart-reset-arrangement']")
        .trigger("click");

      expect(placement("hidden")).toEqual({ x: 500, y: 500 });
      expect(placement("a").x).not.toBe(1);
    });

    it("puts a rotated ship back as it faces by default on reset", async () => {
      const store = useFleetchartStore();
      store.updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });
      store.updatePlacements({
        namespace: "hangar",
        placements: { a: { x: 1, y: 1, facing: FleetchartFacings.TOP } },
      });

      const wrapper = mountCanvas([entry("a", 100)]);

      await wrapper
        .get("[data-test='fleetchart-reset-arrangement']")
        .trigger("click");

      const ship = wrapper.get("[data-test='fleetchart-ship']");

      expect(placement("a").facing).toBe(FleetchartFacings.LEFT);
      expect((ship.element as HTMLElement).style.width).toBe("400px");
    });

    it("starts from the layout before it, boxes and groups included", async () => {
      const store = useFleetchartStore();
      store.updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.COLUMNS,
      });

      mountCanvas([entry("a"), entry("b")]);

      const expected = useFleetchartStore().fleetchartPlacements("hangar");

      expect(expected).toEqual({});

      store.updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });
      await nextTick();

      expect(placement("a").x).toBe(placement("b").x);
    });

    it("does not rotate while typing in a field", async () => {
      const wrapper = await mountFree();
      const input = document.createElement("input");
      document.body.appendChild(input);

      await drag(wrapper, 0);
      const before = { ...placement("a") };

      input.dispatchEvent(
        new KeyboardEvent("keydown", { key: "r", bubbles: true }),
      );
      await nextTick();
      input.remove();

      expect(placement("a")).toEqual(before);
    });

    it("drops a drag when the pointer is cancelled", async () => {
      const wrapper = await mountFree();
      const before = { ...placement("a") };
      const ship = wrapper.findAll("[data-test='fleetchart-ship']")[0];
      const down = new Event("pointerdown", { bubbles: true });

      Object.assign(down, {
        button: 0,
        pointerType: "mouse",
        clientX: 0,
        clientY: 0,
      });
      ship.element.dispatchEvent(down);

      const move = new Event("pointermove");

      Object.assign(move, { clientX: 40, clientY: 0 });
      window.dispatchEvent(move);
      window.dispatchEvent(new Event("pointercancel"));
      window.dispatchEvent(new Event("pointerup"));
      await nextTick();

      expect(placement("a")).toEqual(before);
    });

    it("moves a dragged ship by the distance in metres", async () => {
      const wrapper = await mountFree();
      const before = { ...placement("a") };

      await drag(wrapper, 40);

      expect(placement("a").x).toBe(before.x + 10);
      expect(placement("b")).toBeDefined();
    });

    it("leaves the ships alone while the chart is only being viewed", async () => {
      useFleetchartStore().updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.PACKED,
      });

      const wrapper = mountCanvas([entry("a")]);

      await drag(wrapper, 40);

      expect(placement("a")).toBeUndefined();
    });

    it("undoes a move", async () => {
      const wrapper = await mountFree();
      const before = { ...placement("a") };

      await drag(wrapper, 40);
      window.dispatchEvent(
        new KeyboardEvent("keydown", { key: "z", ctrlKey: true }),
      );
      await nextTick();

      expect(placement("a")).toEqual(before);
    });

    it("rotates only the selected ship", async () => {
      const wrapper = await mountFree();

      await drag(wrapper, 0);
      window.dispatchEvent(new KeyboardEvent("keydown", { key: "r" }));
      await nextTick();

      const facings = [placement("a").facing, placement("b").facing];

      expect(facings).toContain(FleetchartFacings.TOP);
      expect(facings).toContain(FleetchartFacings.LEFT);
    });

    it("ignores keys outside the free layout", async () => {
      useFleetchartStore().updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.PACKED,
      });
      mountCanvas([entry("a")]);

      window.dispatchEvent(new KeyboardEvent("keydown", { key: "r" }));
      await nextTick();

      expect(placement("a")).toBeUndefined();
    });
  });

  it("offers the screen height only where it means anything", async () => {
    showInColumns();

    const wrapper = mountCanvas([entry("a")]);
    const label = "labels.fleetchartApp.screenHeight";

    expect(wrapper.text()).toContain(label);

    useFleetchartStore().updateLayout({
      namespace: "hangar",
      layout: FleetchartLayouts.CLASSIC,
    });
    await nextTick();

    expect(wrapper.text()).not.toContain(label);
  });

  it("disposes of panzoom when it goes away", () => {
    const wrapper = mountCanvas([entry("a")]);

    wrapper.unmount();

    expect(panzoomInstance.dispose).toHaveBeenCalled();
  });
});
