import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import FleetchartCanvas from "./index.vue";
import type { FleetchartEntry } from "@/frontend/components/Fleetchart/geometry";
import {
  FleetchartFacings,
  FleetchartLayouts,
  FleetchartShipStates,
  FleetchartViewpoints,
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
      topView: {
        url: `${id}-top.png`,
        largeUrl: `${id}-top-large.png`,
        mediumUrl: `${id}-top-medium.png`,
        width: 1000,
        height: 500,
      },
    },
  }) as unknown as FleetchartEntry;

const canvasStubs = {
  BtnDropdown: { template: "<div><slot name='label' /><slot /></div>" },
  Btn: {
    props: ["disabled"],
    template: '<button :disabled="disabled"><slot /></button>',
  },
  BtnGroup: { template: "<div><slot /></div>" },
  DownloadScreenshotBtn: true,
  FleetchartCanvasSavedLayouts: true,
  FleetchartCanvasAddShips: true,
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

  describe("a shared layout", () => {
    it("shows the arrangement but cannot change it", async () => {
      const store = useFleetchartStore();

      store.updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });
      store.updatePlacements({
        namespace: "hangar",
        placements: { a: { x: 500, y: 500 } },
      });

      const wrapper = track(
        mount(FleetchartCanvas, {
          props: {
            namespace: "hangar",
            items: [entry("a")],
            canArrange: true,
            readOnly: true,
          },
          global: { stubs: canvasStubs, directives: { tooltip: {} } },
        }),
      );
      const ship = wrapper.get("[data-test='fleetchart-ship']");
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
      window.dispatchEvent(new Event("pointerup"));
      await nextTick();

      expect(store.fleetchartPlacements("hangar").a.x).toBe(500);
      expect(wrapper.find("[data-test='fleetchart-undo']").exists()).toBe(
        false,
      );
      expect(
        wrapper.find("[data-test='fleetchart-saved-layouts']").exists(),
      ).toBe(false);
      expect(
        wrapper.find("[data-test='fleetchart-ship-controls']").exists(),
      ).toBe(false);
      expect(wrapper.find("[data-test='fleetchart-options']").exists()).toBe(
        false,
      );
      expect(wrapper.text()).not.toContain("labels.fleetchartApp.viewpoint");
      expect(wrapper.text()).not.toContain("actions.showLabels");
      expect(wrapper.text()).toContain("actions.resetZoom");
      expect(wrapper.find("[data-test='fleetchart-grid']").exists()).toBe(true);
    });
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

    describe("controls on the selected ship", () => {
      const controls = (wrapper: ReturnType<typeof mountCanvas>) =>
        wrapper.find("[data-test='fleetchart-ship-controls']");

      it("appear only once a ship is selected, outside the export", async () => {
        const wrapper = await mountFree();

        expect(controls(wrapper).exists()).toBe(false);

        await drag(wrapper, 0);

        expect(controls(wrapper).exists()).toBe(true);
        expect(
          wrapper
            .get("#fleetchart")
            .find("[data-test='fleetchart-ship-controls']")
            .exists(),
        ).toBe(false);
      });

      it("go away on Escape and on a press beside the ship", async () => {
        const wrapper = await mountFree();

        await drag(wrapper, 0);
        window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
        await nextTick();

        expect(controls(wrapper).exists()).toBe(false);

        await drag(wrapper, 0);
        await wrapper.get("#fleetchart").trigger("pointerdown");

        expect(controls(wrapper).exists()).toBe(false);
      });

      it("show one ship from another angle and leave the others", async () => {
        const wrapper = await mountFree();

        await drag(wrapper, 0);
        await wrapper
          .get("[data-test='fleetchart-ship-view-top']")
          .trigger("click");

        const views = [placement("a").viewpoint, placement("b").viewpoint];

        expect(views).toContain(FleetchartViewpoints.TOP);
        expect(views).toContain(undefined);
      });

      it("keep a ship's angle when it is dragged", async () => {
        const wrapper = await mountFree();

        await drag(wrapper, 0);
        await wrapper
          .get("[data-test='fleetchart-ship-view-top']")
          .trigger("click");

        const id = placement("a").viewpoint ? "a" : "b";

        await drag(wrapper, 40);

        expect(placement(id).viewpoint).toBe(FleetchartViewpoints.TOP);
      });

      it("offer only the angles a ship has a picture for", async () => {
        const wrapper = await mountFree();

        await drag(wrapper, 0);

        expect(
          wrapper
            .get("[data-test='fleetchart-ship-view-port']")
            .attributes("disabled"),
        ).toBeUndefined();
        expect(
          wrapper
            .get("[data-test='fleetchart-ship-view-front']")
            .attributes("disabled"),
        ).toBeDefined();
      });

      it("set one ship's state, leaving the others", async () => {
        const store = useFleetchartStore();
        store.updateLayout({
          namespace: "hangar",
          layout: FleetchartLayouts.FREE,
        });

        const landed = (id: string) => {
          const base = entry(id) as unknown as { media: object };

          base.media = {
            ...base.media,
            landedPortView: {
              url: `${id}-landed.png`,
              mediumUrl: `${id}-landed.png`,
              width: 1000,
              height: 500,
            },
          };

          return base as unknown as FleetchartEntry;
        };
        const wrapper = mountCanvas([landed("a"), landed("b")]);

        await nextTick();
        await drag(wrapper, 0);
        await wrapper
          .get("[data-test='fleetchart-ship-state-landed']")
          .trigger("click");

        const states = [placement("a").state, placement("b").state];

        expect(states).toContain(FleetchartShipStates.LANDED);
        expect(states).toContain(undefined);
        expect(wrapper.html()).toContain("-landed.png");
      });

      it("set the facing from the dropdown", async () => {
        const wrapper = await mountFree();

        await drag(wrapper, 0);
        await wrapper
          .get("[data-test='fleetchart-ship-facing-bottom']")
          .trigger("click");

        expect([placement("a").facing, placement("b").facing]).toContain(
          FleetchartFacings.BOTTOM,
        );
      });
    });

    describe("several ships", () => {
      const ids = () => ["a", "b"];

      const shipElement = (
        wrapper: ReturnType<typeof mountCanvas>,
        index: number,
      ) => wrapper.findAll("[data-test='fleetchart-ship']")[index].element;

      const press = (element: Element, init: { shiftKey?: boolean } = {}) => {
        const down = new Event("pointerdown", { bubbles: true });

        Object.assign(down, {
          button: 0,
          pointerType: "mouse",
          clientX: 0,
          clientY: 0,
          ...init,
        });
        element.dispatchEvent(down);
      };

      const release = async (distance = 0) => {
        if (distance) {
          const move = new Event("pointermove");

          Object.assign(move, { clientX: distance, clientY: 0 });
          window.dispatchEvent(move);
        }

        window.dispatchEvent(new Event("pointerup"));
        await nextTick();
      };

      const selectBoth = async (wrapper: ReturnType<typeof mountCanvas>) => {
        press(shipElement(wrapper, 0));
        await release();
        press(shipElement(wrapper, 1), { shiftKey: true });
        await release();
      };

      it("narrows to one ship on a plain press without a move", async () => {
        const wrapper = await mountFree();

        await selectBoth(wrapper);
        press(shipElement(wrapper, 0));
        await release();
        await wrapper
          .get("[data-test='fleetchart-ship-facing-top']")
          .trigger("click");

        expect(
          [placement("a").facing, placement("b").facing].filter(
            (value) => value === FleetchartFacings.TOP,
          ),
        ).toHaveLength(1);
      });

      it("adds no undo step for a rotation of nothing", async () => {
        const wrapper = await mountFree();

        window.dispatchEvent(new KeyboardEvent("keydown", { key: "r" }));
        await nextTick();

        expect(
          wrapper.get("[data-test='fleetchart-undo']").attributes("disabled"),
        ).toBeDefined();
      });

      it("drops a selection box when the pointer is cancelled", async () => {
        const wrapper = await mountFree();
        const viewport = wrapper.get(".fleetchart-canvas__viewport").element;

        press(viewport, { shiftKey: true });

        const move = new Event("pointermove");

        Object.assign(move, { clientX: 500, clientY: 500 });
        window.dispatchEvent(move);
        await nextTick();
        window.dispatchEvent(new Event("pointercancel"));
        await nextTick();

        expect(wrapper.find("[data-test='fleetchart-marquee']").exists()).toBe(
          false,
        );
      });

      it("moves every selected ship by the same distance", async () => {
        const wrapper = await mountFree();
        const before = ids().map((id) => ({ ...placement(id) }));

        await selectBoth(wrapper);
        press(shipElement(wrapper, 0));
        await release(40);

        expect(placement("a").x).toBe(before[0].x + 10);
        expect(placement("b").x).toBe(before[1].x + 10);
      });

      it("applies a change to every selected ship", async () => {
        const wrapper = await mountFree();

        await selectBoth(wrapper);
        await wrapper
          .get("[data-test='fleetchart-ship-facing-top']")
          .trigger("click");

        expect(placement("a").facing).toBe(FleetchartFacings.TOP);
        expect(placement("b").facing).toBe(FleetchartFacings.TOP);
      });

      it("drops a ship from the selection on a second Shift press", async () => {
        const wrapper = await mountFree();

        await selectBoth(wrapper);
        press(shipElement(wrapper, 1), { shiftKey: true });
        await release();
        await wrapper
          .get("[data-test='fleetchart-ship-facing-top']")
          .trigger("click");

        expect([placement("a").facing, placement("b").facing].sort()).toEqual([
          FleetchartFacings.LEFT,
          FleetchartFacings.TOP,
        ]);
      });

      it("brings a ship to the front and sends it to the back", async () => {
        const wrapper = await mountFree();

        press(shipElement(wrapper, 0));
        await release();
        await wrapper
          .get("[data-test='fleetchart-bring-to-front']")
          .trigger("click");

        const shipStyle = () => (shipElement(wrapper, 0) as HTMLElement).style;
        const front = Number(shipStyle().zIndex);

        await wrapper
          .get("[data-test='fleetchart-send-to-back']")
          .trigger("click");

        expect(front).toBeGreaterThan(0);
        expect(Number(shipStyle().zIndex)).toBeLessThan(0);
      });

      it("selects and moves grouped ships as one", async () => {
        const wrapper = await mountFree();
        const before = ids().map((id) => ({ ...placement(id) }));

        await selectBoth(wrapper);
        await wrapper
          .get("[data-test='fleetchart-group-ships']")
          .trigger("click");
        window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
        await nextTick();

        press(shipElement(wrapper, 0));
        await release(40);

        expect(placement("a").groupId).toBe(placement("b").groupId);
        expect(placement("a").x).toBe(before[0].x + 10);
        expect(placement("b").x).toBe(before[1].x + 10);
      });

      it("moves one ship alone again once ungrouped", async () => {
        const wrapper = await mountFree();

        await selectBoth(wrapper);
        await wrapper
          .get("[data-test='fleetchart-group-ships']")
          .trigger("click");
        await wrapper
          .get("[data-test='fleetchart-ungroup-ships']")
          .trigger("click");
        window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
        await nextTick();

        const before = ids().map((id) => ({ ...placement(id) }));

        press(shipElement(wrapper, 0));
        await release(40);

        const moved = ids().filter(
          (id, index) => placement(id).x !== before[index].x,
        );

        expect(moved).toHaveLength(1);
      });

      it("selects the ships inside a box drawn with Shift", async () => {
        const wrapper = await mountFree();
        const viewport = wrapper.get(".fleetchart-canvas__viewport").element;

        press(viewport, { shiftKey: true });

        const move = new Event("pointermove");

        Object.assign(move, { clientX: 5000, clientY: 5000 });
        window.dispatchEvent(move);
        await nextTick();

        expect(wrapper.find("[data-test='fleetchart-marquee']").exists()).toBe(
          true,
        );

        await release();
        await wrapper
          .get("[data-test='fleetchart-ship-facing-top']")
          .trigger("click");

        expect(placement("a").facing).toBe(FleetchartFacings.TOP);
        expect(placement("b").facing).toBe(FleetchartFacings.TOP);
      });
    });

    it("saves the stacking as it is drawn, whatever the sort", async () => {
      const wrapper = await mountFree();

      await wrapper
        .get("[data-test='fleetchart-saved-layouts']")
        .trigger("click");

      const saved = wrapper
        .findComponent({ name: "FleetchartCanvasSavedLayouts" })
        .props("placements") as { vehicleId: string; order: number }[];

      expect(saved.map(({ order }) => order).sort()).toEqual([0, 1]);
    });

    describe("catalogue ships", () => {
      const catalogueEntry = (id: string) =>
        ({
          ...entry("hornet"),
          id,
          notOwned: true,
        }) as unknown as FleetchartEntry;

      const mountWithCatalogueShip = async () => {
        const store = useFleetchartStore();

        store.updateLayout({
          namespace: "hangar",
          layout: FleetchartLayouts.FREE,
        });
        store.updatePlacements({
          namespace: "hangar",
          placements: {
            a: { x: 0, y: 0 },
            tried: { x: 100, y: 100, modelId: "hornet-id" },
          },
        });

        const wrapper = mountCanvas([entry("a"), catalogueEntry("tried")]);

        await nextTick();

        return wrapper;
      };

      const press = async (
        wrapper: ReturnType<typeof mountCanvas>,
        index: number,
      ) => {
        const down = new Event("pointerdown", { bubbles: true });

        Object.assign(down, {
          button: 0,
          pointerType: "mouse",
          clientX: 0,
          clientY: 0,
        });
        wrapper
          .findAll("[data-test='fleetchart-ship']")
          [index].element.dispatchEvent(down);
        window.dispatchEvent(new Event("pointerup"));
        await nextTick();
      };

      const tryingOut = (wrapper: ReturnType<typeof mountCanvas>) =>
        wrapper
          .findAll("[data-test='fleetchart-ship']")
          .findIndex((ship) =>
            ship.find("[data-test='fleetchart-ship-not-owned']").exists(),
          );

      it("adds a ship in front of the others, selected, with its own id", async () => {
        const wrapper = await mountFree();

        placement("a").order = 5;

        await wrapper
          .get("[data-test='fleetchart-add-ships']")
          .trigger("click");
        wrapper
          .findComponent({ name: "FleetchartCanvasAddShips" })
          .vm.$emit("add", { id: "hornet-id", slug: "hornet" });
        wrapper
          .findComponent({ name: "FleetchartCanvasAddShips" })
          .vm.$emit("add", { id: "hornet-id", slug: "hornet" });
        await nextTick();

        const added = Object.entries(
          useFleetchartStore().fleetchartPlacements("hangar"),
        ).filter(([, { modelId }]) => modelId === "hornet-id");

        expect(added).toHaveLength(2);
        expect(added[0][1].order).toBe(6);
        expect(added[1][1].order).toBe(7);
        expect(added[0][1].x).not.toBe(added[1][1].x);
      });

      it("marks only the ship that is not owned", async () => {
        const wrapper = await mountWithCatalogueShip();

        expect(
          wrapper.findAll("[data-test='fleetchart-ship-not-owned']"),
        ).toHaveLength(1);
      });

      it("offers removal for that ship only, and undo brings it back", async () => {
        const wrapper = await mountWithCatalogueShip();
        const remove = "[data-test='fleetchart-remove-ship']";
        const owned = tryingOut(wrapper) === 0 ? 1 : 0;

        await press(wrapper, owned);

        expect(wrapper.find(remove).exists()).toBe(false);

        await press(wrapper, tryingOut(wrapper));
        await wrapper.get(remove).trigger("click");

        expect(placement("tried")).toBeUndefined();
        expect(placement("a")).toBeDefined();

        await wrapper.get("[data-test='fleetchart-undo']").trigger("click");

        expect(placement("tried").modelId).toBe("hornet-id");
      });

      it("stays a catalogue ship when moved or reset", async () => {
        const wrapper = await mountWithCatalogueShip();

        await wrapper
          .get("[data-test='fleetchart-arrange-packed']")
          .trigger("click");

        expect(placement("tried").modelId).toBe("hornet-id");

        await wrapper
          .get("[data-test='fleetchart-reset-arrangement']")
          .trigger("click");

        expect(placement("tried").modelId).toBe("hornet-id");
        expect(placement("a").modelId).toBeUndefined();
      });

      it("saves owned and catalogue ships apart, stacked as one chart", async () => {
        const wrapper = await mountWithCatalogueShip();

        await wrapper
          .get("[data-test='fleetchart-saved-layouts']")
          .trigger("click");

        const panel = wrapper.findComponent({
          name: "FleetchartCanvasSavedLayouts",
        });
        const owned = panel.props("placements") as {
          vehicleId: string;
          order: number;
        }[];
        const tried = panel.props("cataloguePlacements") as {
          id: string;
          modelId: string;
          order: number;
        }[];

        expect(owned.map(({ vehicleId }) => vehicleId)).toEqual(["a"]);
        expect(tried.map(({ id, modelId }) => [id, modelId])).toEqual([
          ["tried", "hornet-id"],
        ]);
        expect([owned[0].order, tried[0].order].sort()).toEqual([0, 1]);
      });
    });

    describe("arranging", () => {
      const seed = () => {
        const store = useFleetchartStore();

        store.updateLayout({
          namespace: "hangar",
          layout: FleetchartLayouts.FREE,
        });
        store.updatePlacements({
          namespace: "hangar",
          placements: {
            a: { x: 0, y: 0, facing: FleetchartFacings.TOP },
            b: { x: 1000, y: 1000, viewpoint: FleetchartViewpoints.TOP },
            c: { x: 2000, y: 2000 },
          },
        });
      };

      const selectFirstTwo = async (
        wrapper: ReturnType<typeof mountCanvas>,
      ) => {
        const ships = wrapper.findAll("[data-test='fleetchart-ship']");

        for (const [index, shiftKey] of [
          [0, false],
          [1, true],
        ] as const) {
          const down = new Event("pointerdown", { bubbles: true });

          Object.assign(down, {
            button: 0,
            pointerType: "mouse",
            clientX: 0,
            clientY: 0,
            shiftKey,
          });
          ships[index].element.dispatchEvent(down);
          window.dispatchEvent(new Event("pointerup"));
          await nextTick();
        }
      };

      it("arranges the whole chart, each ship keeping its own settings", async () => {
        seed();

        const wrapper = mountCanvas([entry("a"), entry("b"), entry("c")]);

        await wrapper
          .get("[data-test='fleetchart-arrange-packed']")
          .trigger("click");

        expect(placement("c").x).not.toBe(2000);
        expect(Math.abs(placement("c").y - placement("a").y)).toBeLessThan(
          1000,
        );
        expect(placement("a").facing).toBe(FleetchartFacings.TOP);
        expect(placement("b").viewpoint).toBe(FleetchartViewpoints.TOP);
      });

      it("arranges only the selected ships, leaving the rest", async () => {
        seed();

        const wrapper = mountCanvas([entry("a"), entry("b"), entry("c")]);
        const before = {
          a: placement("a"),
          b: placement("b"),
          c: placement("c"),
        };

        await selectFirstTwo(wrapper);
        await wrapper
          .get("[data-test='fleetchart-arrange-classic']")
          .trigger("click");

        const moved = (["a", "b", "c"] as const).filter(
          (id) => placement(id).x !== before[id].x,
        );

        expect(moved.length).toBeGreaterThan(0);
        expect(moved.length).toBeLessThan(3);
      });

      it("groups by manufacturer with headings, stored on each ship", async () => {
        seed();

        const brand = (id: string, name: string) =>
          ({
            ...(entry(id) as object),
            manufacturer: { code: "X", name },
          }) as FleetchartEntry;
        const wrapper = mountCanvas([
          brand("a", "Anvil"),
          brand("b", "Anvil"),
          brand("c", "Drake"),
        ]);

        await wrapper
          .get("[data-test='fleetchart-arrange-group-manufacturer']")
          .trigger("click");

        expect(placement("a").heading).toBe("Anvil");
        expect(placement("c").heading).toBe("Drake");
        expect(
          wrapper
            .findAll("[data-test='fleetchart-group-heading']")
            .map((heading) => heading.text())
            .sort(),
        ).toEqual(["Anvil", "Drake"]);

        await wrapper
          .get("[data-test='fleetchart-arrange-group-none']")
          .trigger("click");

        expect(placement("a").heading).toBeUndefined();
        expect(
          wrapper.findAll("[data-test='fleetchart-group-heading']"),
        ).toHaveLength(0);
      });

      it("can be undone", async () => {
        seed();

        const wrapper = mountCanvas([entry("a"), entry("b"), entry("c")]);
        const before = placement("c");

        await wrapper
          .get("[data-test='fleetchart-arrange-columns']")
          .trigger("click");
        window.dispatchEvent(
          new KeyboardEvent("keydown", { key: "z", ctrlKey: true }),
        );
        await nextTick();

        expect(placement("c")).toEqual(before);
      });
    });

    it("shows one panel at a time", async () => {
      const wrapper = await mountFree();

      await wrapper.get("[data-test='fleetchart-options']").trigger("click");
      expect(wrapper.find("[data-test='fleetchart-settings']").exists()).toBe(
        true,
      );

      await wrapper
        .get("[data-test='fleetchart-saved-layouts']")
        .trigger("click");
      expect(wrapper.find("[data-test='fleetchart-settings']").exists()).toBe(
        false,
      );
    });

    it("clears a ship's angle on reset", async () => {
      const store = useFleetchartStore();
      store.updateLayout({
        namespace: "hangar",
        layout: FleetchartLayouts.FREE,
      });
      store.updatePlacements({
        namespace: "hangar",
        placements: { a: { x: 1, y: 1, viewpoint: FleetchartViewpoints.TOP } },
      });

      const wrapper = mountCanvas([entry("a")]);

      await wrapper
        .get("[data-test='fleetchart-reset-arrangement']")
        .trigger("click");

      expect(placement("a").viewpoint).toBeUndefined();
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

  it("shows a ship from a view it has when it lacks the chosen one", async () => {
    const wrapper = mountCanvas([entry("a")]);

    useFleetchartStore().updateViewpoint({
      namespace: "hangar",
      viewpoint: FleetchartViewpoints.REAR,
    });
    await nextTick();

    expect(
      wrapper.get("[data-test='fleetchart-ship'] img").attributes("src"),
    ).toContain("a");
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
