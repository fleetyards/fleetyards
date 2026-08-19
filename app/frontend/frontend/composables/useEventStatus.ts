import type { FleetEventStatus } from "@/services/fyApi";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

// A past event still sitting in a pre-finished status reads as "past" to the
// viewer rather than misleadingly advertising open signups. Kept here rather
// than in a component because the tone and the label have to agree, and two
// surfaces render them.
type EffectiveStatus = `${FleetEventStatus}` | "past";

const PRE_FINISHED: string[] = ["draft", "open", "locked"];

/*
 * Tone, not a badge colour. The panel redesign put status on the end-cap and
 * left the frame neutral, so an event card carries its lifecycle the same way
 * every other surface in the app does. `highlight` is the gold cap: locked is a
 * held state, not an error.
 */
const TONE_BY_STATUS: Record<string, `${PanelTonesEnum}`> = {
  draft: PanelTonesEnum.NEUTRAL,
  open: PanelTonesEnum.SUCCESS,
  locked: PanelTonesEnum.HIGHLIGHT,
  active: PanelTonesEnum.PRIMARY,
  completed: PanelTonesEnum.NEUTRAL,
  past: PanelTonesEnum.NEUTRAL,
  cancelled: PanelTonesEnum.ERROR,
};

/*
 * A pill's palette is narrower than the cap's: its default fill is the primary
 * blue, which suits a live event, so the quiet states ask for `neutral` and the
 * gold held state maps to `warning`. Kept beside the tone map because a badge
 * and the cap above it must not disagree about what the event is doing.
 */
const PILL_VARIANT_BY_STATUS: Record<string, `${PillVariantsEnum}`> = {
  draft: PillVariantsEnum.NEUTRAL,
  open: PillVariantsEnum.SUCCESS,
  locked: PillVariantsEnum.WARNING,
  active: PillVariantsEnum.DEFAULT,
  completed: PillVariantsEnum.NEUTRAL,
  past: PillVariantsEnum.NEUTRAL,
  cancelled: PillVariantsEnum.DANGER,
};

export const useEventStatus = () => {
  const effectiveStatus = (
    status: FleetEventStatus,
    past?: boolean,
  ): EffectiveStatus =>
    past && PRE_FINISHED.includes(status) ? "past" : status;

  const toneFor = (status: FleetEventStatus, past?: boolean) =>
    TONE_BY_STATUS[effectiveStatus(status, past)] ?? PanelTonesEnum.NEUTRAL;

  const labelKeyFor = (status: FleetEventStatus, past?: boolean) =>
    `labels.fleets.events.statuses.${effectiveStatus(status, past)}`;

  const pillVariantFor = (status: FleetEventStatus, past?: boolean) =>
    PILL_VARIANT_BY_STATUS[effectiveStatus(status, past)] ??
    PillVariantsEnum.NEUTRAL;

  return { effectiveStatus, toneFor, labelKeyFor, pillVariantFor };
};
