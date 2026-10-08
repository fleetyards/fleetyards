import { mount, type VueWrapper } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick } from "vue";
import { createMemoryHistory, createRouter, type Router } from "vue-router";
import Tour from "./index.vue";
import type { TourStep } from "./types";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, params?: Record<string, unknown>) =>
      params ? `${key} ${JSON.stringify(params)}` : key,
  }),
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

const wrappers: VueWrapper[] = [];
const targets: HTMLElement[] = [];

const addTarget = (id: string) => {
  const element = document.createElement("button");
  element.dataset.tour = id;
  document.body.appendChild(element);
  targets.push(element);

  return element;
};

const STEPS: TourStep[] = [
  { id: "welcome", title: "Welcome", text: "Hello" },
  { id: "add", title: "Add", text: "Add ships", target: '[data-tour="add"]' },
  {
    id: "sync",
    title: "Sync",
    text: "Sync ships",
    target: '[data-tour="sync"]',
    requiresTarget: true,
  },
  {
    id: "stats",
    title: "Stats",
    text: "Your stats",
    target: '[data-tour="stats"]',
    requiresTarget: true,
  },
];

const mountTour = async (steps: TourStep[] = STEPS) => {
  // The tour can close itself while it mounts, before `mount` has returned.
  let wrapper: VueWrapper | undefined = undefined;

  wrapper = mount(Tour, {
    attachTo: document.body,
    props: {
      steps,
      open: true,
      "onUpdate:open": (value: boolean) => wrapper?.setProps({ open: value }),
    },
    global: { stubs: { Btn: BtnStub } },
  });

  wrappers.push(wrapper);

  await flush();

  return wrapper;
};

const flush = async () => {
  for (let i = 0; i < 4; i += 1) await nextTick();
};

const card = () =>
  document.querySelector<HTMLElement>("[data-test='tour-card']");
const hole = () => document.querySelector<HTMLElement>(".tour__hole");
const click = async (test: string) => {
  document.querySelector<HTMLElement>(`[data-test='${test}']`)?.click();
  await flush();
};
const press = async (key: string) => {
  card()?.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true }));
  await flush();
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
  while (wrappers.length) wrappers.pop()?.unmount();
  while (targets.length) targets.pop()?.remove();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("Tour", () => {
  it("leaves out steps whose required target is missing", async () => {
    addTarget("add");
    addTarget("stats");

    await mountTour();

    expect(card()?.dataset.step).toBe("welcome");
    expect(card()?.textContent).toContain('"current":1,"total":3');

    await click("tour-next");
    expect(card()?.dataset.step).toBe("add");

    await click("tour-next");
    expect(card()?.dataset.step).toBe("stats");
  });

  it("centres the card over the dimmed page when a step has no target", async () => {
    await mountTour();

    expect(card()?.dataset.step).toBe("welcome");
    expect(hole()?.classList).toContain("tour__hole--empty");

    await click("tour-next");

    // Optional targets fall back to the centred card rather than vanishing.
    expect(card()?.dataset.step).toBe("add");
    expect(hole()?.classList).toContain("tour__hole--empty");
  });

  it("frames the target of the current step", async () => {
    addTarget("add");

    await mountTour();
    await click("tour-next");

    expect(hole()?.classList).not.toContain("tour__hole--empty");
  });

  it("finishes on the last step", async () => {
    addTarget("stats");

    const wrapper = await mountTour();

    await click("tour-next");
    await click("tour-next");
    expect(card()?.dataset.step).toBe("stats");
    expect(document.querySelector("[data-test='tour-skip']")).toBeNull();
    expect(document.querySelector("[data-test='tour-next']")?.textContent).toBe(
      "actions.tour.done",
    );

    await click("tour-next");

    expect(wrapper.emitted("end")).toEqual([["finished"]]);
    expect(card()).toBeNull();
  });

  it("steps with the arrow keys and skips with Escape", async () => {
    const wrapper = await mountTour();

    await press("ArrowRight");
    expect(card()?.dataset.step).toBe("add");

    await press("ArrowLeft");
    expect(card()?.dataset.step).toBe("welcome");

    await press("ArrowLeft");
    expect(card()?.dataset.step).toBe("welcome");

    await press("Escape");

    expect(wrapper.emitted("end")).toEqual([["skipped"]]);
    expect(card()).toBeNull();
  });

  it("makes the page inert and hands focus back when it ends", async () => {
    const page = document.createElement("div");
    const trigger = document.createElement("button");
    page.appendChild(trigger);
    document.body.appendChild(page);
    targets.push(page);
    trigger.focus();

    await mountTour();

    expect(page.hasAttribute("inert")).toBe(true);
    expect(document.activeElement).toBe(card());

    await click("tour-skip");

    expect(page.hasAttribute("inert")).toBe(false);
    expect(document.activeElement).toBe(trigger);
  });

  it("starts a replay from the first step", async () => {
    const wrapper = await mountTour();

    await click("tour-next");
    expect(card()?.dataset.step).toBe("add");
    await press("Escape");
    expect(card()).toBeNull();

    await wrapper.setProps({ open: true });
    await flush();

    expect(card()?.dataset.step).toBe("welcome");
  });

  it("falls back to another element when its trigger has gone", async () => {
    const menu = addTarget("menu");
    const item = document.createElement("button");
    document.body.appendChild(item);
    targets.push(item);
    item.focus();

    let wrapper: VueWrapper | undefined = undefined;

    wrapper = mount(Tour, {
      attachTo: document.body,
      props: {
        steps: STEPS,
        open: true,
        returnFocusFallback: '[data-tour="menu"]',
        "onUpdate:open": (value: boolean) => wrapper?.setProps({ open: value }),
      },
      global: { stubs: { Btn: BtnStub } },
    });
    wrappers.push(wrapper);
    await flush();

    // The dropdown item that started it is closed away by now.
    item.remove();
    await click("tour-skip");

    expect(document.activeElement).toBe(menu);
  });

  it("leaves the page usable when unmounted before it has started", async () => {
    const page = document.createElement("div");
    document.body.appendChild(page);
    targets.push(page);

    const wrapper = mount(Tour, {
      attachTo: document.body,
      props: { steps: STEPS, open: true },
      global: { stubs: { Btn: BtnStub } },
    });
    wrapper.unmount();

    await flush();

    expect(page.hasAttribute("inert")).toBe(false);
    expect(card()).toBeNull();
  });

  it("does not move focus when unmounted, open or not", async () => {
    const elsewhere = addTarget("elsewhere");

    const closed = mount(Tour, {
      attachTo: document.body,
      props: { steps: STEPS, open: false, returnFocusFallback: "button" },
      global: { stubs: { Btn: BtnStub } },
    });
    elsewhere.focus();
    closed.unmount();
    expect(document.activeElement).toBe(elsewhere);

    const opened = await mountTour();
    wrappers.pop();
    opened.unmount();
    expect(document.activeElement).not.toBe(elsewhere);
    expect(elsewhere.hasAttribute("inert")).toBe(false);
  });

  it("finishes rather than skips with Escape on the last step", async () => {
    const wrapper = await mountTour();

    await press("ArrowRight");
    await press("Escape");

    expect(wrapper.emitted("end")).toEqual([["finished"]]);
  });

  it("keeps a marked subtree usable inside an inert page", async () => {
    const app = document.createElement("div");
    const page = document.createElement("main");
    const notifications = document.createElement("div");
    notifications.dataset.tourKeep = "";
    app.append(page, notifications);
    document.body.appendChild(app);
    targets.push(app);

    await mountTour();

    expect(app.hasAttribute("inert")).toBe(false);
    expect(page.hasAttribute("inert")).toBe(true);
    expect(notifications.hasAttribute("inert")).toBe(false);
  });

  it("reads the step text from the current props", async () => {
    const wrapper = await mountTour();

    await wrapper.setProps({
      steps: STEPS.map((step) => ({ ...step, title: `${step.title}!` })),
    });
    await flush();

    expect(card()?.textContent).toContain("Welcome!");
  });

  it("does not open over a modal", async () => {
    const modal = document.createElement("div");
    modal.className = "app-modal in";
    document.body.appendChild(modal);
    targets.push(modal);

    const wrapper = await mountTour();

    expect(card()).toBeNull();
    expect(modal.hasAttribute("inert")).toBe(false);
    expect(wrapper.emitted("start")).toBeUndefined();
  });

  it("announces when it is on screen", async () => {
    const wrapper = await mountTour();

    expect(wrapper.emitted("start")).toHaveLength(1);
  });

  it("makes content mounted while it runs inert too", async () => {
    await mountTour();

    const late = document.createElement("div");
    document.body.appendChild(late);
    targets.push(late);
    await flush();

    expect(late.hasAttribute("inert")).toBe(true);
  });

  it("leaves modified arrow keys to the browser", async () => {
    await mountTour();

    card()?.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "ArrowRight",
        altKey: true,
        bubbles: true,
      }),
    );
    await flush();

    expect(card()?.dataset.step).toBe("welcome");
  });

  it("keeps focus on Next between steps", async () => {
    await mountTour();

    const nextButton = document.querySelector<HTMLElement>(
      "[data-test='tour-next']",
    );
    nextButton?.focus();
    await click("tour-next");

    expect(card()?.dataset.step).toBe("add");
    expect(document.activeElement).toBe(nextButton);
  });

  it("ends rather than vanishes when its steps go away", async () => {
    const wrapper = await mountTour();

    await wrapper.setProps({ steps: [] });
    await flush();

    expect(wrapper.emitted("end")).toEqual([["finished"]]);
  });

  it("leaves focus alone after a start nothing triggered", async () => {
    const menu = addTarget("menu");
    (document.activeElement as HTMLElement | null)?.blur();

    let wrapper: VueWrapper | undefined = undefined;

    wrapper = mount(Tour, {
      attachTo: document.body,
      props: {
        steps: STEPS,
        open: true,
        returnFocusFallback: '[data-tour="menu"]',
        "onUpdate:open": (value: boolean) => wrapper?.setProps({ open: value }),
      },
      global: { stubs: { Btn: BtnStub } },
    });
    wrappers.push(wrapper);
    await flush();

    await click("tour-skip");

    expect(document.activeElement).not.toBe(menu);
  });

  it("opens over a modal that is still fading out", async () => {
    const modal = document.createElement("div");
    modal.className = "app-modal";
    document.body.appendChild(modal);
    targets.push(modal);

    await mountTour();

    expect(card()?.dataset.step).toBe("welcome");
  });

  it("follows the step that moves into place when an earlier one goes", async () => {
    addTarget("add");
    const wrapper = await mountTour();

    await click("tour-next");
    expect(card()?.dataset.step).toBe("add");

    await wrapper.setProps({
      steps: STEPS.filter((step) => step.id !== "welcome"),
    });
    await flush();

    expect(card()?.dataset.step).toBe("add");
    expect(card()?.textContent).toContain('"current":1,"total":1');
  });

  it("does not open when no step can be shown", async () => {
    const wrapper = await mountTour([STEPS[2]]);

    expect(card()).toBeNull();
    expect(wrapper.emitted("update:open")).toEqual([[false]]);
  });
});

describe("Tour across pages", () => {
  const Page = defineComponent({ render: () => h("div") });

  let router: Router;

  const ROUTED: TourStep[] = [
    { id: "welcome", title: "Welcome", text: "Hello", route: "/start" },
    {
      id: "members",
      title: "Members",
      text: "Invite",
      route: "/members",
      target: '[data-tour="invite"]',
    },
    {
      id: "events",
      title: "Events",
      text: "Plan",
      route: "/events",
      target: '[data-tour="events"]',
      requiresTarget: true,
    },
    { id: "settings", title: "Settings", text: "Done", route: "/settings" },
  ];

  // Rendering a target only once its page is open, the way a page's data
  // loads in after the navigation.
  const renderOn = (path: string, id: string, delay = 0) => {
    router.afterEach((to) => {
      if (to.path !== path) return;
      window.setTimeout(() => addTarget(id), delay);
    });
  };

  const mountRouted = async (steps: TourStep[] = ROUTED) => {
    let wrapper: VueWrapper | undefined = undefined;

    wrapper = mount(Tour, {
      attachTo: document.body,
      props: {
        steps,
        open: true,
        "onUpdate:open": (value: boolean) => wrapper?.setProps({ open: value }),
      },
      global: { stubs: { Btn: BtnStub }, plugins: [router] },
    });

    wrappers.push(wrapper);
    await flush();

    return wrapper;
  };

  // The tour polls for a target on a timer; let it, and the renders after it.
  const settle = async (ms = 200) => {
    await vi.advanceTimersByTimeAsync(ms);
    await flush();
  };

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ["setTimeout", "clearTimeout", "Date"] });
    router = createRouter({
      history: createMemoryHistory(),
      routes: ["/start", "/members", "/events", "/settings"].map((path) => ({
        path,
        component: Page,
      })),
    });
    await router.push("/start");
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("opens a step's page and waits for its target to render", async () => {
    renderOn("/members", "invite", 300);
    renderOn("/events", "events");

    await mountRouted();
    await settle();
    expect(card()?.dataset.step).toBe("welcome");

    await click("tour-next");
    await settle(100);

    expect(router.currentRoute.value.path).toBe("/members");
    expect(card()?.style.visibility).toBe("hidden");

    await settle(400);
    expect(card()?.dataset.step).toBe("members");
    expect(card()?.style.visibility).not.toBe("hidden");
    expect(hole()?.classList).not.toContain("tour__hole--empty");
  });

  it("passes over a step whose required target never renders", async () => {
    renderOn("/members", "invite");

    await mountRouted();
    await settle();
    await click("tour-next");
    await settle();
    expect(card()?.dataset.step).toBe("members");

    await click("tour-next");
    await settle();
    expect(router.currentRoute.value.path).toBe("/events");

    await settle(5000);
    expect(router.currentRoute.value.path).toBe("/settings");
    expect(card()?.dataset.step).toBe("settings");
    expect(card()?.textContent).toContain('"current":3,"total":3');
  });

  it("returns to the previous step's page on Back", async () => {
    renderOn("/members", "invite");
    renderOn("/events", "events");

    await mountRouted();
    await settle();
    await click("tour-next");
    await settle();
    await click("tour-next");
    await settle();
    expect(card()?.dataset.step).toBe("events");

    await click("tour-back");
    await settle();

    expect(router.currentRoute.value.path).toBe("/members");
    expect(card()?.dataset.step).toBe("members");
  });

  it("ignores Next while the next page is still loading", async () => {
    renderOn("/members", "invite", 1000);

    await mountRouted();
    await settle();
    await click("tour-next");
    await settle(100);

    await press("ArrowRight");
    await settle(1000);

    expect(router.currentRoute.value.path).toBe("/members");
    expect(card()?.dataset.step).toBe("members");
  });

  it("centres an optional target's card soon instead of waiting it out", async () => {
    await mountRouted(ROUTED.slice(0, 2));
    await settle();
    await click("tour-next");
    await settle(500);

    expect(router.currentRoute.value.path).toBe("/members");
    expect(card()?.style.visibility).toBe("hidden");

    await settle(600);

    expect(card()?.dataset.step).toBe("members");
    expect(card()?.style.visibility).not.toBe("hidden");
    expect(hole()?.classList).toContain("tour__hole--empty");
  });

  it("does not wait at all for a target on the same page without its slash", async () => {
    await router.push("/members/");
    addTarget("invite");

    await mountRouted([ROUTED[1]]);
    await settle(0);

    expect(card()?.dataset.step).toBe("members");
    expect(hole()?.classList).not.toContain("tour__hole--empty");
  });

  it("ends when the reader leaves a step's page by other means", async () => {
    renderOn("/members", "invite");
    renderOn("/events", "events");

    const wrapper = await mountRouted();
    await settle();
    await click("tour-next");
    await settle();
    await click("tour-next");
    await settle();
    expect(card()?.dataset.step).toBe("events");

    await router.push("/members");
    await settle();

    expect(card()).toBeNull();
    expect(wrapper.emitted("end")).toEqual([["skipped"]]);
  });

  it("ignores Escape while the next page is still loading", async () => {
    renderOn("/members", "invite", 1000);

    const wrapper = await mountRouted();
    await settle();
    await click("tour-next");
    await settle(100);

    await press("Escape");

    expect(wrapper.emitted("end")).toBeUndefined();

    await settle(1000);
    expect(card()?.dataset.step).toBe("members");
  });

  it("gives the focus back to Next after the page changes", async () => {
    renderOn("/members", "invite", 300);

    await mountRouted();
    await settle();
    document.querySelector<HTMLElement>("[data-test='tour-next']")?.focus();

    await click("tour-next");
    await settle(500);

    expect(card()?.dataset.step).toBe("members");
    expect((document.activeElement as HTMLElement | null)?.dataset.test).toBe(
      "tour-next",
    );
  });
});
