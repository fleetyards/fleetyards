import { useMediaQuery } from "@vueuse/core";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";

// The stop nearest to where the reader let go, if one is close enough to be
// what they were aiming for.
export const settleTarget = (
  scrollY: number,
  stops: number[],
  reach: number,
) => {
  let nearest: number | undefined;

  stops.forEach((stop) => {
    const distance = Math.abs(stop - scrollY);
    if (distance > reach) return;
    if (nearest === undefined || distance < Math.abs(nearest - scrollY)) {
      nearest = stop;
    }
  });

  return nearest;
};

// Starts from rest, as the scroll it follows has just come to one.
const easeInOutSine = (progress: number) =>
  -(Math.cos(Math.PI * progress) - 1) / 2;

// Of the viewport's height: a stop further away than this is not one the
// reader was aiming for.
const REACH = 0.25;

// Waited for after the last scroll event, where the browser has no
// `scrollend`.
const IDLE = 150;

const INTERRUPTIONS = ["wheel", "pointerdown", "keydown", "touchstart"];

// Once scrolling comes to rest near the top of a section, eases the page the
// rest of the way, rather than CSS snapping's abrupt jump whose speed no
// browser lets a page choose. The page top stands in for the first section,
// so the header stays in view, and the page bottom keeps the footer
// reachable. A section taller than the window is no stop, or part of it could
// never be read. Touch screens and readers who asked for reduced motion
// scroll freely.
export const useScrollSettle = (sections: () => Iterable<HTMLElement>) => {
  const { prefersReducedMotion } = useReducedMotion();
  const finePointer = useMediaQuery("(hover: hover) and (pointer: fine)");

  let frame: number | undefined;
  let idle: ReturnType<typeof setTimeout> | undefined;

  const stops = () => {
    const viewport = window.innerHeight;
    const bottom = document.documentElement.scrollHeight - viewport;
    const points = [0, bottom];

    Array.from(sections())
      .slice(1)
      .forEach((section) => {
        const rect = section.getBoundingClientRect();
        if (rect.height > viewport + 1) return;

        points.push(Math.min(rect.top + window.scrollY, bottom));
      });

    return points;
  };

  const stop = () => {
    if (frame === undefined) return;

    window.cancelAnimationFrame(frame);
    frame = undefined;
  };

  const glide = (to: number) => {
    const from = window.scrollY;
    const distance = to - from;
    const duration = Math.min(
      1100,
      Math.max(600, (Math.abs(distance) / window.innerHeight) * 2400),
    );
    let start: number | undefined;

    const step = (now: number) => {
      start ??= now;
      const progress = Math.min(1, (now - start) / duration);

      window.scrollTo({
        top: from + distance * easeInOutSine(progress),
        behavior: "instant",
      });

      frame = progress < 1 ? window.requestAnimationFrame(step) : undefined;
    };

    frame = window.requestAnimationFrame(step);
  };

  const settle = () => {
    if (frame !== undefined) return;
    if (!finePointer.value || prefersReducedMotion.value) return;

    const target = settleTarget(
      window.scrollY,
      stops(),
      window.innerHeight * REACH,
    );

    if (target === undefined || Math.abs(target - window.scrollY) < 2) return;

    glide(target);
  };

  const onScroll = () => {
    clearTimeout(idle);
    idle = setTimeout(settle, IDLE);
  };

  const hasScrollEnd = "onscrollend" in window;

  onMounted(() => {
    if (hasScrollEnd) {
      window.addEventListener("scrollend", settle);
    } else {
      window.addEventListener("scroll", onScroll, { passive: true });
    }

    INTERRUPTIONS.forEach((event) =>
      window.addEventListener(event, stop, { passive: true }),
    );
  });

  onBeforeUnmount(() => {
    window.removeEventListener("scrollend", settle);
    window.removeEventListener("scroll", onScroll);
    INTERRUPTIONS.forEach((event) => window.removeEventListener(event, stop));
    clearTimeout(idle);
    stop();
  });
};
