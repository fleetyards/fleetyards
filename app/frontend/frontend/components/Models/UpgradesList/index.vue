<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
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
</script>

<template>
  <AsyncData :async-status="asyncStatus" hide-error>
    <template v-if="upgrades?.length" #resolved>
      <hr />
      <div id="upgrades" class="row">
        <div class="col-12">
          <Heading :level="HeadingLevelEnum.H2" hero>
            {{ t(`labels.model.upgrades`) }}
          </Heading>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="item in upgrades"
              :key="`upgrades-${item.id}`"
              class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
            >
              <TeaserPanel :item="item" level="h3" />
            </div>
          </transition-group>
        </div>
      </div>
    </template>
  </AsyncData>
</template>
