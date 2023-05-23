import Panel from "@/frontend/core/components/Panel/index.vue";
import mountVM from "~/test/javascript/unit/mount";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";

const model = {
  name: "Enterprise",
  slug: "enterprise",
  media: {
    storeImage: {
      source: "TestImage",
      small: "TestImage",
      medium: "TestImage",
      large: "TestImage",
    },
  },
  manufacturer: {
    id: "1",
    code: "FED",
    name: "Utopia Planitia",
  },
  shipRole: {
    name: "Exporation Cruiser",
  },
};

describe("ShipPanel", () => {
  let cmp;

  beforeEach(() => {
    cmp = mountVM(ModelPanel, { model });
  });

  it("renders ship panel", () => {
    const panel = cmp.findComponent(Panel);
    expect(panel.exists()).toBe(true);
  });

  it("renders heading with ship name and manufacturer", () => {
    expect(cmp.vm.$el.querySelector("h2").textContent).toContain(model.name);
    expect(cmp.vm.$el.querySelector("h2").textContent).toContain(
      model.manufacturer.name
    );
  });
});
