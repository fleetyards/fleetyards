import type { ComputedRef, InjectionKey } from "vue";
import type { BtnSizesEnum } from "@/shared/components/base/Btn/types";

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
};

export const BTN_CONTAINER: InjectionKey<BtnContainerContext> =
  Symbol("btnContainer");
