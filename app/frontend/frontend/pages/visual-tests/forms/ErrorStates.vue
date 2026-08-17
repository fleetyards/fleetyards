<script lang="ts">
export default {
  name: "VisualTestsFormsErrorStates",
};
</script>

<script lang="ts" setup>
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { useForm } from "vee-validate";

// Only FormInput takes a `rules` prop, so the schema lives on the form — that
// covers the components that call `useField` without one. Validated up front so
// the invalid styling is visible without interaction; the message itself only
// shows in the field's tooltip.
const { validate } = useForm({
  validationSchema: {
    handle: "required",
    contact: "required|email",
    quantity: "required|min_value:1",
    notes: "required",
  },
  initialValues: {
    handle: "",
    contact: "not-an-email",
    quantity: 0,
    notes: "",
    terms: false,
  },
});

onMounted(async () => {
  await validate();
});
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput name="handle" label="Handle (required)" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput name="contact" label="Contact (email)" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput name="quantity" label="Quantity (min 1)" type="number" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormCheckbox name="terms" label="Accept terms" />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-md-6">
      <FormTextarea name="notes" label="Notes (required)" />
    </div>
  </div>
</template>
