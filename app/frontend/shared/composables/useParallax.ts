import { useReducedMotion } from "@/shared/composables/useReducedMotion";

// How far a layer is shifted while its section crosses the viewport: zero
// with the section centred, growing as it moves away, scaled by `speed`.
export const parallaxOffset = (
  top: number,
  height: number,
  viewportHeight: number,
  speed: number,
) => (top + height / 2 - viewportHeight / 2) * -speed;

// Writes the offset of `target` into `--parallax-offset` on every scroll
// frame, for a background layer to translate by. Nothing moves for a reader
// who asked for reduced motion.
export const useParallax = (target: Ref<HTMLElement | null>, speed = 0.25) => {
  const { prefersReducedMotion } = useReducedMotion();

  let frame: number | undefined;

  const update = () => {
    frame = undefined;

    const element = target.value;
    if (!element) return;

    if (prefersReducedMotion.value) {
      element.style.removeProperty("--parallax-offset");
      return;
    }

    const rect = element.getBoundingClientRect();

    element.style.setProperty(
      "--parallax-offset",
      `${parallaxOffset(rect.top, rect.height, window.innerHeight, speed)}px`,
    );
  };

  const schedule = () => {
    if (frame === undefined) frame = window.requestAnimationFrame(update);
  };

  onMounted(() => {
    window.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", schedule, { passive: true });
    update();
  });

  onBeforeUnmount(() => {
    window.removeEventListener("scroll", schedule);
    window.removeEventListener("resize", schedule);
    if (frame !== undefined) window.cancelAnimationFrame(frame);
  });

  watch(prefersReducedMotion, update);
};
