import { reaches } from "@/frontend/components/Hangar/Planner/reach";
import {
  type HangarPlanModel,
  HangarPlanUpgradeSourceEnum,
} from "@/services/fyApi";

export type ChainStep = {
  sourceKind: HangarPlanUpgradeSourceEnum;
  toModelId: string | null;
};

export type ChainContext<S extends ChainStep> = {
  model: (id: string) => HangarPlanModel | undefined;
  // The ship a held upgrade starts from, which is fixed by the upgrade itself.
  heldFrom: (step: S) => string | null | undefined;
  storeStep: (toModelId: string) => S;
  // A store upgrade that now starts elsewhere costs a different amount, so a
  // price entered for its old start no longer applies.
  restart: (step: S) => S;
};

type TailEntry<S> = { step: S; from: string | null };

const isStore = (step: ChainStep) =>
  step.sourceKind === HangarPlanUpgradeSourceEnum.STORE;

// A store upgrade can lead from one ship to another. Ships we hold no data for
// are given the benefit of the doubt.
export const storeLeads = <S extends ChainStep>(
  ctx: ChainContext<S>,
  from: string | null | undefined,
  to: string | null | undefined,
) => {
  if (!from || !to || from === to) return false;

  const fromModel = ctx.model(from);
  const toModel = ctx.model(to);
  if (!fromModel || !toModel) return true;

  return reaches(fromModel, toModel);
};

// Where each step of a chain starts: the route's start, then wherever the step
// before it ends.
export const chainStarts = <S extends ChainStep>(start: string, steps: S[]) =>
  steps.map((_, index) => (index === 0 ? start : steps[index - 1].toModelId));

export const tailOf = <S extends ChainStep>(
  start: string,
  steps: S[],
  index: number,
): TailEntry<S>[] => {
  const starts = chainStarts(start, steps);

  return steps
    .slice(index)
    .map((step, offset) => ({ step, from: starts[index + offset] }));
};

// What is left of a route's later steps once the step before them ends on
// another ship. The first step that can still follow keeps it and everything
// after it: one that starts there anyway, a store upgrade to a dearer ship, or
// a held upgrade a store upgrade can bridge to. Steps before it are passed over,
// and with none that can follow, or once the route has reached its target, the
// route stops here.
export const reattach = <S extends ChainStep>(
  end: string,
  tail: TailEntry<S>[],
  ctx: ChainContext<S>,
  target?: string,
): S[] => {
  if (end === target) return [];

  for (let index = 0; index < tail.length; index++) {
    const { step, from } = tail[index];
    const rest = tail.slice(index + 1).map((entry) => entry.step);

    if (!step.toModelId) continue;

    if (isStore(step)) {
      if (from === end) return [step, ...rest];
      if (storeLeads(ctx, end, step.toModelId)) {
        return [ctx.restart(step), ...rest];
      }
      continue;
    }

    const heldStart = ctx.heldFrom(step) ?? from;
    if (heldStart === end) return [step, ...rest];
    if (heldStart && storeLeads(ctx, end, heldStart)) {
      return [ctx.storeStep(heldStart), step, ...rest];
    }
  }

  return [];
};

export type HeldUpgrade<S> = { step: S; from: string; to: string };

// A held upgrade goes in after the last stop it can follow, with a store
// upgrade in front of it when that stop is not the ship it starts from. The
// store steps it passes over make way for it, and a store upgrade finishes a
// route that would otherwise stop short of the target. Undefined when the route
// has no stop it can follow, when it leads somewhere the target cannot be
// reached from, or when it would drop a held upgrade or a stop still being
// picked.
export const spliceHeld = <S extends ChainStep>(
  start: string,
  steps: S[],
  held: HeldUpgrade<S>,
  target: string,
  ctx: ChainContext<S>,
): S[] | undefined => {
  if (held.to !== target && !storeLeads(ctx, held.to, target)) return undefined;

  const pendingStop = steps.findIndex((step) => !step.toModelId);
  if (
    pendingStop >= 0 &&
    steps.slice(pendingStop + 1).some((step) => !!step.toModelId)
  ) {
    return undefined;
  }

  const stops = [start, ...steps.map((step) => step.toModelId)];
  let after = -1;
  for (let index = 0; index < stops.length; index++) {
    const stop = stops[index];
    if (!stop) break;
    if (stop === held.from || storeLeads(ctx, stop, held.from)) after = index;
  }
  if (after < 0) return undefined;

  const bridge = stops[after] === held.from ? [] : [ctx.storeStep(held.from)];

  const spliced = [
    ...steps.slice(0, after),
    ...bridge,
    held.step,
    ...reattach(held.to, tailOf(start, steps, after), ctx, target),
  ];

  const dropsHeld = steps.some(
    (step) => !isStore(step) && step.toModelId && !spliced.includes(step),
  );
  if (dropsHeld) return undefined;

  const end = spliced[spliced.length - 1].toModelId;
  if (end === target) return spliced;
  if (!storeLeads(ctx, end, target)) return undefined;

  return [...spliced, ctx.storeStep(target)];
};
