<script lang="ts">
export default {
  name: "ShipHoloPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import HoloViewer2 from "@/shared/components/HoloViewer2/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { type Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const metaTitle = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return t("title.shipHolo", {
    name: props.model.name,
  });
});

const metaDescription = computed(() => {
  if (!props.model || !props.model.description) {
    return undefined;
  }

  return props.model.description;
});

const metaImage = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return props.model.media.storeImage?.large;
});

const route = useRoute();

const crumbs = computed(() => {
  if (!props.model) {
    return [];
  }

  return [
    {
      to: {
        name: "ships",
        hash: `#${props.model.slug}`,
      },
      label: t("nav.ships.index"),
    },
    {
      to: { name: "ship", param: { slug: route.params.slug } },
      label: props.model.name,
    },
  ];
});

onMounted(() => {
  updateTitle();
});

watch(
  () => props.model,
  () => updateTitle,
);

const updateTitle = () => {
  if (!props.model) {
    return;
  }

  updateMetaInfo({
    title: metaTitle.value,
    description: metaDescription.value,
    image: metaImage.value,
    type: "article",
  });
};
</script>

<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <BreadCrumbs :crumbs="crumbs" />
          <h1>
            {{ metaTitle }}
          </h1>
        </div>
      </div>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <HoloViewer2 v-if="model.holo" :holo="model.holo" />
    </div>
  </div>
</template>
