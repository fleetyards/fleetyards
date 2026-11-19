<script lang="ts">
export default {
  name: "FeedbackReplyForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  label: string;
  submitLabel: string;
  hint?: string;
  maxlength: number;
  // Resolves when the reply was taken; a rejection keeps what was typed.
  send: (body: string) => Promise<void>;
};

const props = withDefaults(defineProps<Props>(), { hint: undefined });

const initialValues = { body: "" };

const { defineField, handleSubmit, resetForm } = useForm({ initialValues });

const [body, bodyProps] = defineField("body");

const sending = ref(false);

const onSubmit = handleSubmit(async (values) => {
  sending.value = true;

  try {
    await props.send(String(values.body).trim());
    resetForm({ values: { body: "" } });
  } catch {
    // The caller has told the reader what went wrong.
  } finally {
    sending.value = false;
  }
});
</script>

<template>
  <form
    class="feedback-reply-form"
    data-test="feedback-reply-form"
    @submit.prevent="onSubmit"
  >
    <FormTextarea
      v-model="body"
      name="body"
      v-bind="bodyProps"
      rules="required"
      :label="label"
      :info="hint"
      :maxlength="maxlength"
      data-test="feedback-reply-body"
    />
    <Btn
      :type="BtnTypesEnum.SUBMIT"
      :loading="sending"
      commit
      data-test="feedback-reply-submit"
    >
      {{ submitLabel }}
    </Btn>
  </form>
</template>

<style lang="scss" scoped>
.feedback-reply-form {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;

  > :first-child {
    align-self: stretch;
  }
}
</style>
