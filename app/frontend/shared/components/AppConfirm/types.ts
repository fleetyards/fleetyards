/*
 * A confirm's own vocabulary, deliberately smaller than the panel's. Neutral is
 * the default, so colour is spent only where it means something rather than
 * becoming the wallpaper of every confirmation.
 */
export enum AppConfirmTonesEnum {
  NEUTRAL = "neutral",
  // Nothing is destroyed, but it cannot simply be repeated - a long import, a
  // sync that touches remote state.
  WARNING = "warning",
  // Something goes away and does not come back.
  DANGER = "danger",
}

export type AppConfirmOptions = {
  text?: string;
  onConfirm?: () => void | Promise<unknown>;
  onClose?: () => void | Promise<unknown>;
  confirmText?: string;
  cancelText?: string;
  tone?: `${AppConfirmTonesEnum}`;
};
