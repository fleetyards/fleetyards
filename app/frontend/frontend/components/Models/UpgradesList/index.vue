<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>

<script lang="ts" setup>
import ModelSection from "@/frontend/components/Models/Section/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import { useModelUpgrades as useModelUpgradesQuery } from "@/services/fyApi";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { data: upgrades, ...asyncStatus } = useModelUpgradesQuery(
  props.modelSlug,
);

const { t } = useI18n();

// Drawn while its request is out, so a link to the section has somewhere to
// land; a ship with nothing to show here loses the section once it is back.
const isEmpty = computed(
  () =>
    !upgrades.value?.length &&
    (asyncStatus.isSuccess.value || asyncStatus.isError.value),
);
</script>

<template>
  <ModelSection
    v-if="!isEmpty"
    anchor="upgrades"
    :model-slug="modelSlug"
    :title="t('labels.model.upgrades')"
  >
    <AsyncData :async-status="asyncStatus" hide-error>
      <template #resolved>
        <transition-group
          v-if="upgrades?.length"
          name="fade-list"
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="item in upgrades"
            :key="`upgrades-${item.id}`"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
          >
            <TeaserPanel :item="item" level="h3" />
          </div>
        </transition-group>
      </template>
    </AsyncData>
  </ModelSection>
</template>
