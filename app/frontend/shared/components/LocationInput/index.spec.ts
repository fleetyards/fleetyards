import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { locations } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  locations: vi.fn(async () => ({
    items: [
      {
        id: "lorville",
        name: "Lorville",
        slug: "lorville",
        parent: { name: "Hurston" },
      },
    ],
  })),
}));

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/locations/:slug",
        name: "location",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "home" });
  await instance.isReady();

  return instance;
};

describe("LocationInput", () => {
  it("links the place a suggestion names, and drops the link when retyped", async () => {
    vi.useFakeTimers();

    const wrapper = await mountWithDefaults(Component, {
      props: { name: "location", modelValue: "", locationId: null },
      plugins: [await router()],
    });

    await wrapper.find("input").setValue("Lorv");
    await vi.advanceTimersByTimeAsync(300);
    await flushPromises();

    const suggestion = wrapper.find(".location-input__suggestion");
    expect(suggestion.text()).toContain("Lorville");

    await suggestion.trigger("mousedown");

    expect(wrapper.emitted("update:locationId")?.at(-1)).toEqual(["lorville"]);
    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual(["Lorville"]);

    await wrapper.setProps({ modelValue: "Lorville", locationId: "lorville" });
    await wrapper.find("input").setValue("Lorville, Teasa");

    expect(wrapper.emitted("update:locationId")?.at(-1)).toEqual([null]);

    vi.useRealTimers();
  });

  it("ignores an older search that answers after a newer one", async () => {
    vi.useFakeTimers();

    const place = (name: string) => ({
      items: [{ id: name, name, slug: name.toLowerCase(), parent: null }],
    });
    const slow: ((value: unknown) => void)[] = [];
    const answerSlow = (value: unknown) =>
      slow.forEach((resolve) => resolve(value));

    vi.mocked(locations).mockImplementation(((params?: {
      q?: { nameCont?: string; nameStart?: string };
    }) => {
      const text = params?.q?.nameCont ?? params?.q?.nameStart;

      if (text === "Lor") {
        return new Promise((resolve) => {
          slow.push(resolve);
        });
      }

      return Promise.resolve(place("Levski"));
    }) as never);

    const wrapper = await mountWithDefaults(Component, {
      props: { name: "location", modelValue: "", locationId: null },
      plugins: [await router()],
    });

    await wrapper.find("input").setValue("Lor");
    await vi.advanceTimersByTimeAsync(300);
    await wrapper.find("input").setValue("Lev");
    await vi.advanceTimersByTimeAsync(300);
    await flushPromises();

    answerSlow(place("Lorville"));
    await flushPromises();

    expect(wrapper.find(".location-input__suggestion").text()).toContain(
      "Levski",
    );

    vi.useRealTimers();
  });

  it("puts a place whose name starts with the text first", async () => {
    vi.useFakeTimers();

    vi.mocked(locations).mockImplementation((async (params?: {
      q?: { nameStart?: string };
    }) =>
      params?.q?.nameStart
        ? {
            items: [
              { id: "tressler", name: "Port Tressler", slug: "tressler" },
            ],
          }
        : {
            items: [
              { id: "hub", name: "Lazarus Transport Hub", slug: "hub" },
              { id: "tressler", name: "Port Tressler", slug: "tressler" },
            ],
          }) as never);

    const wrapper = await mountWithDefaults(Component, {
      props: { name: "location", modelValue: "", locationId: null },
      plugins: [await router()],
    });

    await wrapper.find("input").setValue("Port");
    await vi.advanceTimersByTimeAsync(300);
    await flushPromises();

    expect(
      wrapper.findAll(".location-input__suggestion").map((node) => node.text()),
    ).toEqual(["Port Tressler", "Lazarus Transport Hub"]);

    vi.useRealTimers();
  });
});
