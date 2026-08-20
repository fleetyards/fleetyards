export const useReducedMotion = () => {
  const query = window.matchMedia("(prefers-reduced-motion: reduce)");

  const prefersReducedMotion = ref(query.matches);

  const update = (event: MediaQueryListEvent) => {
    prefersReducedMotion.value = event.matches;
  };

  onMounted(() => {
    query.addEventListener("change", update);
  });

  onBeforeUnmount(() => {
    query.removeEventListener("change", update);
  });

  return { prefersReducedMotion };
};
