import { describe, expect, it } from "vitest";
import {
  HangarPlanCcuIntoEnum,
  HangarPlanCcuOutOfEnum,
  type HangarPlanModel,
  HangarPlanUpgradeSourceEnum,
} from "@/services/fyApi";
import { type ChainContext, reattach, spliceHeld, tailOf } from "./chain";

type Step = {
  sourceKind: HangarPlanUpgradeSourceEnum;
  toModelId: string | null;
  heldFrom?: string;
  restarted?: boolean;
};

const prices: Record<string, number> = {
  Aurora: 25,
  Avenger: 50,
  Cutlass: 110,
  Freelancer: 125,
  Taurus: 175,
  Mole: 315,
  Merchantman: 650,
  Carrack: 600,
};

const model = (name: string): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  pledgePrice: prices[name],
  ccuInto: HangarPlanCcuIntoEnum.ON_SALE,
  ccuOutOf: HangarPlanCcuOutOfEnum.KNOWN,
});

const store = (toModelId: string): Step => ({
  sourceKind: HangarPlanUpgradeSourceEnum.STORE,
  toModelId,
});

const owned = (from: string, to: string): Step => ({
  sourceKind: HangarPlanUpgradeSourceEnum.OWNED_CCU,
  toModelId: to,
  heldFrom: from,
});

const ctx: ChainContext<Step> = {
  model: (id) => (id in prices ? model(id) : undefined),
  heldFrom: (step) => step.heldFrom,
  storeStep: store,
  restart: (step) => ({ ...step, restarted: true }),
};

const held = (from: string, to: string) => ({
  step: owned(from, to),
  from,
  to,
});

const route = (steps: Step[]) =>
  steps.map((step) => `${step.sourceKind}:${step.toModelId}`);

describe("Hangar/Planner/chain", () => {
  describe("spliceHeld", () => {
    it("puts a CCU starting on the route's start first, keeping the rest", () => {
      const steps = [store("Cutlass"), store("Mole")];

      const spliced = spliceHeld(
        "Aurora",
        steps,
        held("Aurora", "Avenger"),
        "Mole",
        ctx,
      );

      expect(route(spliced!)).toEqual([
        "owned_ccu:Avenger",
        "store:Cutlass",
        "store:Mole",
      ]);
      expect(spliced![1].restarted).toBe(true);
      expect(spliced![2]).toBe(steps[1]);
    });

    it("bridges to a CCU in the middle with a store upgrade only when needed", () => {
      const steps = [store("Cutlass"), store("Merchantman")];

      expect(
        route(
          spliceHeld(
            "Aurora",
            steps,
            held("Cutlass", "Taurus"),
            "Merchantman",
            ctx,
          )!,
        ),
      ).toEqual(["store:Cutlass", "owned_ccu:Taurus", "store:Merchantman"]);

      expect(
        route(
          spliceHeld(
            "Aurora",
            steps,
            held("Freelancer", "Taurus"),
            "Merchantman",
            ctx,
          )!,
        ),
      ).toEqual([
        "store:Cutlass",
        "store:Freelancer",
        "owned_ccu:Taurus",
        "store:Merchantman",
      ]);
    });

    it("ends a route on a CCU into the target, dropping the steps it replaces", () => {
      const steps = [store("Cutlass"), store("Taurus"), store("Merchantman")];

      expect(
        route(
          spliceHeld(
            "Aurora",
            steps,
            held("Taurus", "Merchantman"),
            "Merchantman",
            ctx,
          )!,
        ),
      ).toEqual(["store:Cutlass", "store:Taurus", "owned_ccu:Merchantman"]);
    });

    it("replaces the store steps a CCU spans", () => {
      const steps = [
        store("Avenger"),
        store("Cutlass"),
        store("Freelancer"),
        store("Mole"),
      ];

      expect(
        route(
          spliceHeld("Aurora", steps, held("Avenger", "Taurus"), "Mole", ctx)!,
        ),
      ).toEqual(["store:Avenger", "owned_ccu:Taurus", "store:Mole"]);
    });

    it("keeps a later held upgrade, bridging to where it starts", () => {
      const steps = [store("Mole"), owned("Mole", "Merchantman")];

      expect(
        route(
          spliceHeld(
            "Cutlass",
            steps,
            held("Cutlass", "Taurus"),
            "Merchantman",
            ctx,
          )!,
        ),
      ).toEqual(["owned_ccu:Taurus", "store:Mole", "owned_ccu:Merchantman"]);
    });

    it("offers nothing for a CCU past the target or before the start", () => {
      const steps = [store("Mole")];

      expect(
        spliceHeld("Cutlass", steps, held("Mole", "Merchantman"), "Mole", ctx),
      ).toBeUndefined();
      expect(
        spliceHeld("Cutlass", steps, held("Aurora", "Avenger"), "Mole", ctx),
      ).toBeUndefined();
    });
  });

  describe("reattach", () => {
    it("keeps the steps after a changed one that still connect", () => {
      const steps = [store("Cutlass"), store("Taurus"), store("Mole")];

      expect(
        route(reattach("Freelancer", tailOf("Aurora", steps, 1), ctx)),
      ).toEqual(["store:Taurus", "store:Mole"]);
    });

    it("passes over steps the new end has gone beyond", () => {
      const steps = [store("Cutlass"), store("Taurus"), store("Merchantman")];

      expect(route(reattach("Mole", tailOf("Aurora", steps, 1), ctx))).toEqual([
        "store:Merchantman",
      ]);
    });

    it("stops the route when nothing can follow", () => {
      const steps = [store("Cutlass"), store("Taurus")];

      expect(reattach("Taurus", tailOf("Aurora", steps, 1), ctx)).toEqual([]);
    });
  });
});
