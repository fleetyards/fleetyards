import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { type Fleet, type FleetSquadron } from "@/services/fyApi";
import Component from "./index.vue";

const items = [
  { id: "c", name: "Rota", slug: "rota", team: true },
  {
    id: "a",
    name: "Alpha",
    slug: "alpha",
    team: false,
    shortDescription: "Interceptors",
  },
] as FleetSquadron[];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetSquadrons: () => ({
      data: ref({ items }),
      isLoading: ref(false),
    }),
  };
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (squadronsEnabled = true) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", squadronsEnabled } as Fleet,
    },
  });

  return wrapper;
};

const select = (subject: VueWrapper) =>
  subject.findComponent({ name: "BaseSelect" });

describe("FleetSquadronSourceSelect", () => {
  it("lists squadrons before teams", async () => {
    const subject = await mount();

    expect(
      (select(subject).props("options") as { label: string }[]).map(
        (option) => option.label,
      ),
    ).toEqual(["Alpha", "Rota"]);
  });

  it("hands the picked squadron over", async () => {
    const subject = await mount();

    select(subject).vm.$emit("update:modelValue", "a");
    await nextTick();

    expect(subject.emitted("update:modelValue")).toEqual([["a"]]);
    expect(subject.emitted("pick")?.[0]?.[0]).toMatchObject({
      name: "Alpha",
      shortDescription: "Interceptors",
    });
  });

  it("hands over the squadron it replaces", async () => {
    wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        fleet: { slug: "maru", squadronsEnabled: true } as Fleet,
        modelValue: "a",
      },
    });

    select(wrapper).vm.$emit("update:modelValue", "c");
    await nextTick();

    expect(wrapper.emitted("pick")?.[0]?.[1]).toMatchObject({ name: "Alpha" });
  });

  it("is not offered while squadrons are off", async () => {
    const subject = await mount(false);

    expect(select(subject).exists()).toBe(false);
  });
});
