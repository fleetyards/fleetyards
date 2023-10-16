<template>
  <div>
    <Panel
      v-if="model"
      :id="model.slug"
      class="model-panel"
      :class="`model-panel-${model.slug}`"
    >
      <PanelHeading level="h2">
        <template #default>
          <router-link
            :to="{
              name: 'model',
              params: {
                slug: model.slug,
              },
            }"
          >
            <span>{{ model.name }}</span>
          </router-link>
        </template>
        <template #subtitle>
          <router-link :to="manufacturerRoute">
            {{ manufacturerName }}
          </router-link>
        </template>
        <template #actions>
          <AddToHangar
            :model="model"
            class="panel-add-to-hangar-button"
            variant="panel"
          />
        </template>
      </PanelHeading>
      <PanelImage
        :rounded="details ? undefined : 'bottom'"
        :image="storeImage"
        :alt="model.name"
        :to="{ name: 'model', params: { slug: model.slug } }"
      >
        <div
          v-show="model.onSale"
          v-tooltip="t('labels.model.onSale')"
          class="on-sale"
        >
          <i class="fal fa-dollar-sign" />
        </div>
      </PanelImage>
      <Collapsed
        :key="`details-${model.slug}-${uuid}-wrapper`"
        :visible="details"
      >
        <div class="production-status">
          <strong class="text-uppercase">
            <template v-if="model.productionStatus">
              {{ t(`labels.model.productionStatus.${model.productionStatus}`) }}
            </template>
            <template v-else>
              {{ t(`labels.not-available`) }}
            </template>
          </strong>
        </div>
        <ModelPanelMetrics :model="model" />
      </Collapsed>
    </Panel>
  </div>
</template>

<script lang="ts" setup>
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import { Model } from "@/services/fyApi";

type Props = {
  model: Model;
  details?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
});

const { t } = useI18n();

const uuid = ref<string>(uuidv4());

const storeImage = computed(() => props.model.media.storeImage?.medium);

onMounted(() => {
  uuid.value = uuidv4();
});

const manufacturerName = computed(() => {
  return props.model.manufacturer?.name;
});

const manufacturerRoute = computed(() => {
  return {
    query: {
      q: {
        manufacturerIn: [props.model.manufacturer?.slug],
      } as unknown as string,
    },
  };
});
</script>

<script lang="ts">
export default {
  name: "ModelPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
