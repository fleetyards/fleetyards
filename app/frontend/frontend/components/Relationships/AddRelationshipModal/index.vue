<script lang="ts">
export default {
  name: "RelationshipsAddRelationshipModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  title: string;
  label: string;
  placeholder: string;
  hint: string;
  submitLabel: string;
  onSubmit: (handle: string) => Promise<boolean>;
};

const props = defineProps<Props>();

const comlink = useComlink();

const handle = ref("");
const submitting = ref(false);

const invalid = computed(() => handle.value.trim() === "");

const submit = async () => {
  if (invalid.value) return;

  submitting.value = true;

  try {
    // Closed only on success. A refusal -- already related, at capacity, no
    // such handle -- leaves the typed value where it is so it can be corrected
    // rather than retyped.
    if (await props.onSubmit(handle.value.trim())) {
      comlink.emit("close-modal");
    }
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="title">
    <form id="add-relationship-form" @submit.prevent="submit">
      <p class="add-relationship__hint">
        {{ hint }}
      </p>

      <FormInput
        v-model="handle"
        name="handle"
        :label="label"
        :placeholder="placeholder"
        data-test="relationship-handle"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :disabled="invalid"
          :size="BtnSizesEnum.LG"
          data-test="relationship-submit"
          @click="submit"
        >
          {{ submitLabel }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.add-relationship__hint {
  margin-bottom: 1rem;
  opacity: 0.75;
}
</style>
