import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";

// The current page with the chart open: filters, sort and page live in the
// query, and `fleetchart` opens the chart on mount.
export const useFleetchartShareUrl = () => {
  const route = useRoute();
  const router = useRouter();

  return computed(() => {
    const { href } = router.resolve({
      path: route.path,
      query: { ...route.query, fleetchart: "true" },
    });

    return `${window.location.origin}${href}`;
  });
};
