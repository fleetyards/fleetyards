<template>
  <AsyncData :async-status="asyncStatus" hide-error>
    <template v-if="upgrades?.length" #resolved>
      <hr />
      <div id="upgrades" class="row">
        <div class="col-12">
          <h2 class="text-uppercase">
            {{ t(`labels.model.upgrades`) }}
          </h2>
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

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import { useModelQueries } from "@/frontend/composables/useModelQueries";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { upgradesQuery } = useModelQueries(props.modelSlug);

const { data: upgrades, ...asyncStatus } = upgradesQuery();

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>
