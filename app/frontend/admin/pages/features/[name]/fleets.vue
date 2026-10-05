<script lang="ts">
export default {
  name: "AdminFeatureFleetsPage",
};
</script>

<script lang="ts" setup>
import {
  type Feature,
  type FeatureActor,
  type FleetOption,
} from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import ActorList from "@/admin/components/Features/ActorList/index.vue";
import FleetActorSearch from "@/admin/components/Features/FleetActorSearch/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatureActions } from "@/admin/composables/useFeatureActions";

type Props = {
  feature: Feature;
};

const props = defineProps<Props>();

const { t } = useI18n();

const fleets = computed(() =>
  props.feature.actors.filter((actor) => actor.type === "Fleet"),
);

const actions = useFeatureActions(() => props.feature.name);

const enabledIds = computed(() => fleets.value.map((fleet) => fleet.id));

const add = (fleet: FleetOption) => actions.addActor("Fleet", fleet.id);

const remove = (actor: FeatureActor) => actions.removeActor("Fleet", actor.id);
</script>

<template>
  <div class="feature-actors-page">
    <Panel>
      <section class="feature-section">
        <h3>{{ t("headlines.admin.features.addFleet") }}</h3>
        <FleetActorSearch
          :enabled-ids="enabledIds"
          :busy="actions.busy.value"
          @add="add"
        />
      </section>
    </Panel>

    <Panel>
      <section class="feature-section">
        <h3>
          {{ t("headlines.admin.features.enabledFleets") }}
          <span class="text-muted">({{ fleets.length }})</span>
        </h3>
        <ActorList
          :actors="fleets"
          name="fleets"
          :filter-label="t('labels.features.filterFleets')"
          :empty-text="t('labels.features.noFleets')"
          @remove="remove"
        />
      </section>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
@import "./actors";
</style>
