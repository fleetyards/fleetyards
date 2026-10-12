import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { type Model, ModelProductionStatusEnum } from "@/services/fyApi";

const model = (overrides: Partial<Model> = {}): Model =>
  ({
    id: "model-1",
    name: "Ironclad",
    slug: "ironclad",
    media: {},
    metrics: { length: 123, cargo: 1440 },
    speeds: { scmSpeed: 115, maxSpeed: 1050 },
    crew: { value: 4, label: "2 - 6" },
    productionStatus: ModelProductionStatusEnum.FLIGHT_READY,
    ...overrides,
  }) as Model;

const labels = async (props: { model: Model }) => {
  const wrapper = await mountWithDefaults(Component, { props });

  return wrapper.findAll("dt").map((term) => term.text());
};

describe("VehicleOverviewSpecs", () => {
  it("shows the ship's status where the top speed used to be", async () => {
    const terms = await labels({ model: model() });

    expect(terms).toContain("Status");
    expect(terms).not.toContain("Max Speed");
  });

  it("leaves out a figure the model has no value for", async () => {
    const terms = await labels({
      model: model({ productionStatus: undefined }),
    });

    expect(terms).not.toContain("Status");
  });
});
