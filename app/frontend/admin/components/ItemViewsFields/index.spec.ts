import { describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { type ItemMedia } from "@/services/fyAdminApi";
import ItemViewsFields from "./index.vue";

// The upload field pulls three.js in through its preset picker, which the test
// environment cannot load.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: {
    name: "FormFileInput",
    props: ["name", "file", "allowedTypes"],
    template:
      "<div class='file-input' :data-name='name' :data-types='allowedTypes' :data-url='file?.url' />",
  },
}));

const mountFields = (media?: ItemMedia) =>
  mount(ItemViewsFields, { props: { media } });

const inputs = (wrapper: ReturnType<typeof mountFields>) =>
  wrapper.findAll(".file-input");

describe("ItemViewsFields", () => {
  it("offers the holo and the eight views", () => {
    const wrapper = mountFields();

    expect(
      inputs(wrapper).map((input) => input.attributes("data-name")),
    ).toEqual([
      "holo",
      "topView",
      "portView",
      "frontView",
      "angledView",
      "angledRearView",
      "bottomView",
      "rearView",
      "starboardView",
    ]);
  });

  it("takes a holo file for the holo and images for the views", () => {
    const [holo, ...views] = inputs(mountFields());

    expect(holo.attributes("data-types")).toBe("holo");
    expect(
      views.every((view) => view.attributes("data-types") === "image"),
    ).toBe(true);
  });

  it("shows what each field already holds", () => {
    const wrapper = mountFields({
      rearView: { url: "https://example.test/rear.png" },
    } as ItemMedia);

    expect(wrapper.find("[data-name='rearView']").attributes("data-url")).toBe(
      "https://example.test/rear.png",
    );
  });
});
