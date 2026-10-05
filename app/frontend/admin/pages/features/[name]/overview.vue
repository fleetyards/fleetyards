<script lang="ts">
export default {
  name: "AdminFeatureOverviewPage",
};
</script>

<script lang="ts" setup>
import { type Feature } from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatureActions } from "@/admin/composables/useFeatureActions";

type Props = {
  feature: Feature;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const actions = useFeatureActions(() => props.feature.name);

const isOn = computed(() => props.feature.state === "on");

const availableGroups = ["testers", "admins"];

const missingGroups = computed(() =>
  availableGroups.filter((group) => !props.feature.groups.includes(group)),
);

// Whole days open, which is what the removal decision is made on.
const daysOpen = computed(() => {
  if (!props.feature.fullyOnSince) return null;

  return Math.floor(
    (Date.now() - new Date(props.feature.fullyOnSince).getTime()) /
      (1000 * 60 * 60 * 24),
  );
});

const rangeValue = (event: Event) =>
  Number((event.target as HTMLInputElement).value);
</script>

<template>
  <div class="feature-overview">
    <Panel>
      <section class="feature-section" data-test="feature-global">
        <h3>{{ t("headlines.admin.features.globalState") }}</h3>
        <p class="text-muted">{{ t("labels.features.globalHint") }}</p>
        <Toggle
          :active="isOn"
          :loading="actions.busy.value"
          :label="
            isOn ? t('actions.disableGlobally') : t('actions.enableGlobally')
          "
          data-test="toggle-global"
          @toggle="actions.setGlobal(!isOn)"
        />
        <p class="feature-meta text-muted">
          <BasePill
            v-if="daysOpen !== null && !feature.permanent"
            margin-right
            data-test="feature-open-for"
          >
            {{ t("labels.features.openFor", { days: daysOpen }) }}
          </BasePill>
          <template v-if="feature.lastChangedAt">
            {{
              t("labels.features.lastChanged", {
                date: l(feature.lastChangedAt),
              })
            }}
            <template v-if="feature.lastChangedSource">
              ({{ t(`labels.features.sources.${feature.lastChangedSource}`) }}
              <template v-if="feature.lastChangedBy">
                {{
                  t("labels.features.historyBy", {
                    actor: feature.lastChangedBy,
                  })
                }}</template
              >)
            </template>
          </template>
        </p>
      </section>
    </Panel>

    <Panel>
      <section class="feature-section" data-test="feature-self-service">
        <h3>{{ t("headlines.admin.features.selfService") }}</h3>
        <p class="text-muted">{{ t("labels.features.selfServiceHint") }}</p>
        <div class="feature-toggles">
          <Toggle
            :active="feature.selfServiceUser"
            :label="t('labels.features.selfServiceUser')"
            data-test="toggle-self-service"
            @toggle="actions.toggleUserSelfService()"
          />
          <Toggle
            :active="feature.selfServiceFleet"
            :label="t('labels.features.selfServiceFleet')"
            data-test="toggle-fleet-self-service"
            @toggle="actions.toggleFleetSelfService()"
          />
        </div>
      </section>
    </Panel>

    <Panel>
      <section class="feature-section" data-test="feature-rollout">
        <h3>{{ t("headlines.admin.features.groups") }}</h3>
        <div class="feature-groups">
          <span
            v-for="group in feature.groups"
            :key="group"
            class="feature-group"
            :data-test="`feature-group-${group}`"
          >
            <BasePill>{{ group }}</BasePill>
            <Btn
              :aria-label="t('actions.remove')"
              :title="t('actions.remove')"
              @click="actions.removeGroup(group)"
            >
              <i class="fa-duotone fa-times" />
            </Btn>
          </span>
          <span v-if="!feature.groups.length" class="text-muted">
            {{ t("labels.features.noGroups") }}
          </span>
        </div>
        <div v-if="missingGroups.length" class="feature-groups">
          <Btn
            v-for="group in missingGroups"
            :key="group"
            :data-test="`add-group-${group}`"
            @click="actions.addGroup(group)"
          >
            <i class="fa-duotone fa-plus" />
            {{ group }}
          </Btn>
        </div>

        <h3>{{ t("headlines.admin.features.percentageOfActors") }}</h3>
        <div class="feature-percentage">
          <input
            type="range"
            min="0"
            max="100"
            :value="feature.percentageOfActors"
            :aria-label="t('headlines.admin.features.percentageOfActors')"
            data-test="percentage-of-actors"
            @change="actions.setPercentageOfActors(rangeValue($event))"
          />
          <span class="feature-percentage-value">
            {{ feature.percentageOfActors }}%
          </span>
        </div>

        <h3>{{ t("headlines.admin.features.percentageOfTime") }}</h3>
        <div class="feature-percentage">
          <input
            type="range"
            min="0"
            max="100"
            :value="feature.percentageOfTime"
            :aria-label="t('headlines.admin.features.percentageOfTime')"
            data-test="percentage-of-time"
            @change="actions.setPercentageOfTime(rangeValue($event))"
          />
          <span class="feature-percentage-value">
            {{ feature.percentageOfTime }}%
          </span>
        </div>
      </section>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.feature-overview {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.feature-section {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;

  h3 {
    margin: 0;
    font-size: 1rem;
  }

  p {
    margin: 0;
  }
}

.feature-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.25rem;
}

.feature-toggles,
.feature-groups {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem 1.5rem;
}

.feature-group {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.feature-percentage {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  max-width: 32rem;

  input[type="range"] {
    flex: 1;
  }
}

.feature-percentage-value {
  min-width: 3rem;
  text-align: right;
  font-weight: 600;
}
</style>
