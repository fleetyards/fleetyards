<script lang="ts">
export default {
  name: "ModelsLoanersList",
};
</script>

<script lang="ts" setup>
import ModelSection from "@/frontend/components/Models/Section/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useModelLoaners as useModelLoanersQuery } from "@/services/fyApi";

type Props = {
  modelSlug: string;
};

const props = defineProps<Props>();

const { data: loaners, ...asyncStatus } = useModelLoanersQuery(props.modelSlug);

const { t } = useI18n();

// Drawn while its request is out, so a link to the section has somewhere to
// land; a ship with nothing to show here loses the section once it is back.
const isEmpty = computed(
  () =>
    !loaners.value?.items.length &&
    (asyncStatus.isSuccess.value || asyncStatus.isError.value),
);
</script>

<template>
  <ModelSection
    v-if="!isEmpty"
    anchor="loaners"
    :model-slug="modelSlug"
    :title="t('labels.model.loaners')"
  >
    <AsyncData :async-status="asyncStatus" hide-error>
      <template #resolved>
        <transition-group
          v-if="loaners?.items.length"
          name="fade-list"
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="item in loaners.items"
            :key="`loaners-${item.slug}`"
            class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel
              :model="item"
              :details="true"
              :level="HeadingLevelEnum.H3"
            />
          </div>
        </transition-group>
      </template>
    </AsyncData>
  </ModelSection>
</template>
