import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

/*
 * The card's frame is BasePanel's now, so what is worth asserting is that the
 * fold-in actually happened: that it renders a panel rather than a second card
 * implementation, and that the two things which stayed card-local - the metric
 * title tone and the slim treatment - still reach the right places.
 */
describe("MetricsCard", () => {
  it("renders as a panel rather than its own surface", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Combat" },
    });

    expect(wrapper.find(".panel").exists()).toBe(true);
    expect(wrapper.find(".panel").classes()).toContain("metrics-card");
    // The double frame the redesign removed.
    expect(wrapper.find(".panel-wrapper").exists()).toBe(false);
  });

  it("titles itself with the metric tone", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Combat" },
    });
    const heading = wrapper.find(".panel-heading");

    expect(heading.classes()).toContain("panel-heading--metric");
    expect(heading.text()).toContain("Combat");
    // The e2e specs locate panel titles by this hook.
    expect(wrapper.find("[data-test='panel-heading-title']").exists()).toBe(
      true,
    );
  });

  it("carries no end-caps and a divided head when slim", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Weapons", variant: "slim" },
    });

    expect(wrapper.find(".panel").classes()).toContain("panel--slim");
    expect(wrapper.find(".panel-heading").classes()).toContain(
      "panel-heading--divider",
    );
    expect(wrapper.find(".panel-heading").classes()).toContain(
      "panel-heading--compact",
    );
  });

  it("keeps slotted content in the consumer's scope", async () => {
    // metricsCard.scss styles these classes from the consuming component, so
    // the card must not wrap or rewrite what it is handed.
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Hull" },
      slots: {
        default: () => [h("div", { class: "metrics-card__hero" }, "tiles")],
      },
    });

    expect(wrapper.find(".panel-body > .metrics-card__hero").exists()).toBe(
      true,
    );
  });

  it("runs a loading line under its heading and is busy while loading", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Combat", loading: true },
    });

    expect(wrapper.find(".panel").attributes("aria-busy")).toBe("true");
    const line = wrapper.find(".metrics-card__head .loading-line");
    expect(line.classes()).toContain("loading-line--active");
    expect(line.classes()).toContain("loading-line--bottom");
    expect(wrapper.find("[role='status']").text()).toContain("Combat");
    // The status text must not leak into the title the e2e specs read.
    expect(wrapper.find("[data-test='panel-heading-title']").text()).toBe(
      "Combat",
    );
  });

  it("is idle, and announces nothing, once loaded", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Combat" },
    });

    expect(wrapper.find(".loading-line").classes()).not.toContain(
      "loading-line--active",
    );
    expect(wrapper.find("[role='status']").text()).toBe("");
  });
});
