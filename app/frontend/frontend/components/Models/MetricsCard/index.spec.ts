import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

/*
 * The card's frame is BasePanel's now, so what is worth asserting is that the
 * fold-in actually happened: that it renders a panel rather than a second card
 * implementation, and that the two things which stayed card-local - the metric
 * title tone and the slim treatment - still reach the right places.
 */
describe("MetricsCard", () => {
  it("renders as a panel rather than its own surface", () => {
    const wrapper = mount(Component, { props: { title: "Combat" } });

    expect(wrapper.find(".panel").exists()).toBe(true);
    expect(wrapper.find(".panel").classes()).toContain("metrics-card");
    // The double frame the redesign removed.
    expect(wrapper.find(".panel-wrapper").exists()).toBe(false);
  });

  it("titles itself with the metric tone", () => {
    const wrapper = mount(Component, { props: { title: "Combat" } });
    const heading = wrapper.find(".panel-heading");

    expect(heading.classes()).toContain("panel-heading--metric");
    expect(heading.text()).toContain("Combat");
    // The e2e specs locate panel titles by this hook.
    expect(wrapper.find("[data-test='panel-heading-title']").exists()).toBe(
      true,
    );
  });

  it("carries no end-caps and a divided head when slim", () => {
    const wrapper = mount(Component, {
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

  it("keeps slotted content in the consumer's scope", () => {
    // metricsCard.scss styles these classes from the consuming component, so
    // the card must not wrap or rewrite what it is handed.
    const wrapper = mount(Component, {
      props: { title: "Hull" },
      slots: { default: '<div class="metrics-card__hero">tiles</div>' },
    });

    expect(wrapper.find(".panel-body > .metrics-card__hero").exists()).toBe(
      true,
    );
  });
});
