<script lang="ts">
export default {
  name: "ItemHoloViewer",
};
</script>

<script lang="ts" setup>
import { type ItemMedia } from "@/services/fyApi";
import { useHoloViewerPage } from "@/frontend/composables/useHoloViewerPage";
import { useI18n } from "@/shared/composables/useI18n";
import { type RouteLocationNamedRaw } from "vue-router";

type Props = {
  name: string;
  media?: ItemMedia | null;
  backRoute: RouteLocationNamedRaw;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

// The full screen viewer of the item page, as a page of its own the way the
// ship viewer is, so it can be linked to; `?textured=1` opens the textured
// holo the item page was showing.
useHoloViewerPage({
  title: () => t("title.itemViewer", { name: props.name }),
  backRoute: () => props.backRoute,
  modal: () =>
    props.media?.holo?.url
      ? {
          component: () =>
            import("@/frontend/components/ItemHoloModal/index.vue"),
          fullscreen: true,
          props: {
            media: props.media,
            textured: route.query.textured === "1",
          },
        }
      : undefined,
});
</script>
