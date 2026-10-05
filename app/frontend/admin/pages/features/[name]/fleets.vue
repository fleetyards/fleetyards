<script lang="ts">
export default {
  name: "AdminFeatureFleetsPage",
};
</script>

<script lang="ts" setup>
import { type Feature, type FeatureActor } from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import ActorList from "@/admin/components/Features/ActorList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FleetSelect from "@/admin/components/base/FleetSelect/index.vue";
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

const enabledFids = computed(() =>
  fleets.value.flatMap((fleet) => (fleet.fid ? [fleet.fid] : [])),
);

const selectedFleet = ref<string>();

const alreadyEnabled = computed(
  () =>
    !!selectedFleet.value && enabledFids.value.includes(selectedFleet.value),
);

const add = async () => {
  if (!selectedFleet.value || alreadyEnabled.value) return;

  if (await actions.addActor("Fleet", selectedFleet.value)) {
    selectedFleet.value = undefined;
  }
};

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
          <div class="feature-add-actor">
            <FleetSelect
              v-model="selectedFleet"
              name="feature-fleet"
              :marked-fids="enabledFids"
              :marked-label="t('labels.features.alreadyEnabled')"
              inline
            />
            <Btn
              :disabled="!selectedFleet || alreadyEnabled"
              :loading="actions.busy.value"
              data-test="feature-add-fleet"
              @click="add"
            >
              <i class="fa-duotone fa-plus" />
              {{ t("actions.add") }}
            </Btn>
          </div>
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
