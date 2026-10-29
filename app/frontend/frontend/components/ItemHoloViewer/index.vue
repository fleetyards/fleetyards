<script lang="ts">
export default {
  name: "ItemHoloViewer",
};
</script>

<script lang="ts" setup>
import { type ItemMedia } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { type RouterLinkProps } from "vue-router";

type Props = {
  name: string;
  media?: ItemMedia | null;
  backRoute: RouterLinkProps["to"];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const route = useRoute();

const router = useRouter();

const comlink = useComlink();

// The full screen viewer of the item page, as a page of its own the way the
// ship viewer is, so it can be linked to; `?textured=1` opens the textured
// holo the item page was showing.
onMounted(() => {
  if (!props.media?.holo?.url) {
    void router.replace(props.backRoute);
    return;
  }

  updateMetaInfo({ title: t("title.itemViewer", { name: props.name }) });

  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/ItemHoloModal/index.vue"),
    fullscreen: true,
    props: {
      media: props.media,
      textured: route.query.textured === "1",
      backRoute: props.backRoute,
    },
  });
});
</script>
