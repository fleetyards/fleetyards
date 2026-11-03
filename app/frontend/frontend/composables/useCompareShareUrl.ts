import debounce from "lodash.debounce";
import { compareShare, type CompareShareInput } from "@/services/fyApi";

// The link a compare page shares: a short one once the API has made it, the
// page's own address until then.
//
// Fetched ahead of the click so the share button can hand it to
// navigator.share synchronously -- iOS Safari requires transient user
// activation and rejects share() calls that await first.
export const useCompareShareUrl = (
  kind: keyof CompareShareInput,
  slugs: MaybeRefOrGetter<string[]>,
) => {
  const route = useRoute();

  const longShareUrl = computed(() => {
    const host = `${window.location.protocol}//${window.location.host}`;

    return `${host}${route.fullPath}`;
  });

  const shortShareUrl = ref<string | undefined>();

  const shareKey = computed(() => [...toValue(slugs)].sort().join(","));

  const fetchShortShareUrl = debounce(async (key: string) => {
    try {
      const result = await compareShare({ [kind]: key.split(",") });
      if (key !== shareKey.value) return;
      shortShareUrl.value = result.shortUrl || result.longUrl || undefined;
    } catch (error) {
      if (key !== shareKey.value) return;
      console.info("compareShare failed", error);
      shortShareUrl.value = undefined;
    }
  }, 300);

  watch(
    shareKey,
    (key) => {
      fetchShortShareUrl.cancel();
      shortShareUrl.value = undefined;
      if (!key) return;
      void fetchShortShareUrl(key);
    },
    { immediate: true },
  );

  onBeforeUnmount(() => {
    fetchShortShareUrl.cancel();
  });

  return computed(() => shortShareUrl.value || longShareUrl.value);
};
