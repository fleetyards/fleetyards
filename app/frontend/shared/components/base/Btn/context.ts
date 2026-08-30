import type { ComputedRef, InjectionKey } from "vue";
import type {
  BtnSizesEnum,
  BtnTonesEnum,
} from "@/shared/components/base/Btn/types";

/**
 * Provided by containers that change how a Btn should look inside them, and
 * consumed by Btn itself. This is what keeps the nesting styles in Btn: a
 * container states *that* it contains buttons, and Btn decides what that means.
 * BtnGroup and BtnDropdown therefore never write descendant selectors into
 * Btn's internals.
 *
 * - `group` — segmented control. The container draws the border, radius and
 *   end-caps, so members drop their own chrome entirely.
 * - `menu`  — dropdown list. Members go full-width and left-aligned.
 */
export type BtnContainer = "group" | "menu";

export type BtnContainerContext = {
  container: BtnContainer;
  /** Lets a container set the size once for every member. */
  size: ComputedRef<`${BtnSizesEnum}` | undefined>;
  /** Members share the container's width equally. Passed as context rather than
   *  applied with `> :deep(*)`, so the member still styles itself. */
  block: ComputedRef<boolean>;
  /**
   * A segmented group is a *switch*: one member is chosen, and the container
   * draws a single thumb that slides to it. Members drop their own fill entirely
   * - the thumb is the fill - and take radio semantics, because a mode switch is
   * a choice rather than a row of independent actions. Optional: a `menu`
   * container is not a switch and provides neither this nor `register`.
   */
  segmented?: ComputedRef<boolean>;
  /**
   * Members announce themselves so the container can place its thumb. Reported
   * rather than measured: the group would otherwise have to reach into the DOM
   * for a member's index and active state, which is the coupling this context
   * exists to avoid. Registration order is mount order, which is DOM order.
   *
   * The tone comes along because a member has no cap of its own to show it in,
   * so the thumb shows it instead - which means the container has to know the
   * tone of the member it is currently parked on. `neutral` reads as no
   * opinion, leaving whatever the container itself was given.
   */
  register?: (
    active: () => boolean,
    tone: () => `${BtnTonesEnum}`,
  ) => {
    unregister: () => void;
  };
};

export const BTN_CONTAINER: InjectionKey<BtnContainerContext> =
  Symbol("btnContainer");
