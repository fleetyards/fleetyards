import type { PillVariantsEnum } from "@/shared/components/base/Pill/types";

/**
 * A figure or a state shown at the end of a row. Passed as data rather than
 * filled by a slot so the row can build its own accessible name: the toggle is
 * an overlay covering the whole row, so its label has to carry everything the
 * row shows, and a slot's rendered text is not readable from here.
 *
 * `variant` makes it a Pill; without one it is plain text, which is what a
 * figure like a cargo capacity wants — a pill on every number would tint a row
 * that is only reporting.
 */
export type AddonBadge = {
  key: string;
  label: string;
  variant?: `${PillVariantsEnum}`;
};
