import type { RouteLocationRaw } from "vue-router";
import type { FloatingPlacement } from "@/shared/utils/floatingPlacement";

export interface TourStep {
  id: string;
  title: string;
  text: string;
  // A selector for the control the step explains. Without one -- or when
  // nothing it matches is rendered -- the card is centred over the dimmed page.
  target?: string;
  placement?: FloatingPlacement;
  // Leave the step out entirely when its target is missing, rather than
  // falling back to the centred card. For steps that only make sense pointing
  // at something: a feature flag, the mobile layout or an empty list can each
  // take the control away.
  requiresTarget?: boolean;
  // The page the step lives on. The tour goes there before showing the step --
  // forwards and back -- and waits for the target to render. A step whose
  // required target never appears is passed over. Without one, the step is
  // shown on whatever page the tour is on.
  route?: RouteLocationRaw;
}

export type TourEndReason = "finished" | "skipped";
