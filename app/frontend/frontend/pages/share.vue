<script lang="ts">
export default {
  name: "SharePage",
};
</script>

<script lang="ts" setup>
import type { LocationQueryValue, RouteLocationRaw } from "vue-router";
import Loader from "@/shared/components/Loader/index.vue";
import { resolveSharedLink } from "@/frontend/utils/sharedLink";

const route = useRoute();

const router = useRouter();

const single = (
  value: LocationQueryValue | LocationQueryValue[] | undefined,
): string | undefined => (Array.isArray(value) ? value[0] : value) ?? undefined;

// The page Android opens with whatever was shared into the installed app. It
// shows nothing of its own and is replaced in history by where the share leads.
onMounted(async () => {
  const target = resolveSharedLink(
    {
      title: single(route.query.title),
      text: single(route.query.text),
      url: single(route.query.url),
    },
    {
      frontendEndpoint: window.FRONTEND_ENDPOINT,
      shortDomain: window.SHORT_DOMAIN || undefined,
    },
  );

  switch (target.kind) {
    case "route":
      await router.replace(target.path);
      break;
    case "short":
      window.location.replace(target.href);
      break;
    case "search":
      await router.replace({
        name: "ships",
        query: { searchCont: target.query },
      } as unknown as RouteLocationRaw);
      break;
    default:
      await router.replace({ name: "home" });
  }
});
</script>

<template>
  <Loader loading />
</template>
