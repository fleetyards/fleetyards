<script lang="ts">
export default {
  name: "AnnouncementPartsEditor",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  label: string;
  hint?: string;
  /*
   * Passed explicitly because the name carries the row's index, so there is no
   * fixed key for FormTextarea to look a placeholder up under -- and its
   * fallback renders the missing-translation string straight into the box.
   */
  partPlaceholder?: string;
  /** Per-platform caps, drawn as a count under each part. */
  limits?: { label: string; limit: number; weighted?: boolean }[];
};

const props = withDefaults(defineProps<Props>(), {
  hint: undefined,
  partPlaceholder: undefined,
  limits: () => [],
});

const parts = defineModel<string[]>({ required: true });

const { t } = useI18n();

/*
 * X bills every URL at 23 characters whatever its real length, because it
 * wraps them through t.co. Counting plain characters would tell an author a
 * post is over when it is not — which is why the copy in docs/announcements
 * carries two different counts for the same text.
 */
const URL_WEIGHT = 23;
const URL_PATTERN = /https?:\/\/\S+/g;

function weightedLength(text: string) {
  return text.replace(URL_PATTERN, "x".repeat(URL_WEIGHT)).length;
}

function countFor(text: string, weighted: boolean) {
  return weighted ? weightedLength(text) : [...text].length;
}

const add = () => {
  parts.value = [...parts.value, ""];
};

const remove = (index: number) => {
  parts.value = parts.value.filter((_, position) => position !== index);
};

const move = (index: number, by: number) => {
  const next = [...parts.value];
  const [part] = next.splice(index, 1);
  next.splice(index + by, 0, part);
  parts.value = next;
};

const update = (index: number, value: string) => {
  parts.value = parts.value.map((part, position) =>
    position === index ? value : part,
  );
};
</script>

<template>
  <div class="parts-editor" :data-test="`parts-editor-${props.name}`">
    <div class="parts-editor__head">
      <span class="parts-editor__label">{{ props.label }}</span>
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.announcements.addPart')"
        data-test="parts-editor-add"
        @click="add"
      >
        <i class="fa fa-plus" />
        {{ t("actions.announcements.addPart") }}
      </Btn>
    </div>

    <p v-if="props.hint" class="parts-editor__hint">{{ props.hint }}</p>

    <div
      v-for="(part, index) in parts"
      :key="index"
      class="parts-editor__part"
      data-test="parts-editor-part"
    >
      <div class="parts-editor__part-head">
        <span class="parts-editor__position">
          {{
            t("labels.admin.announcements.partPosition", {
              position: index + 1,
              total: parts.length,
            })
          }}
        </span>
        <Btn
          :size="BtnSizesEnum.SM"
          :disabled="index === 0"
          :aria-label="t('actions.announcements.movePartUp')"
          data-test="parts-editor-up"
          @click="move(index, -1)"
        >
          <i class="fa-duotone fa-arrow-up" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :disabled="index === parts.length - 1"
          :aria-label="t('actions.announcements.movePartDown')"
          data-test="parts-editor-down"
          @click="move(index, 1)"
        >
          <i class="fa-duotone fa-arrow-down" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :aria-label="t('actions.announcements.removePart')"
          data-test="parts-editor-remove"
          @click="remove(index)"
        >
          <i class="fa-duotone fa-trash" />
        </Btn>
      </div>

      <FormTextarea
        :model-value="part"
        :name="`${props.name}-${index}`"
        :placeholder="props.partPlaceholder"
        :no-placeholder="!props.partPlaceholder"
        no-label
        @update:model-value="update(index, String($event ?? ''))"
      />

      <p v-if="props.limits.length" class="parts-editor__counts">
        <span
          v-for="counter in props.limits"
          :key="counter.label"
          :class="{
            'parts-editor__count--over':
              countFor(part, !!counter.weighted) > counter.limit,
          }"
          class="parts-editor__count"
        >
          {{ counter.label }}
          {{ countFor(part, !!counter.weighted) }}/{{ counter.limit }}
        </span>
      </p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.parts-editor {
  margin-bottom: 24px;
}

.parts-editor__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 4px;
}

.parts-editor__label {
  font-weight: 600;
}

.parts-editor__hint,
.parts-editor__counts {
  color: $gray-lighter;
  font-size: 0.875rem;
  margin: 0 0 8px;
}

.parts-editor__part {
  margin-bottom: 12px;
}

.parts-editor__part-head {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-bottom: 4px;
}

.parts-editor__position {
  margin-right: auto;
  color: $gray-lighter;
  font-size: 0.875rem;
}

.parts-editor__count {
  margin-right: 12px;
}

.parts-editor__count--over {
  color: $danger;
  font-weight: 600;
}
</style>
