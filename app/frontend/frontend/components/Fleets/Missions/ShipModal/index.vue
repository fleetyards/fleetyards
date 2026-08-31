<script lang="ts">
export default {
  name: "FleetMissionsShipModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type Mission,
  type MissionShip,
  type MissionTeam,
  type FilterOption,
  type Model,
  models as fetchModels,
  modelPositions as fetchModelPositions,
  useModelClassificationsFilters,
  useModelFocusFilters,
  useCreateMissionShip,
  useUpdateMissionShip,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  mission: Mission;
  team: MissionTeam;
  ship?: MissionShip;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const isEdit = computed(() => !!props.ship);
const submitting = ref(false);

type ShipMode = "specific" | "list" | "filter";

// A new spot opens on the list. Naming the handful of ships that fit is the
// answer most spots want; one exact ship and a range of criteria are the
// narrower and the broader exception either side of it.
const initialMode: ShipMode = !props.ship
  ? "list"
  : props.ship.strict
    ? "specific"
    : props.ship.allowedModels?.length
      ? "list"
      : "filter";
const mode = ref<ShipMode>(initialMode);

// The models a listed spot will take, in the order they were picked.
const selectedModelIds = ref<string[]>(
  (props.ship?.allowedModels ?? []).map((model) => model.id),
);

const sizeOptions: FilterOption[] = [
  { value: "snub", label: "Snub" },
  { value: "small", label: "Small" },
  { value: "medium", label: "Medium" },
  { value: "large", label: "Large" },
  { value: "extra_large", label: "Extra Large" },
  { value: "capital", label: "Capital" },
];

const { defineField, handleSubmit } = useForm({
  initialValues: {
    title: props.ship?.title ?? "",
    description: props.ship?.description ?? "",
    classification: props.ship?.filters?.classification ?? "",
    focus: props.ship?.filters?.focus ?? "",
    minSize: props.ship?.filters?.minSize ?? "",
    maxSize: props.ship?.filters?.maxSize ?? "",
    minCrew: props.ship?.filters?.minCrew ?? null,
    minCargo: props.ship?.filters?.minCargo ?? null,
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [classification] = defineField("classification");
const [focus] = defineField("focus");

const { data: classificationFilters } = useModelClassificationsFilters();

const focusFilterParams = computed(() => ({
  classification: (classification.value as string) || undefined,
}));
const { data: focusFilters } = useModelFocusFilters(focusFilterParams);

const classificationOptions = computed<FilterOption[]>(
  () => (classificationFilters.value as FilterOption[] | undefined) ?? [],
);
const focusOptions = computed<FilterOption[]>(
  () => (focusFilters.value as FilterOption[] | undefined) ?? [],
);

watch(classification, (newValue, oldValue) => {
  if (newValue !== oldValue && focus.value) {
    focus.value = "";
  }
});
const [minSize] = defineField("minSize");
const [maxSize] = defineField("maxSize");
const [minCrew, minCrewProps] = defineField("minCrew");
const [minCargo, minCargoProps] = defineField("minCargo");

const selectedModelId = ref<string | undefined>(props.ship?.model?.id);
const selectedModelSlug = ref<string | undefined>(props.ship?.model?.slug);

const fetchModelOptions = (params: BaseSelectParams<FilterOption>) => {
  const q: Record<string, unknown> = { inGameEq: true };
  if (params.search) q.nameCont = params.search;
  if (params.missing) q.idIn = [params.missing as string];
  return fetchModels({
    page: String(params.page || 1),
    q: q as never,
  });
};

const formatModels = (response: { items: Model[] }) => {
  return (response.items || []).map((m) => ({
    label: m.name,
    value: m.id,
    object: m,
  }));
};

const resolveSlugForId = async (id: string | undefined) => {
  if (!id) return undefined;
  if (id === props.ship?.model?.id && props.ship.model.slug) {
    return props.ship.model.slug;
  }
  const response = await fetchModels({
    q: { idIn: [id] } as never,
  });
  return response.items?.[0]?.slug;
};

watch(selectedModelId, async (newId) => {
  selectedModelSlug.value = await resolveSlugForId(newId);
});

type Position = {
  id: string;
  name: string;
  positionType: string;
};

const positions = ref<Position[]>([]);
const selectedPositionIds = ref<Set<string>>(new Set());
const positionsLoading = ref(false);

watch(selectedModelSlug, async (slug) => {
  if (mode.value !== "specific" || !slug) {
    positions.value = [];
    selectedPositionIds.value = new Set();
    return;
  }

  positionsLoading.value = true;
  try {
    const response = await fetchModelPositions(slug);
    const items = (response as Position[] | undefined) ?? [];
    positions.value = items;
    selectedPositionIds.value = new Set(items.map((p) => p.id));
  } catch {
    positions.value = [];
    selectedPositionIds.value = new Set();
  } finally {
    positionsLoading.value = false;
  }
});

const togglePosition = (id: string) => {
  const next = new Set(selectedPositionIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  selectedPositionIds.value = next;
};

const createMutation = useCreateMissionShip();
const updateMutation = useUpdateMissionShip();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data: Record<string, unknown> = {
    title: values.title || null,
    description: values.description || null,
  };

  if (mode.value === "specific") {
    data.modelId = selectedModelId.value || null;
    data.allowedModelIds = [];
    if (!isEdit.value) {
      data.positionIds = Array.from(selectedPositionIds.value);
    }
    data.minCrew = values.minCrew == null ? null : Number(values.minCrew);
  } else if (mode.value === "list") {
    // Each mode is the whole answer, so switching to a list clears the model and
    // the criteria rather than leaving a spot that says two things at once.
    data.modelId = null;
    data.allowedModelIds = selectedModelIds.value;
    data.classification = null;
    data.focus = null;
    data.minSize = null;
    data.maxSize = null;
    data.minCrew = null;
    data.minCargo = null;
  } else {
    data.allowedModelIds = [];
    data.modelId = null;
    data.classification = values.classification || null;
    data.focus = values.focus || null;
    data.minSize = values.minSize || null;
    data.maxSize = values.maxSize || null;
    data.minCrew = values.minCrew || null;
    data.minCargo = values.minCargo || null;
  }

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        missionSlug: props.mission.slug,
        missionTeamId: props.team.id,
        id: props.ship!.id,
        data: data as never,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        missionSlug: props.mission.slug,
        missionTeamId: props.team.id,
        data: data as never,
      });

  await mutation
    .then(() => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleets.missionShip.update.success")
          : t("messages.fleets.missionShip.create.success"),
      });
      comlink.emit("mission-children-changed");
      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({
        text: isEdit.value
          ? t("messages.fleets.missionShip.update.failure")
          : t("messages.fleets.missionShip.create.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal
    :title="
      isEdit
        ? t('headlines.fleets.missions.editShip')
        : t('headlines.fleets.missions.addShip')
    "
  >
    <form id="ship-form" @submit.prevent="onSubmit">
      <!-- The switch is a section break, so it keeps the 1rem the fields below
           it carry between them. -->
      <div class="mb-4 flex">
        <BtnGroup segmented>
          <Btn :active="mode === 'list'" @click="mode = 'list'">
            {{ t("labels.fleets.missions.modelList") }}
          </Btn>
          <Btn :active="mode === 'filter'" @click="mode = 'filter'">
            {{ t("labels.fleets.missions.filterRange") }}
          </Btn>
          <Btn :active="mode === 'specific'" @click="mode = 'specific'">
            {{ t("labels.fleets.missions.modelSpecific") }}
          </Btn>
        </BtnGroup>
      </div>

      <template v-if="mode === 'list'">
        <!-- The same picker the specific mode uses, taking several: a spot that
             names its ships is a list of one or more, not a filter. -->
        <BaseSelect
          v-model="selectedModelIds"
          :query-fn="fetchModelOptions"
          :query-response-formatter="formatModels"
          :label="t('labels.fleets.missions.allowedShips')"
          name="allowedModelIds"
          multiple
          :searchable="true"
          :paginated="true"
        />
        <p class="text-muted small">
          {{ t("labels.fleets.missions.modelListHint") }}
        </p>
      </template>

      <template v-else-if="mode === 'specific'">
        <BaseSelect
          v-model="selectedModelId"
          :query-fn="fetchModelOptions"
          :query-response-formatter="formatModels"
          :label="t('labels.fleets.missions.ship')"
          name="modelId"
          :searchable="true"
          :paginated="true"
        />

        <div v-if="!isEdit && positions.length" class="seat-checklist">
          <strong class="seat-checklist-label">
            {{ t("labels.fleets.missions.seats") }}
          </strong>
          <label
            v-for="position in positions"
            :key="position.id"
            class="seat-row"
          >
            <input
              type="checkbox"
              :checked="selectedPositionIds.has(position.id)"
              @change="togglePosition(position.id)"
            />
            <span class="seat-name">{{ position.name }}</span>
            <span class="seat-type">{{ position.positionType }}</span>
          </label>
        </div>

        <p v-else-if="!isEdit && positionsLoading" class="text-muted">
          {{ t("messages.loading") }}
        </p>

        <div class="min-crew-override">
          <FormInput
            v-model="minCrew"
            v-bind="minCrewProps"
            name="minCrew"
            type="number"
            :label="t('labels.fleets.missions.minCrewOverrideLabel')"
          >
            <template #subline>
              {{ t("labels.fleets.missions.minCrewOverrideHint") }}
            </template>
          </FormInput>
        </div>
      </template>

      <template v-else>
        <BaseSelect
          v-model="classification"
          :options="classificationOptions"
          :label="t('labels.fleets.missions.classification')"
          name="classification"
          :searchable="false"
          :nullable="true"
        />
        <BaseSelect
          v-model="focus"
          :options="focusOptions"
          :label="t('labels.fleets.missions.focus')"
          name="focus"
          :searchable="true"
          :nullable="true"
        />
        <div class="form-row">
          <BaseSelect
            v-model="minSize"
            :options="sizeOptions"
            :label="t('labels.fleets.missions.minSize')"
            name="minSize"
            :searchable="false"
            :nullable="true"
          />
          <BaseSelect
            v-model="maxSize"
            :options="sizeOptions"
            :label="t('labels.fleets.missions.maxSize')"
            name="maxSize"
            :searchable="false"
            :nullable="true"
          />
        </div>
        <div class="form-row">
          <FormInput
            v-model="minCrew"
            v-bind="minCrewProps"
            name="minCrew"
            type="number"
            :label="t('labels.fleets.missions.minCrew')"
          />
          <FormInput
            v-model="minCargo"
            v-bind="minCargoProps"
            name="minCargo"
            type="number"
            :label="t('labels.fleets.missions.minCargo')"
          />
        </div>
      </template>

      <FormInput
        v-model="title"
        v-bind="titleProps"
        name="title"
        :label="t('labels.fleets.missions.title')"
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.fleets.missions.description')"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.seat-checklist {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);
  margin-top: 8px;
}
.seat-checklist-label {
  display: block;
  margin-bottom: 4px;
  font-size: 13px;
  color: var(--color-muted, #7a8288);
}
.seat-row {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 14px;
}
.seat-name {
  flex: 1;
}
.seat-type {
  font-size: 12px;
  color: var(--color-muted, #7a8288);
  text-transform: uppercase;
}
.min-crew-override {
  margin-top: 8px;
}
.min-crew-override .small {
  font-size: 12px;
  margin: 4px 0 0;
}
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
@media (max-width: 480px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
