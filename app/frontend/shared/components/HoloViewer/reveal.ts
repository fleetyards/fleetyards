// A value eased towards its target a frame at a time: a layer fading in, a
// door opening. `apply` gets the eased value.
export type Tween = {
  value: number;
  target: number;
  perSecond: number;
  apply: (eased: number) => void;
};

export const ease = (value: number) => value * value * (3 - 2 * value);

export const prefersReducedMotion = () =>
  typeof window !== "undefined" &&
  !!window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

// Whether it moved. Capped: drawing on demand, the first frame after a pause
// reports the whole pause as its delta, and the tween would end in one step.
export const stepTween = (tween: Tween, delta: number) => {
  if (tween.value === tween.target) return false;

  const step = Math.min(delta, 1 / 30) * tween.perSecond;
  tween.value =
    tween.target > tween.value
      ? Math.min(tween.target, tween.value + step)
      : Math.max(tween.target, tween.value - step);
  tween.apply(ease(tween.value));

  return true;
};

// Jumps straight to the target where motion is unwanted.
export const retarget = (tween: Tween, target: number) => {
  tween.target = target;

  if (prefersReducedMotion()) {
    tween.value = target;
    tween.apply(ease(target));
  }
};
