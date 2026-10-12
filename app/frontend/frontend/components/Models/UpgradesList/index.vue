<script lang="ts">
export default {
  name: "ModelsModulesList",
};
</script>

<script lang="ts" setup>
import SectionEmpty from "@/frontend/components/Models/SectionEmpty/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import TeaserPanel from "@/shared/components/TeaserPanel/index.vue";
import { useModelUpgrades as useModelUpgradesQuery } from "@/services/fyApi";

type Props = {
  modelSlug: string;
  modelName: string;
};

const props = defineProps<Props>();

const { data: upgrades, ...asyncStatus } = useModelUpgradesQuery(
  props.modelSlug,
);

const { t } = useI18n();
</script>

<template>
  <!-- Always drawn, so the ship page's sections stand in the same place for
       every ship and a link to one has an anchor to land on before the
       request is back. -->
  <hr />
  <section id="upgrades" class="row">
    <div class="col-12">
      <Heading :level="HeadingLevelEnum.H2" hero>
        {{ t("labels.model.upgrades") }}
      </Heading>
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
          <SectionEmpty
            v-else
            :model-name="modelName"
            :section="t('labels.model.upgrades')"
          />
        </template>
      </AsyncData>
    </div>
  </section>
</template>
