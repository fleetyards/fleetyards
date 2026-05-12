<script lang="ts">
export default {
  name: "FleetMissionEditDescriptionPage",
};
</script>

<script lang="ts" setup>
import { useForm, type SubmissionHandler } from "vee-validate";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import MissionEditFormShell from "@/frontend/components/Fleets/Missions/MissionEditFormShell/index.vue";
import {
  type Fleet,
  type MissionExtended,
  type MissionUpdateInput,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionCover } from "@/frontend/composables/useMissionCover";

type Props = {
  fleet: Fleet;
  mission: MissionExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { defineField, handleSubmit, meta, setErrors } =
  useForm<MissionUpdateInput>({
    initialValues: {
      description: props.mission.description ?? "",
      coverImage: undefined,
      coverImagePreset: props.mission.coverImagePreset ?? null,
    },
  });

const [description, descriptionProps] = defineField("description");
const [coverImage, coverImageProps] = defineField("coverImage");
const [coverImagePreset] = defineField("coverImagePreset");

const { presetsFor } = useMissionCover();

const presetOptions = computed(() =>
  presetsFor(props.mission.category as string),
);

const selectPreset = (key: string) => {
  coverImagePreset.value = (
    coverImagePreset.value === key ? null : key
  ) as never;
};

const existingCoverImage = computed(() => {
  return (
    props.mission as
      | { coverImage?: { url?: string; mediumUrl?: string } | null }
      | undefined
  )?.coverImage;
});

const wrapHandleSubmit = (cb: SubmissionHandler<MissionUpdateInput>) =>
  handleSubmit((values, ctx) =>
    cb(
      {
        description: values.description || null,
        coverImage: values.coverImage || undefined,
        coverImagePreset: values.coverImage ? null : values.coverImagePreset,
      },
      ctx,
    ),
  );
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.missions.editDescription") }}</Heading>
  <MissionEditFormShell
    :fleet="fleet"
    :mission="mission"
    :handle-submit="wrapHandleSubmit"
    :meta="meta"
    :set-errors="setErrors"
    form-id="fleet-mission-edit-description"
  >
    <div class="row">
      <div class="col-12">
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
          :label="t('labels.fleets.missions.description')"
        />
      </div>
    </div>

    <div v-if="presetOptions.length" class="row">
      <div class="col-12">
        <span class="cover-presets-label">
          {{ t("labels.fleets.missions.coverPresets") }}
        </span>
        <div class="cover-presets-grid">
          <button
            v-for="preset in presetOptions"
            :key="preset.key"
            type="button"
            class="cover-preset"
            :class="{
              'cover-preset--active': coverImagePreset === preset.key,
            }"
            :style="{ backgroundImage: `url(${preset.url})` }"
            @click="selectPreset(preset.key)"
          />
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <FormFileInput
          v-model="coverImage"
          v-bind="coverImageProps"
          :file="existingCoverImage as never"
          name="coverImage"
          :label="t('labels.fleets.missions.coverImage')"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
    </div>
  </MissionEditFormShell>
</template>

<style lang="scss" scoped>
.cover-presets-label {
  display: block;
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-bottom: 0.35rem;
}
.cover-presets-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 0.5rem;
  margin-bottom: 1rem;
}
.cover-preset {
  aspect-ratio: 16 / 9;
  background-size: cover;
  background-position: center;
  border: 2px solid rgba(255, 255, 255, 0.08);
  border-radius: 4px;
  cursor: pointer;
  padding: 0;
  transition: border-color 0.15s;

  &:hover {
    border-color: rgba(255, 255, 255, 0.4);
  }

  &--active {
    border-color: var(--accent, #4aa);
  }
}
</style>
