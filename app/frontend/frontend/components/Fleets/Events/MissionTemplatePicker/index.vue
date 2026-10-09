<script lang="ts">
export default {
  name: "FleetEventsMissionTemplatePicker",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type Mission,
  MissionStatusEnum,
  useFleetMissions,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMissionCover } from "@/frontend/composables/useMissionCover";

type Props = {
  fleet: Fleet;
  onPick: (mission: Mission | null) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { resolve } = useMissionCover();

const fleetSlug = computed(() => props.fleet.slug);
const {
  data: missions,
  isLoading,
  isError,
  refetch,
} = useFleetMissions(fleetSlug, ref({}));

// A draft has not been offered to the fleet yet, so nothing is spawned from it.
const missionList = computed<Mission[]>(() =>
  (missions.value?.items ?? []).filter(
    (mission) => mission.status !== MissionStatusEnum.DRAFT,
  ),
);

const pick = (mission: Mission | null) => {
  props.onPick(mission);
  comlink.emit("close-modal");
};
</script>

<template>
  <Modal :title="t('headlines.fleets.events.pickTemplate')">
    <p class="template-picker__note">
      {{ t("labels.fleets.events.pickTemplateHint") }}
    </p>

    <p v-if="isLoading" class="template-picker__note">
      {{ t("messages.loading") }}
    </p>

    <div
      v-else-if="isError && !missions"
      class="template-picker__error"
      data-test="mission-template-error"
    >
      <span class="template-picker__note">
        {{ t("labels.fleets.events.pickTemplateLoadFailed") }}
      </span>
      <Btn
        :size="BtnSizesEnum.SM"
        data-test="mission-template-retry"
        @click="refetch()"
      >
        {{ t("actions.retry") }}
      </Btn>
    </div>

    <p v-else-if="!missionList.length" class="template-picker__note">
      {{ t("labels.fleets.missions.noMissions") }}
    </p>

    <div class="template-list">
      <button
        type="button"
        class="template-card template-card--clear"
        data-test="mission-template-none"
        @click="pick(null)"
      >
        <i class="fa-light fa-ban template-card__icon" />
        <div class="template-card__body">
          <strong>{{ t("labels.fleets.events.noTemplate") }}</strong>
          <span class="template-card__hint">
            {{ t("labels.fleets.events.noTemplateHint") }}
          </span>
        </div>
      </button>

      <button
        v-for="mission in missionList"
        :key="mission.id"
        type="button"
        class="template-card"
        :data-test="`mission-template-${mission.slug}`"
        @click="pick(mission)"
      >
        <div
          class="template-card__cover"
          :style="{ backgroundImage: `url(${resolve(mission)})` }"
        />
        <div class="template-card__body">
          <strong class="template-card__title">{{ mission.title }}</strong>
          <div class="template-card__meta">
            <Pill uppercase>
              {{ t(`labels.fleets.missions.categories.${mission.category}`) }}
            </Pill>
            <span v-if="mission.scenario" class="template-card__hint">
              {{ mission.scenario }}
            </span>
          </div>
          <p
            v-if="mission.description"
            class="template-card__desc template-card__hint"
          >
            {{ mission.description }}
          </p>
          <div class="template-card__stats template-card__hint">
            <span>
              <strong>{{ mission.teamCount }}</strong>
              {{ t("labels.fleets.missions.teams") }}
            </span>
            <span>
              <strong>{{ mission.shipCount }}</strong>
              {{ t("labels.fleets.missions.ships") }}
            </span>
          </div>
        </div>
      </button>
    </div>

    <template #footer>
      <Btn
        :size="BtnSizesEnum.LG"
        :variant="BtnVariantsEnum.BARE"
        @click="comlink.emit('close-modal')"
      >
        {{ t("actions.cancel") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.template-picker__note {
  color: var(--color-text-dim);
}
.template-picker__error {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}
.template-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
  margin-top: 12px;
}
.template-card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  text-align: left;
  padding: 0;
  background: var(--color-control);
  border: 1px solid var(--color-edge-faint);
  border-radius: var(--radius-control);
  color: var(--color-text);
  cursor: pointer;
  overflow: hidden;
  transition:
    border-color 0.15s,
    transform 0.1s;

  &:hover {
    border-color: var(--color-edge-strong);
    transform: translateY(-1px);
  }
}
.template-card--clear {
  flex-direction: row;
  align-items: center;
  gap: 12px;
  padding: 14px;
  min-height: 76px;
}
.template-card__icon {
  font-size: 1.6rem;
  color: var(--color-muted);
}
.template-card__cover {
  width: 100%;
  height: 110px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}
.template-card__body {
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}
.template-card--clear .template-card__body {
  padding: 0;
}
.template-card__title {
  font-size: 15px;
}
.template-card__meta {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}
.template-card__hint {
  font-size: 12px;
  color: var(--color-text-dim);
}
.template-card__desc {
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.template-card__stats {
  display: flex;
  gap: 14px;

  strong {
    color: var(--color-text);
  }
}
</style>
