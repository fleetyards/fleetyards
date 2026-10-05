import { describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import type { FeatureActor } from "@/services/fyAdminApi";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import ActorList from "./index.vue";

const actor = (name: string, fid: string | null = null): FeatureActor => ({
  type: fid ? "Fleet" : "User",
  id: `id-${name}`,
  name,
  fid,
});

const mountList = (actors: FeatureActor[]) =>
  mount(ActorList, {
    props: {
      actors,
      name: "fleets",
      filterLabel: "filter",
      emptyText: "empty",
    },
    global: {
      stubs: {
        FormInput: {
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template:
            "<input :value='modelValue' @input=\"$emit('update:modelValue', $event.target.value)\" />",
        },
        Btn: {
          emits: ["click"],
          template: "<button @click=\"$emit('click')\"><slot /></button>",
        },
      },
    },
  });

const names = (wrapper: ReturnType<typeof mountList>) =>
  wrapper
    .findAll('[data-test="feature-actor-row"]')
    .map((row) => row.find(".feature-actor-name").text());

describe("FeatureActorList", () => {
  it("lists the actors by name", () => {
    const wrapper = mountList([actor("Zulu"), actor("alpha"), actor("Mike")]);

    expect(names(wrapper)).toEqual(["alpha", "Mike", "Zulu"]);
  });

  // Several fleets share a name; the SID is what tells them apart.
  it("filters fleets by SID as well as by name", async () => {
    const wrapper = mountList([
      actor("Test", "Test100"),
      actor("Test", "OTHER"),
      actor("Woot", "test_id"),
    ]);

    await wrapper.find("input").setValue("test1");

    expect(
      wrapper.findAll(".feature-actor-fid").map((el) => el.text()),
    ).toEqual(["Test100"]);
  });

  it("shows a page at a time and offers the rest", async () => {
    const wrapper = mountList(
      Array.from({ length: 60 }, (_, index) =>
        actor(`user${String(index).padStart(2, "0")}`),
      ),
    );

    expect(names(wrapper)).toHaveLength(50);

    await wrapper.find('[data-test="feature-actors-more"]').trigger("click");

    expect(names(wrapper)).toHaveLength(60);
    expect(wrapper.find('[data-test="feature-actors-more"]').exists()).toBe(
      false,
    );
  });

  it("hands the actor up to be removed", async () => {
    const wrapper = mountList([actor("alpha")]);

    await wrapper.find('[data-test="feature-actor-remove"]').trigger("click");

    expect(wrapper.emitted("remove")?.[0]).toEqual([actor("alpha")]);
  });

  it("says when nothing is enabled", () => {
    const wrapper = mountList([]);

    expect(wrapper.text()).toContain("empty");
    expect(wrapper.find("input").exists()).toBe(false);
  });
});
