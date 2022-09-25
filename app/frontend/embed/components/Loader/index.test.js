import { mount } from "@vue/test-utils";
import Loader from "@/embed/components/Loader/index.vue";

describe("Loader", () => {
  it("does not render loader on default", () => {
    const cmp = mount(Loader);
    expect(cmp.find("div").exists()).toBe(false);
  });

  it("renders centered loader", () => {
    const cmp = mount(Loader, { propsData: { loading: true } });
    const mainElement = cmp.find("div");

    expect(mainElement.exists()).toBe(true);
    expect(mainElement.classes("text-center")).toBe(true);
    expect(cmp.find(".loader").exists()).toBe(true);
  });
});
