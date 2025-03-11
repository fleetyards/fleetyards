<script lang="ts">
export default {
  name: "ModelsLoanersList",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import { PanelHeadingLevelEnum } from "@/shared/components/Panel/Heading/types";
import { useModelLoaners as useModelLoanersQuery } from "@/services/fyApi";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { data: loaners, ...asyncStatus } = useModelLoanersQuery(props.modelSlug);

const { t } = useI18n();
</script>

<template>
  <AsyncData :async-status="asyncStatus" hide-error>
    <template v-if="loaners?.items.length" #resolved>
      <hr />
      <div id="loaners" class="row">
        <div class="col-12 variants">
          <h2 class="text-uppercase">
            {{ t(`labels.model.loaners`) }}
          </h2>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="item in loaners.items"
              :key="`loaners-${item.slug}`"
              class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
            >
              <ModelPanel
                :model="item"
                :details="true"
                :level="PanelHeadingLevelEnum.H3"
              />
            </div>
          </transition-group>
        </div>
      </div>
    </template>
  </AsyncData>
</template>
