import mountVM from "~/test/javascript/unit/mount";
import AppFooter from "@/frontend/core/components/AppFooter/index.vue";

describe("AppFooter", () => {
  it("renders all links", () => {
    const cmp = mountVM(AppFooter);
    expect(cmp.findAll("a")).toHaveLength(6);
  });
});
