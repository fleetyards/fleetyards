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
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
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
      <PanelHeading>
        {{ t("headlines.admin.features.addFleet") }}
      </PanelHeading>
      <PanelBody>
        <section class="feature-section">
          <FleetActorSearch
            :enabled-ids="enabledIds"
            :busy="actions.busy.value"
            @add="add"
          />
        </section>
      </PanelBody>
    </Panel>

    <Panel>
      <PanelHeading>
        {{ t("headlines.admin.features.enabledFleets") }}
        <span class="text-muted">({{ fleets.length }})</span>
      </PanelHeading>
      <PanelBody>
        <section class="feature-section">
          <ActorList
            :actors="fleets"
            name="fleets"
            :filter-label="t('labels.features.filterFleets')"
            :empty-text="t('labels.features.noFleets')"
            @remove="remove"
          />
        </section>
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
@import "./actors";
</style>
