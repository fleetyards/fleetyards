<script lang="ts">
export default {
  name: "FleetEventsMissionTemplatePicker",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type Fleet, type Mission, useFleetMissions } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMissionCover } from "@/frontend/composables/useMissionCover";

type Props = {
  fleet: Fleet;
  selectedSlug?: string | null;
  onPick: (mission: Mission | null) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { resolve } = useMissionCover();

const fleetSlug = computed(() => props.fleet.slug);
const { data: missions, isLoading } = useFleetMissions(fleetSlug, ref({}));

const missionList = computed<Mission[]>(() => missions.value?.items ?? []);

const pick = (mission: Mission | null) => {
  props.onPick(mission);
  comlink.emit("close-modal");
};
</script>

<template>
  <Modal :title="t('headlines.fleets.events.pickTemplate')">
    <p class="text-muted">{{ t("labels.fleets.events.pickTemplateHint") }}</p>

    <p v-if="isLoading" class="text-muted">{{ t("messages.loading") }}</p>

    <p v-else-if="!missionList.length" class="text-muted">
      {{ t("labels.fleets.missions.noMissions") }}
    </p>

    <div v-else class="template-list">
      <button
        type="button"
        class="template-card template-card--clear"
        :class="{ 'template-card--active': !selectedSlug }"
        @click="pick(null)"
      >
        <i class="fa-light fa-ban template-card__icon" />
        <div class="template-card__body">
          <strong>{{ t("labels.fleets.events.noTemplate") }}</strong>
          <span class="text-muted small">
            {{ t("labels.fleets.events.noTemplateHint") }}
          </span>
        </div>
      </button>

      <button
        v-for="mission in missionList"
        :key="mission.id"
        type="button"
        class="template-card"
        :class="{ 'template-card--active': selectedSlug === mission.slug }"
        @click="pick(mission)"
      >
        <div
          class="template-card__cover"
          :style="{ backgroundImage: `url(${resolve(mission)})` }"
        />
        <div class="template-card__body">
          <strong class="template-card__title">{{ mission.title }}</strong>
          <div class="template-card__meta">
            <span class="template-card__badge">
              {{ t(`labels.fleets.missions.categories.${mission.category}`) }}
            </span>
            <span
              v-if="(mission as { scenario?: string | null }).scenario"
              class="text-muted small"
            >
              {{ (mission as { scenario?: string | null }).scenario }}
            </span>
          </div>
          <p
            v-if="mission.description"
            class="template-card__desc text-muted small"
          >
            {{ mission.description }}
          </p>
          <div class="template-card__stats text-muted small">
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
      <div class="float-sm-right">
        <Btn
          :size="BtnSizesEnum.LARGE"
          inline
          variant="link"
          @click="comlink.emit('close-modal')"
        >
          {{ t("actions.cancel") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.template-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 0.75rem;
  margin-top: 0.75rem;
}
.template-card {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  text-align: left;
  padding: 0;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 6px;
  cursor: pointer;
  overflow: hidden;
  transition:
    border-color 0.15s,
    transform 0.1s;

  &:hover {
    border-color: rgba(255, 255, 255, 0.25);
    transform: translateY(-1px);
  }
}
.template-card--active {
  border-color: var(--accent, #4aa);
  box-shadow: 0 0 0 1px var(--accent, #4aa);
}
.template-card--clear {
  flex-direction: row;
  align-items: center;
  gap: 0.75rem;
  padding: 0.85rem;
  min-height: 76px;
}
.template-card__icon {
  font-size: 1.6rem;
  color: var(--text-muted);
}
.template-card__cover {
  width: 100%;
  height: 110px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}
.template-card__body {
  padding: 0.6rem 0.85rem;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  flex: 1;
}
.template-card--clear .template-card__body {
  padding: 0;
}
.template-card__title {
  font-size: 0.95rem;
}
.template-card__meta {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  flex-wrap: wrap;
}
.template-card__badge {
  font-size: 0.65rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 0.1rem 0.4rem;
  border-radius: 999px;
  background: rgba(74, 170, 170, 0.18);
  color: var(--accent, #4aa);
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
  gap: 0.85rem;

  strong {
    color: var(--text);
  }
}
.small {
  font-size: 0.78rem;
}
</style>
