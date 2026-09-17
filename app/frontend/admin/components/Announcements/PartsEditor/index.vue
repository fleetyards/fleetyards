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

import {
  blueskyLength,
  discordLength,
  xLength,
} from "@/shared/utils/socialCounters";

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
  limits?: {
    label: string;
    limit: number;
    counter?: "x" | "bluesky" | "discord";
  }[];
};

const props = withDefaults(defineProps<Props>(), {
  hint: undefined,
  partPlaceholder: undefined,
  limits: () => [],
});

const parts = defineModel<string[]>({ required: true });

const { t } = useI18n();

// Two or more parts are a thread, and the form says so: a rail down the left
// ties them together and each row reads as a reply to the one above. Presentation
// only -- what goes out is unchanged.
const threaded = computed(() => parts.value.length > 1);

/*
 * Discord messages carry a position marker the composer adds, so its cost is
 * counted here too. Without it the editor offers the full 2,000 and the send
 * bounces — which is exactly the margin a 1,982-character message sits in.
 */
const DISCORD_MARKER_OVERHEAD = 9;

function countFor(text: string, counter?: "x" | "bluesky" | "discord") {
  if (counter === "x") return xLength(text);
  if (counter === "discord") {
    return discordLength(text) + (threaded.value ? DISCORD_MARKER_OVERHEAD : 0);
  }

  return blueskyLength(text);
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
  <div
    class="parts-editor"
    :class="{ 'parts-editor--threaded': threaded }"
    :data-test="`parts-editor-${props.name}`"
  >
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
        <i
          v-if="threaded && index > 0"
          class="parts-editor__reply fa-duotone fa-reply"
          aria-hidden="true"
        />
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
              countFor(part, counter.counter) > counter.limit,
          }"
          class="parts-editor__count"
        >
          {{ counter.label }}
          {{ countFor(part, counter.counter) }}/{{ counter.limit }}
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

/*
 * The rail runs down the gutter between the rows, so it connects them without
 * moving the fields. `::before` on the part rather than a border on the list:
 * the last row stops the line at its own head, which is what makes it read as
 * a chain with an end rather than an open-ended column.
 */
.parts-editor--threaded .parts-editor__part {
  position: relative;
  padding-left: 18px;
}

.parts-editor--threaded .parts-editor__part::before {
  content: "";
  position: absolute;
  left: 5px;
  top: 12px;
  bottom: -12px;
  width: 2px;
  background: $gray-lighter;
  opacity: 0.35;
}

.parts-editor--threaded .parts-editor__part:last-child::before {
  bottom: auto;
  height: 10px;
}

.parts-editor--threaded .parts-editor__part:first-child::before {
  top: 18px;
}

.parts-editor__reply {
  color: $gray-lighter;
  margin-right: 4px;
  opacity: 0.7;
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
