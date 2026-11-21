<script lang="ts">
export default {
  name: "BlueprintLogImportModal",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { filesFromDataTransfer } from "@/shared/components/DirectUpload/directoryFiles";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  importBlueprintsFromLogs,
  matchBlueprintLogNames,
  type BlueprintLogImportResult,
} from "@/services/fyApi";
import {
  isImportableChannel,
  isLogFile,
  readBlueprintLog,
  uniqueNames,
  type BlueprintReceipt,
} from "@/frontend/utils/blueprintLog";
import { reviewMatches, type BlueprintLogReview } from "../review";

const { t } = useI18n();

const comlink = useComlink();

const queryClient = useQueryClient();

const { displayAlert, displaySuccess } = useAppNotifications();

type Step = "pick" | "reading" | "review" | "importing" | "done";

const step = ref<Step>("pick");

const filesTotal = ref(0);
const filesRead = ref(0);
const skippedFiles = ref(0);

const review = ref<BlueprintLogReview>();
const selected = ref<Set<string>>(new Set());
const result = ref<BlueprintLogImportResult>();

const isDragging = ref(false);
const folderInput = ref<HTMLInputElement>();
const filesInput = ref<HTMLInputElement>();

const reset = () => {
  step.value = "pick";
  review.value = undefined;
  selected.value = new Set();
  result.value = undefined;
  filesRead.value = 0;
  filesTotal.value = 0;
  skippedFiles.value = 0;
};

const readFiles = async (files: File[]) => {
  const logs = files.filter(isLogFile);

  if (!logs.length) {
    displayAlert({ text: t("messages.blueprintLogImport.noLogs") });
    return;
  }

  step.value = "reading";
  filesTotal.value = logs.length;

  const receipts: BlueprintReceipt[] = [];

  try {
    for (const file of logs) {
      const log = await readBlueprintLog(file);

      if (!isImportableChannel(log.channel)) skippedFiles.value += 1;

      receipts.push(...log.receipts);
      filesRead.value += 1;
    }

    const names = uniqueNames(receipts);

    const matches = names.length ? await matchBlueprintLogNames({ names }) : [];

    review.value = reviewMatches(matches);
    selected.value = new Set(review.value.fresh.map(({ slug }) => slug));
    step.value = "review";
  } catch {
    displayAlert({ text: t("messages.blueprintLogImport.failure") });
    reset();
  }
};

const onDrop = async (event: DragEvent) => {
  isDragging.value = false;

  if (!event.dataTransfer) return;

  await readFiles(await filesFromDataTransfer(event.dataTransfer));
};

const onInputChange = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  const files = Array.from(input.files ?? []);

  input.value = "";

  await readFiles(files);
};

const toggle = (slug: string, checked: boolean) => {
  const next = new Set(selected.value);

  if (checked) {
    next.add(slug);
  } else {
    next.delete(slug);
  }

  selected.value = next;
};

const foundCount = computed(() => {
  if (!review.value) return 0;

  const { fresh, ambiguous, owned, unmatched } = review.value;

  return fresh.length + ambiguous.length + owned.length + unmatched.length;
});

const submit = async () => {
  if (!review.value || !selected.value.size) return;

  step.value = "importing";

  try {
    result.value = await importBlueprintsFromLogs({
      slugs: [...selected.value],
      unmatchedNames: review.value.unmatched,
    });

    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ["blueprints"] }),
      queryClient.invalidateQueries({
        queryKey: ["hangar", "blueprint-missions"],
      }),
      queryClient.invalidateQueries({ queryKey: ["imports"] }),
      queryClient.invalidateQueries({
        predicate: (query) =>
          query.queryKey[0] === "fleets" && query.queryKey[2] === "blueprints",
      }),
    ]);

    displaySuccess({
      text: t("messages.blueprintLogImport.success", {
        count: result.value.imported,
      }),
    });

    step.value = "done";
  } catch {
    displayAlert({ text: t("messages.blueprintLogImport.failure") });
    step.value = "review";
  }
};

const importRoute = computed(() =>
  result.value
    ? { name: "hangar-import", params: { id: result.value.importId } }
    : undefined,
);

const close = () => comlink.emit("close-modal");
</script>

<template>
  <Modal
    :title="t('headlines.blueprintLogImport')"
    :loading="step === 'importing'"
  >
    <div v-if="step === 'pick'" class="blueprint-log-import">
      <p>{{ t("texts.blueprintLogImport.intro") }}</p>
      <code class="blueprint-log-import__path">
        {{ t("texts.blueprintLogImport.path") }}
      </code>

      <div
        class="blueprint-log-import__dropzone"
        :class="{ 'blueprint-log-import__dropzone--dragging': isDragging }"
        data-test="blueprint-log-import-dropzone"
        @dragover.prevent="isDragging = true"
        @dragleave.prevent="isDragging = false"
        @drop.prevent.stop="onDrop"
      >
        <i class="fa-light fa-folder-arrow-up blueprint-log-import__icon" />
        <span>{{ t("texts.blueprintLogImport.drop") }}</span>
        <div class="blueprint-log-import__browse">
          <Btn
            :variant="BtnVariantsEnum.GHOST"
            data-test="blueprint-log-import-folder"
            @click="folderInput?.click()"
          >
            {{ t("actions.blueprintLogImport.chooseFolder") }}
          </Btn>
          <Btn
            :variant="BtnVariantsEnum.BARE"
            data-test="blueprint-log-import-files"
            @click="filesInput?.click()"
          >
            {{ t("actions.blueprintLogImport.chooseFiles") }}
          </Btn>
        </div>
      </div>

      <input
        ref="folderInput"
        type="file"
        class="blueprint-log-import__input"
        webkitdirectory
        multiple
        @change="onInputChange"
      />
      <input
        ref="filesInput"
        type="file"
        class="blueprint-log-import__input"
        accept=".log"
        multiple
        data-test="blueprint-log-import-files-input"
        @change="onInputChange"
      />

      <p class="blueprint-log-import__hint">
        <i class="fa-light fa-lock" />
        {{ t("texts.blueprintLogImport.privacy") }}
      </p>
      <p class="blueprint-log-import__hint">
        <i class="fa-light fa-clock-rotate-left" />
        {{ t("texts.blueprintLogImport.limits") }}
      </p>
    </div>

    <div v-else-if="step === 'reading'" class="blueprint-log-import">
      <p>
        {{
          t("texts.blueprintLogImport.reading", {
            read: filesRead,
            total: filesTotal,
          })
        }}
      </p>
      <ProgressBar
        :progress="filesTotal ? (filesRead / filesTotal) * 100 : 0"
      />
    </div>

    <div
      v-else-if="review && (step === 'review' || step === 'importing')"
      class="blueprint-log-import"
      data-test="blueprint-log-import-review"
    >
      <Alert v-if="!foundCount">
        {{ t("texts.blueprintLogImport.nothingFound") }}
      </Alert>
      <p v-else>
        {{ t("texts.blueprintLogImport.found", { count: foundCount }) }}
      </p>
      <p v-if="skippedFiles" class="blueprint-log-import__hint">
        {{
          t("texts.blueprintLogImport.skippedFiles", { count: skippedFiles })
        }}
      </p>

      <section
        v-if="review.fresh.length"
        class="blueprint-log-import__section"
        data-test="blueprint-log-import-fresh"
      >
        <h4 class="blueprint-log-import__title">
          {{ t("labels.blueprintLogImport.fresh") }}
          <span class="blueprint-log-import__count">
            {{ review.fresh.length }}
          </span>
        </h4>
        <FormCheckbox
          v-for="option in review.fresh"
          :key="option.slug"
          :name="`blueprint-log-import-${option.slug}`"
          :label="option.name"
          :model-value="selected.has(option.slug)"
          @update:model-value="toggle(option.slug, !!$event)"
        />
      </section>

      <section
        v-if="review.ambiguous.length"
        class="blueprint-log-import__section"
        data-test="blueprint-log-import-ambiguous"
      >
        <h4 class="blueprint-log-import__title">
          {{ t("labels.blueprintLogImport.ambiguous") }}
          <span class="blueprint-log-import__count">
            {{ review.ambiguous.length }}
          </span>
        </h4>
        <p class="blueprint-log-import__hint">
          {{ t("texts.blueprintLogImport.ambiguous") }}
        </p>
        <div
          v-for="match in review.ambiguous"
          :key="match.name"
          class="blueprint-log-import__group"
        >
          <FormCheckbox
            v-for="option in match.blueprints"
            :key="option.slug"
            :name="`blueprint-log-import-${option.slug}`"
            :label="`${option.name} (${option.slug})`"
            :model-value="selected.has(option.slug)"
            @update:model-value="toggle(option.slug, !!$event)"
          />
        </div>
      </section>

      <section v-if="review.owned.length" class="blueprint-log-import__section">
        <h4 class="blueprint-log-import__title">
          {{ t("labels.blueprintLogImport.owned") }}
          <span class="blueprint-log-import__count">
            {{ review.owned.length }}
          </span>
        </h4>
        <ul class="blueprint-log-import__list">
          <li v-for="option in review.owned" :key="option.slug">
            {{ option.name }}
          </li>
        </ul>
      </section>

      <section
        v-if="review.unmatched.length"
        class="blueprint-log-import__section"
        data-test="blueprint-log-import-unmatched"
      >
        <h4 class="blueprint-log-import__title">
          {{ t("labels.blueprintLogImport.unmatched") }}
          <span class="blueprint-log-import__count">
            {{ review.unmatched.length }}
          </span>
        </h4>
        <ul class="blueprint-log-import__list">
          <li v-for="name in review.unmatched" :key="name">{{ name }}</li>
        </ul>
      </section>
    </div>

    <div
      v-else-if="step === 'done' && result"
      class="blueprint-log-import"
      data-test="blueprint-log-import-done"
    >
      <p class="blueprint-log-import__result">
        {{
          t("messages.blueprintLogImport.success", { count: result.imported })
        }}
      </p>
      <p v-if="result.unchanged" class="blueprint-log-import__hint">
        {{
          t("texts.blueprintLogImport.alreadyOwned", {
            count: result.unchanged,
          })
        }}
      </p>
      <RouterLink v-if="importRoute" :to="importRoute" @click="close">
        {{ t("actions.blueprintLogImport.showImport") }}
      </RouterLink>
    </div>

    <template v-if="step !== 'pick' && step !== 'reading'" #footer>
      <template v-if="step === 'review' || step === 'importing'">
        <Btn :variant="BtnVariantsEnum.BARE" @click="reset">
          {{ t("actions.blueprintLogImport.startOver") }}
        </Btn>
        <Btn
          :disabled="!selected.size"
          :loading="step === 'importing'"
          data-test="blueprint-log-import-submit"
          @click="submit"
        >
          {{ t("actions.blueprintLogImport.import", { count: selected.size }) }}
        </Btn>
      </template>
      <Btn v-else-if="step === 'done'" @click="close">
        {{ t("actions.close") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.blueprint-log-import {
  display: flex;
  flex-direction: column;
  gap: 12px;

  p {
    margin: 0;
  }

  &__path {
    display: block;
    word-break: break-all;
  }

  &__dropzone {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 10px;
    min-height: 150px;
    padding: 20px;
    text-align: center;
    border: 2px dashed var(--color-edge, rgb(122 130 136 / 0.5));
    border-radius: var(--radius-control, 8px);
    transition: border-color 0.2s;

    &--dragging {
      border-color: var(--color-primary, currentcolor);
    }
  }

  &__icon {
    font-size: 2rem;
    opacity: 0.7;
  }

  &__browse {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 8px;
  }

  &__input {
    display: none;
  }

  &__hint {
    font-size: 0.9em;
    opacity: 0.75;
  }

  &__result {
    font-size: 1.1em;
  }

  &__section {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  &__group {
    display: flex;
    flex-direction: column;
    padding-bottom: 6px;
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 8px 0 4px;
  }

  &__count {
    opacity: 0.6;
    font-weight: normal;
  }

  &__list {
    margin: 0;
    padding-left: 20px;
    max-height: 200px;
    overflow-y: auto;
  }
}
</style>
