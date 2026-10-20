import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeAll, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required, url } from "@vee-validate/rules";
import type { GameEvent } from "@/services/fyAdminApi";
import Component from "./index.vue";

beforeAll(() => {
  defineRule("required", required);
  defineRule("url", url);
});

// The real picker is a calendar widget; the form only cares about the string
// it hands back, which is local time without an offset.
vi.mock("@/shared/components/base/FormDateTime/index.vue", () => ({
  default: {
    name: "FormDateTime",
    props: { modelValue: { type: String, default: null }, name: String },
    emits: ["update:modelValue"],
    render: () => null,
  },
}));

const gameEvent: GameEvent = {
  id: "8d0e3c7a-0000-4000-8000-000000000001",
  title: "Invictus Launch Week",
  category: "ship_combat",
  startsAt: "2026-10-24T18:00:00.000Z",
  published: true,
  createdAt: "2026-10-01T00:00:00Z",
  updatedAt: "2026-10-01T00:00:00Z",
};

// vee-validate settles a submit over several ticks, not one microtask flush.
const submit = async (wrapper: Awaited<ReturnType<typeof mountForm>>) => {
  await wrapper.find("form#game-event-form").trigger("submit");
  await flushPromises();
  await new Promise((resolve) => setTimeout(resolve, 20));
  await flushPromises();
};

const mountForm = (props: { gameEvent?: GameEvent } = {}) =>
  mountWithDefaults(Component, {
    props: { formId: "game-event-form", ...props },
  });

describe("GameEventForm", () => {
  it("submits an existing event as it was loaded", async () => {
    const wrapper = await mountForm({ gameEvent });

    await submit(wrapper);

    expect(wrapper.emitted("submit")?.[0]?.[0]).toMatchObject({
      title: "Invictus Launch Week",
      category: "ship_combat",
      startsAt: "2026-10-24T18:00:00.000Z",
      endsAt: null,
      published: true,
    });
  });

  it("turns the picker's local time into RFC 3339 before submitting", async () => {
    const wrapper = await mountForm({ gameEvent });

    const [startsAt, endsAt] = wrapper.findAllComponents({
      name: "FormDateTime",
    });
    startsAt.vm.$emit("update:modelValue", "2026-11-20T19:30");
    endsAt.vm.$emit("update:modelValue", "2026-12-02T23:00");
    await submit(wrapper);

    expect(wrapper.emitted("submit")?.[0]?.[0]).toMatchObject({
      startsAt: new Date("2026-11-20T19:30").toISOString(),
      endsAt: new Date("2026-12-02T23:00").toISOString(),
    });
  });

  it("does not submit without a title", async () => {
    const wrapper = await mountForm();

    await submit(wrapper);

    expect(wrapper.emitted("submit")).toBeUndefined();
  });
});
