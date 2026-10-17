import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { LoadoutSocketGroup } from "@/frontend/components/Loadout/Socket/types";

const GROUPS: LoadoutSocketGroup[] = [
  {
    key: "nose",
    label: "Nose",
    slots: [{ id: "nose-1", label: "Nose" }],
  },
  {
    key: "wings",
    label: "Wings",
    slots: [
      { id: "wing-left", label: "Left wing" },
      { id: "wing-right", label: "Right wing" },
    ],
  },
];

const mount = (
  props: { groups: LoadoutSocketGroup[]; active?: string; editable?: boolean },
  attachTo?: Element,
) => mountWithDefaults(Component, { props, attachTo });

describe("LoadoutSocketBoard", () => {
  it("lists every socket under its group's heading", async () => {
    const wrapper = await mount({ groups: GROUPS });

    expect(
      wrapper
        .findAll(".loadout-socket-board__heading")
        .map((heading) => heading.text()),
    ).toEqual(["Nose", "Wings"]);
    expect(
      wrapper
        .get("[data-test='loadout-socket-group-wings']")
        .findAll(".loadout-socket"),
    ).toHaveLength(2);
  });

  it("leaves out a heading the group does not have", async () => {
    const wrapper = await mount({
      groups: [{ key: "all", slots: [{ id: "only", label: "Module slot" }] }],
    });

    expect(wrapper.find(".loadout-socket-board__heading").exists()).toBe(false);
  });

  it("makes a socket the active one when it is picked", async () => {
    const wrapper = await mount({ groups: GROUPS, editable: true });

    await wrapper
      .get("[data-test='loadout-socket-wing-right']")
      .trigger("click");

    expect(wrapper.emitted("update:active")).toEqual([["wing-right"]]);
  });

  it("marks only the active socket, and none while read-only", async () => {
    const editable = await mount({
      groups: GROUPS,
      active: "wing-left",
      editable: true,
    });

    expect(
      editable
        .findAll(".loadout-socket--active")
        .map((socket) => socket.attributes("data-test")),
    ).toEqual(["loadout-socket-wing-left"]);

    const readOnly = await mount({ groups: GROUPS, active: "wing-left" });

    expect(readOnly.find(".loadout-socket--active").exists()).toBe(false);
  });

  it("renders the caller's panel under the active socket only", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { groups: GROUPS, active: "wing-left", editable: true },
      slots: { active: () => [h("p", { "data-test": "panel" }, "picker")] },
    });

    const panels = wrapper.findAll("[data-test='loadout-socket-board-active']");
    expect(panels).toHaveLength(1);
    expect(
      panels[0].element.previousElementSibling
        ?.querySelector(".loadout-socket")
        ?.getAttribute("data-test"),
    ).toBe("loadout-socket-wing-left");
  });

  it("walks the sockets with the arrow keys, across groups", async () => {
    const host = document.createElement("div");
    document.body.appendChild(host);
    const wrapper = await mount({ groups: GROUPS, editable: true }, host);

    const nose = wrapper.get<HTMLButtonElement>(
      "[data-test='loadout-socket-nose-1']",
    );
    nose.element.focus();
    await nose.trigger("keydown", { key: "ArrowDown" });

    expect(document.activeElement?.getAttribute("data-test")).toBe(
      "loadout-socket-wing-left",
    );

    await wrapper
      .get("[data-test='loadout-socket-wing-left']")
      .trigger("keydown", { key: "ArrowUp" });

    expect(document.activeElement?.getAttribute("data-test")).toBe(
      "loadout-socket-nose-1",
    );

    wrapper.unmount();
    host.remove();
  });
});
