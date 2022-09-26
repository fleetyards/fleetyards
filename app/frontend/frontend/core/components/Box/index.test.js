import { mount } from "@vue/test-utils";
import sanityTest from "~/test/javascript/unit/sanityTest";
import Box from "@/frontend/core/components/Box/index.vue";

sanityTest(Box);

describe("Box", () => {
  let cmp;
  beforeEach(() => {
    cmp = mount(Box);
  });

  it("renders", () => {
    expect(cmp.vm.$el.className).toBe("box");
  });

  it("renders large box", async () => {
    cmp.setProps({ large: true });
    await cmp.vm.$nextTick();
    expect(cmp.vm.$el.className).toBe("box box-large");
  });
});
