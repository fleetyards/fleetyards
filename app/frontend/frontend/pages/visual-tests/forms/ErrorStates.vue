<script lang="ts">
export default {
  name: "VisualTestsFormsErrorStates",
};
</script>

<script lang="ts" setup>
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useForm } from "vee-validate";

// The checkbox and the toggle reserve a field label's line so they line up with
// the fields beside them in these rows -- see D7. Off by default, because on its
// own a standalone checkbox has no field to line up with.
//
// Only FormInput takes a `rules` prop, so the schema lives on the form — that
// covers every control that calls `useField` without one, which is all of these.
// Validated up front so the invalid styling is visible without interaction.
//
// RadioList and FilterGroup are absent because they do not bind a field at all,
// so a form has no way to mark them; and no control in this design system has a
// readonly state, which is worth knowing before looking for one.
const { validate } = useForm({
  validationSchema: {
    handle: "required",
    contact: "required|email",
    quantity: "required|min_value:1",
    notes: "required",
    terms: "required",
    boughtAt: "required",
    avatar: "required",
    newsletter: "required",
  },
  initialValues: {
    handle: "",
    contact: "not-an-email",
    quantity: 0,
    notes: "",
    terms: false,
    boughtAt: null,
    avatar: null,
    newsletter: false,
  },
});

onMounted(async () => {
  await validate();
});
</script>

<template>
  <div data-test="error-states">
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
        <FormCheckbox name="terms" label="Accept terms" align-with-fields />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormTextarea name="notes" label="Notes (required)" />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-3">
        <FormDatePicker name="boughtAt" label="Bought at (required)" />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <FormToggle
          name="newsletter"
          label="Newsletter (required)"
          align-with-fields
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <FormFileInput
          name="avatar"
          label="Avatar (required)"
          :allowed-types="AllowedFileTypes.IMAGE"
          :allowed-size-mb="5"
        />
      </div>
    </div>
  </div>
</template>
