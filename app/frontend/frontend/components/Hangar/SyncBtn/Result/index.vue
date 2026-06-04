<script lang="ts">
export default {
  name: "HangarSyncResult",
};
</script>

<script lang="ts" setup>
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import SupportHint from "@/shared/components/SupportHint/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { RsiHangarItemInput, HangarSyncResult } from "@/services/fyApi";
import type { SyncProcessStep } from "./types";

type Props = {
  processSteps: SyncProcessStep[];
  currentPage: number;
  pledges: RsiHangarItemInput[];
  result?: HangarSyncResult;
  finished: boolean;
  finishedWithErrors: boolean;
  showSupportHint?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  result: undefined,
  showSupportHint: false,
});

defineEmits<{
  (event: "support-hint-dismiss"): void;
}>();

const { t } = useI18n();

const items = computed(() =>
  props.pledges.filter((pledge) =>
    ["ship", "component", "upgrade"].includes(pledge.type),
  ),
);

const ships = computed(() =>
  props.pledges.filter((pledge) => pledge.type === "ship"),
);

const components = computed(() =>
  props.pledges.filter((pledge) => pledge.type === "component"),
);

const upgrades = computed(() =>
  props.pledges.filter((pledge) => pledge.type === "upgrade"),
);

const importedVehicles = computed(() => props.result?.importedVehicles || []);
const foundVehicles = computed(() => props.result?.foundVehicles || []);
const movedVehiclesToWanted = computed(
  () => props.result?.movedVehiclesToWanted || [],
);
const missingModels = computed(() => props.result?.missingModels || []);
const importedComponents = computed(
  () => props.result?.importedComponents || [],
);
const foundComponents = computed(() => props.result?.foundComponents || []);
const missingComponents = computed(() => props.result?.missingComponents || []);
const missingComponentVehicles = computed(
  () => props.result?.missingComponentVehicles || [],
);
const importedUpgrades = computed(() => props.result?.importedUpgrades || []);
const foundUpgrades = computed(() => props.result?.foundUpgrades || []);
const missingUpgrades = computed(() => props.result?.missingUpgrades || []);
const missingUpgradeVehicles = computed(
  () => props.result?.missingUpgradeVehicles || [],
);

const visibleSteps = computed(() =>
  props.processSteps.filter((step) => step.status !== "pending"),
);

const hasWarnings = computed(
  () =>
    missingModels.value.length > 0 ||
    missingComponents.value.length > 0 ||
    missingComponentVehicles.value.length > 0 ||
    missingUpgrades.value.length > 0 ||
    missingUpgradeVehicles.value.length > 0,
);
</script>

<template>
  <div class="hangar-sync-result flex flex-col gap-4">
    <p
      class="flex justify-center text-uppercase mb-0"
      :class="{
        'text-warning': !finished && !finishedWithErrors,
        'text-success': finished,
        'text-danger': finishedWithErrors,
      }"
    >
      <b v-if="finished">{{ t("labels.syncExtension.status.finished") }}</b>
      <b v-else-if="finishedWithErrors">
        {{ t("labels.syncExtension.status.failed") }}
      </b>
      <b v-else>{{ t("labels.syncExtension.status.started") }}</b>
    </p>
    <ul v-if="processSteps.length" class="list-unstyled process-steps-list">
      <li
        v-for="step in visibleSteps"
        :key="step.name"
        class="process-steps-item"
        :class="{ 'text-muted': step.status === 'pending' }"
      >
        <div class="process-steps-item-title">
          <p>{{ t(`labels.syncExtension.processSteps.${step.name}`) }}</p>
          <SmallLoader
            :loading="step.status === 'processing'"
            alignment="right"
          />
          <i
            v-if="step.status === 'success'"
            class="fa-light fa-check text-success"
          />
          <i
            v-if="step.status === 'failure'"
            class="fa-light fa-times text-danger"
          />
        </div>
        <div v-if="step.name === 'fetchHangar'" class="process-steps-item-info">
          <dl class="row">
            <dt class="col-sm-7">
              {{ t("labels.syncExtension.pledgeItems.pages") }}:
            </dt>
            <dd class="col-sm-5 text-right">{{ currentPage }}</dd>
            <template v-if="items.length">
              <dt class="col-sm-7">
                {{ t("labels.syncExtension.pledgeItems.all") }}:
              </dt>
              <dd class="col-sm-5 text-right">{{ items.length }}</dd>
            </template>
            <template v-if="ships.length">
              <dt class="col-sm-7">
                {{ t("labels.syncExtension.pledgeItems.ships") }}:
              </dt>
              <dd class="col-sm-5 text-right">{{ ships.length }}</dd>
            </template>
            <template v-if="components.length">
              <dt class="col-sm-7">
                {{ t("labels.syncExtension.pledgeItems.components") }}:
              </dt>
              <dd class="col-sm-5 text-right">{{ components.length }}</dd>
            </template>
            <template v-if="upgrades.length">
              <dt class="col-sm-7">
                {{ t("labels.syncExtension.pledgeItems.upgrades") }}:
              </dt>
              <dd class="col-sm-5 text-right">{{ upgrades.length }}</dd>
            </template>
          </dl>
        </div>
        <div v-if="step.name === 'submitData'" class="process-steps-item-info">
          <dl class="row">
            <template v-if="importedVehicles.length">
              <dt class="col-sm-8">
                {{ t("labels.syncExtension.importedItems.importedVehicles") }}:
              </dt>
              <dd class="col-sm-4 text-right">
                {{ importedVehicles.length }}
              </dd>
            </template>
            <template v-if="foundVehicles.length">
              <dt class="col-sm-8">
                {{ t("labels.syncExtension.importedItems.foundVehicles") }}:
              </dt>
              <dd class="col-sm-4 text-right">
                {{ foundVehicles.length }}
              </dd>
            </template>
            <template v-if="movedVehiclesToWanted.length">
              <dt class="col-sm-8">
                {{
                  t("labels.syncExtension.importedItems.movedVehiclesToWanted")
                }}:
              </dt>
              <dd class="col-sm-4 text-right">
                {{ movedVehiclesToWanted.length }}
              </dd>
            </template>
            <template v-if="importedComponents.length">
              <dt class="col-sm-8">
                {{
                  t("labels.syncExtension.importedItems.importedComponents")
                }}:
              </dt>
              <dd class="col-sm-4 text-right">
                {{ importedComponents.length }}
              </dd>
            </template>
            <template v-if="foundComponents.length">
              <dt class="col-sm-8">
                {{ t("labels.syncExtension.importedItems.foundComponents") }}:
              </dt>
              <dd class="col-sm-4 text-right">
                {{ foundComponents.length }}
              </dd>
            </template>
            <template v-if="importedUpgrades.length">
              <dt class="col-sm-8">
                {{ t("labels.syncExtension.importedItems.importedUpgrades") }}:
              </dt>
              <dd class="col-sm-4 text-right">
                {{ importedUpgrades.length }}
              </dd>
            </template>
            <template v-if="foundUpgrades.length">
              <dt class="col-sm-8">
                {{ t("labels.syncExtension.importedItems.foundUpgrades") }}:
              </dt>
              <dd class="col-sm-4 text-right">{{ foundUpgrades.length }}</dd>
            </template>
          </dl>
        </div>
        <div v-if="step.name === 'submitData' && hasWarnings" class="sync-warnings">
          <h6 class="sync-warnings__title">
            {{ t("labels.syncExtension.warnings") }}
          </h6>
          <div class="sync-warnings__body">
            <dl class="row">
              <template v-if="missingModels.length">
                <dt class="col-sm-8">
                  {{ t("labels.syncExtension.importedItems.missingModels") }}:
                </dt>
                <dd class="col-sm-4 text-right">
                  {{ missingModels.length }}
                </dd>
                <dd class="col-12 missing-items">
                  <ul>
                    <li
                      v-for="item in missingModels"
                      :key="`missing-ship-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </dd>
              </template>
              <template v-if="missingComponents.length">
                <dt class="col-sm-8">
                  {{
                    t("labels.syncExtension.importedItems.missingComponents")
                  }}:
                </dt>
                <dd class="col-sm-4 text-right">
                  {{ missingComponents.length }}
                </dd>
                <dd class="col-12 missing-items">
                  <ul>
                    <li
                      v-for="item in missingComponents"
                      :key="`missing-component-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </dd>
              </template>
              <template v-if="missingComponentVehicles.length">
                <dt class="col-sm-8">
                  {{
                    t(
                      "labels.syncExtension.importedItems.missingComponentVehicles",
                    )
                  }}:
                </dt>
                <dd class="col-sm-4 text-right">
                  {{ missingComponentVehicles.length }}
                </dd>
                <dd class="col-12 missing-items">
                  <ul>
                    <li
                      v-for="item in missingComponentVehicles"
                      :key="`missing-component-vehicle-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </dd>
              </template>
              <template v-if="missingUpgrades.length">
                <dt class="col-sm-8">
                  {{ t("labels.syncExtension.importedItems.missingUpgrades") }}:
                </dt>
                <dd class="col-sm-4 text-right">
                  {{ missingUpgrades.length }}
                </dd>
                <dd class="col-12 missing-items">
                  <ul>
                    <li
                      v-for="item in missingUpgrades"
                      :key="`missing-upgrade-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </dd>
              </template>
              <template v-if="missingUpgradeVehicles.length">
                <dt class="col-sm-8">
                  {{
                    t(
                      "labels.syncExtension.importedItems.missingUpgradeVehicles",
                    )
                  }}:
                </dt>
                <dd class="col-sm-4 text-right">
                  {{ missingUpgradeVehicles.length }}
                </dd>
                <dd class="col-12 missing-items">
                  <ul>
                    <li
                      v-for="item in missingUpgradeVehicles"
                      :key="`missing-upgrade-vehicle-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </dd>
              </template>
            </dl>
          </div>
        </div>
      </li>
    </ul>
    <transition name="fade">
      <SupportHint
        v-if="showSupportHint"
        inline
        context="hangarSync"
        :meta="{ count: importedVehicles.length }"
        @dismiss="$emit('support-hint-dismiss')"
      />
    </transition>
  </div>
</template>

<style lang="scss" scoped>
.process-steps-list {
  .process-steps-item {
    margin-bottom: 10px;

    .process-steps-item-title {
      position: relative;
      font-weight: bold;
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-right: 10px;
      margin-bottom: 10px;

      p {
        margin-bottom: 0;
      }
    }

    .process-steps-item-info {
      margin-left: 30px;
      margin-right: 10px;

      dl {
        font-size: 90%;
      }

      dt {
        font-weight: normal;
      }
    }

    .sync-warnings {
      margin-top: 1rem;
      margin-right: 10px;

      &__title {
        color: $warning;
        font-weight: bold;
        text-transform: uppercase;
        font-size: 0.85rem;
        letter-spacing: 0.05em;
        margin-bottom: 0.5rem;
      }

      &__body {
        margin-left: 30px;

        dl {
          font-size: 90%;
        }

        dt {
          font-weight: normal;
        }

        .missing-items {
          margin-bottom: 0.5rem;

          ul {
            margin: 0;
            padding-left: 1rem;
            list-style: disc;
          }
        }
      }
    }
  }
}
</style>
