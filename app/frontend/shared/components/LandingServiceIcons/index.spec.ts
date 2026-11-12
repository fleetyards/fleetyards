import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import LandingServiceIcons from "./index.vue";

const services = [
  { key: "repair" as const, label: "Repair", url: "/repair.svg" },
  { key: "rearm" as const, label: "Rearm" },
];

const mountIcons = (withLabels = false) =>
  mount(LandingServiceIcons, {
    props: { services, withLabels },
    global: { directives: { Tooltip: {} } },
  });

describe("LandingServiceIcons", () => {
  it("shows the icon alone, named by its alt text", () => {
    const repair = mountIcons().get('[data-test="landing-service-repair"]');

    expect(repair.get("img").attributes("alt")).toBe("Repair");
    expect(repair.text()).toBe("");
  });

  it("names a service that has no icon", () => {
    expect(mountIcons().get('[data-test="landing-service-rearm"]').text()).toBe(
      "Rearm",
    );
  });

  it("puts the name beside the icon when asked", () => {
    expect(
      mountIcons(true).get('[data-test="landing-service-repair"]').text(),
    ).toBe("Repair");
  });
});
