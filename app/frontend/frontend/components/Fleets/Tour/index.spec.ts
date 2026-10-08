import { mount, type VueWrapper } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick } from "vue";
import FleetTour from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const BtnStub = defineComponent({
  name: "Btn",
  emits: ["click"],
  setup(_, { slots, emit, attrs }) {
    return () =>
      h(
        "button",
        { ...attrs, type: "button", onClick: () => emit("click") },
        slots.default?.(),
      );
  },
});

let wrapper: VueWrapper | undefined;
const targets: HTMLElement[] = [];

const addTab = (id: string) => {
  const element = document.createElement("li");
  element.dataset.tour = id;
  document.body.appendChild(element);
  targets.push(element);
};

const flush = async () => {
  for (let i = 0; i < 4; i += 1) await nextTick();
};

const card = () =>
  document.querySelector<HTMLElement>("[data-test='tour-card']");

// Every step the tour shows, in order, by clicking through to the end.
const walk = async () => {
  wrapper = mount(FleetTour, {
    attachTo: document.body,
    props: {
      open: true,
      "onUpdate:open": (value: boolean) => wrapper?.setProps({ open: value }),
    },
    global: { stubs: { Btn: BtnStub } },
  });
  await flush();

  const seen: string[] = [];

  while (card()) {
    seen.push(card()?.dataset.step ?? "");
    document.querySelector<HTMLElement>("[data-test='tour-next']")?.click();
    await flush();
  }

  return seen;
};

beforeEach(() => {
  // jsdom lays nothing out, so every element would read as not rendered.
  vi.spyOn(Element.prototype, "getClientRects").mockImplementation(
    () => [new DOMRect(0, 0, 10, 10)] as unknown as DOMRectList,
  );
  vi.stubGlobal(
    "matchMedia",
    vi.fn(() => ({
      matches: true,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    })),
  );
  Element.prototype.scrollIntoView = vi.fn();
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  while (targets.length) targets.pop()?.remove();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("FleetTour", () => {
  it("skips events and contracts while their tabs are switched off", async () => {
    ["fleet-members", "fleet-ships", "fleet-settings"].forEach(addTab);

    expect(await walk()).toEqual([
      "welcome",
      "members",
      "roles",
      "ships",
      "rsi",
      "discord",
      "settings",
    ]);
  });

  it("includes events and contracts when their tabs are rendered", async () => {
    [
      "fleet-members",
      "fleet-ships",
      "fleet-contracts",
      "fleet-events",
      "fleet-settings",
    ].forEach(addTab);

    expect(await walk()).toEqual([
      "welcome",
      "members",
      "roles",
      "ships",
      "events",
      "contracts",
      "rsi",
      "discord",
      "settings",
    ]);
  });

  // The mobile bar has no settings tab, and the setup steps are the point of
  // the tour, so they fall back to a centred card rather than disappearing.
  it("keeps the settings steps when the settings tab is not rendered", async () => {
    ["fleet-members", "fleet-ships"].forEach(addTab);

    const seen = await walk();

    expect(seen).toEqual(
      expect.arrayContaining(["roles", "rsi", "discord", "settings"]),
    );
  });
});
