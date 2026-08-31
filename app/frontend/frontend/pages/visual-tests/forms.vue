<script lang="ts">
export default {
  name: "VisualTestsFormsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormInputGroup from "@/shared/components/base/FormInputGroup/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import Slider from "@/shared/components/base/Slider/index.vue";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import ErrorStates from "@/frontend/pages/visual-tests/forms/ErrorStates.vue";
import FileInputStates from "@/frontend/pages/visual-tests/forms/FileInputStates.vue";
import TabsDemo from "@/frontend/pages/visual-tests/forms/TabsDemo.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  InputAlignmentsEnum,
  InputSizesEnum,
  InputTypesEnum,
  InputVariantsEnum,
} from "@/shared/components/base/FormInput/types";
import { type FilterOption } from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { displaySuccess } = useAppNotifications();

const text = ref("Aegis Dynamics");
const number = ref(42);
const password = ref("hunter2");
const email = ref("pilot@fleetyards.net");
const url = ref("https://fleetyards.net");
const color = ref("#ffcc00");
const clearable = ref("Clear me");
const prefixed = ref(1250);
const empty = ref<string | null>(null);
const dateTime = ref<string | null>("2029-06-14T19:30:00.000Z");
const dateOnly = ref<string | null>("2029-06-14T00:00:00.000Z");
const dateTimeEmpty = ref<string | null>(null);
const large = ref("Large size");
const clean = ref("Clean variant");
const rightAligned = ref(998);

const textarea = ref(
  "The Galaxy is a modular multi-role ship. Swap the module to change what the ship does.",
);

const checkbox = ref(true);
const checkboxUnchecked = ref(false);
const checkboxGroup = ref<string[]>(["cargo"]);
const toggleField = ref(true);

const date = ref("2026-08-12");

const file = ref<string | null>(null);

const radio = ref("medium");

const sliderValue = ref(40);
const sliderStepped = ref(4);

const toggleActive = ref(true);
const toggleLoading = ref(false);

const filterSingle = ref<string | null>("medium");

const filterMultiple = ref<string[]>(["small", "large"]);

const sizes = [
  { label: "Small", value: "small" },
  { label: "Medium", value: "medium" },
  { label: "Large", value: "large" },
  { label: "Capital", value: "capital" },
];

// RadioList and FilterGroup type their options differently — RadioList requires
// a non-null string value, FilterGroup allows null.
const radioOptions = sizes;
const sizeOptions: FilterOption[] = sizes;

const submitting = ref(false);

// Tracked so a pending fake round-trip cannot resolve after the page is gone and
// push its notification onto whatever route the user landed on.
const timers: ReturnType<typeof setTimeout>[] = [];

const later = (callback: () => void, delay: number) => {
  timers.push(setTimeout(callback, delay));
};

onBeforeUnmount(() => {
  timers.forEach(clearTimeout);
});

const onSubmit = () => {
  submitting.value = true;

  later(() => {
    submitting.value = false;
    displaySuccess({ text: "Form submitted." });
  }, 1500);
};

const onCancel = () => {
  displaySuccess({ text: "Form cancelled." });
};

const toggleTheToggle = () => {
  toggleActive.value = !toggleActive.value;
};

const fireToggleLoading = () => {
  toggleLoading.value = true;

  later(() => {
    toggleLoading.value = false;
  }, 2000);
};

const sliderMarks = (value: number) =>
  value % 25 === 0 ? { label: `${value}%` } : false;

const sliderTooltip = (value: number) => `${value}%`;

const powerMarks = (value: number) => ({ label: String(value) });
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">FormInput | Types</Heading>
  <p>Every input type the component supports, each bound to live state.</p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput v-model="text" name="text" label="Text" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="number"
        name="number"
        label="Number"
        :type="InputTypesEnum.NUMBER"
        :step="1"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="password"
        name="password"
        label="Password"
        :type="InputTypesEnum.PASSWORD"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="email"
        name="email"
        label="Email"
        :type="InputTypesEnum.EMAIL"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="url"
        name="url"
        label="URL"
        :type="InputTypesEnum.URL"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="color"
        name="color"
        label="Color"
        :type="InputTypesEnum.COLOR"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormInput | Variations</Heading>
  <p>
    Sizes, variants, alignment, affixes, icon labels and the clearable,
    placeholder-only and disabled states.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="large"
        name="large"
        label="Large"
        :size="InputSizesEnum.LARGE"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="clean"
        name="clean"
        label="Clean"
        :variant="InputVariantsEnum.CLEAN"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="rightAligned"
        name="right-aligned"
        label="Right aligned"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="clearable"
        name="clearable"
        label="Clearable"
        clearable
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="prefixed"
        name="prefixed"
        label="With affixes"
        :type="InputTypesEnum.NUMBER"
        prefix="UEC"
        suffix="/ SCU"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="text"
        name="with-icon"
        label="With icon"
        icon="fa-duotone fa-rocket"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="empty"
        name="placeholder-only"
        label="Hidden until filled"
        placeholder="Search ships…"
        hide-label-on-empty
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput v-model="text" name="disabled" label="Disabled" disabled />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormInputGroup</Heading>
  <p>An input with a button glued to its trailing edge, baseline aligned.</p>
  <div class="row">
    <div class="col-12 col-md-6">
      <FormInputGroup>
        <FormInput v-model="text" name="grouped" label="RSI Handle" />
        <Btn>Verify</Btn>
      </FormInputGroup>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormTextarea</Heading>
  <p>Default and disabled.</p>
  <div class="row">
    <div class="col-12 col-md-6">
      <FormTextarea v-model="textarea" name="textarea" label="Description" />
    </div>
    <div class="col-12 col-md-6">
      <FormTextarea
        v-model="textarea"
        name="textarea-disabled"
        label="Description (disabled)"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormCheckbox & FormToggle</Heading>
  <p>
    Checked, unchecked, partial (the select-all tri-state), disabled, inline,
    and a multi-value group sharing one array.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormCheckbox v-model="checkbox" name="checked" label="Checked" />
      <FormCheckbox
        v-model="checkboxUnchecked"
        name="unchecked"
        label="Unchecked"
      />
      <FormCheckbox name="partial" label="Partial" partial />
      <FormCheckbox
        v-model="checkbox"
        name="checkbox-disabled"
        label="Disabled"
        disabled
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormCheckbox
        v-model="checkboxGroup"
        name="focus"
        label="Cargo"
        checkbox-value="cargo"
      />
      <FormCheckbox
        v-model="checkboxGroup"
        name="focus"
        label="Combat"
        checkbox-value="combat"
      />
      <FormCheckbox
        v-model="checkboxGroup"
        name="focus"
        label="Exploration"
        checkbox-value="exploration"
      />
      <p class="text-muted">Selected: {{ checkboxGroup.join(", ") || "—" }}</p>
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormCheckbox name="inline-a" label="Inline A" inline />
      <FormCheckbox name="inline-b" label="Inline B" inline />
      <FormCheckbox name="no-label" no-label inline />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormToggle v-model="toggleField" name="toggle-field" label="Public" />
      <FormToggle
        v-model="toggleField"
        name="toggle-field-disabled"
        label="Public (disabled)"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormDatePicker</Heading>
  <p>Bound to an ISO date string.</p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormDatePicker v-model="date" name="date" label="Bought at" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDatePicker
        v-model="date"
        name="disabledDate"
        label="Disabled"
        disabled
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <p class="text-muted">Value: {{ date || "—" }}</p>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormDateTime</Heading>
  <p>
    Date and time in one control, bound to an ISO string. The displayed format
    follows the signed-in user's setting, so it reads as
    <code>dd.mm.yyyy</code> or <code>mm/dd/yyyy</code> for the same value.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime v-model="dateTime" name="startsAt" label="Starts at" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateOnly"
        name="dateOnly"
        label="Date only"
        :enable-time-picker="false"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTimeEmpty"
        name="emptyDateTime"
        label="Empty, not clearable"
        :clearable="false"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTime"
        name="disabledDateTime"
        label="Disabled"
        disabled
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTimeEmpty"
        name="invalidDateTime"
        label="With an error"
        error-message="Pick a date after today"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTime"
        name="hourlyDateTime"
        label="Whole hours only"
        :minutes-increment="60"
      />
    </div>
    <div class="col-12 col-md-6">
      <p class="text-muted">Value: {{ dateTime || "—" }}</p>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormTabs</Heading>
  <TabsDemo />

  <Heading :level="HeadingLevelEnum.H2">FormFileInput</Heading>
  <p>The drop target, plus the avatar and transparent variants.</p>
  <div class="row">
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="image"
        label="Image"
        :allowed-types="AllowedFileTypes.IMAGE"
        :allowed-size-mb="5"
        clearable
      />
    </div>
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="disabledImage"
        label="Disabled"
        :allowed-types="AllowedFileTypes.IMAGE"
        :allowed-size-mb="5"
        disabled
      />
    </div>
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="avatar"
        label="Avatar"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
        avatar
      />
    </div>
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="transparent"
        label="Transparent"
        :allowed-types="AllowedFileTypes.IMAGE"
        transparent
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormFileInput | States</Heading>
  <p>
    The states it can be in, which is more than any other control: empty,
    holding a value that was saved elsewhere, disabled with one, and invalid.
    Each in the plain, avatar and transparent treatments.
  </p>
  <FileInputStates />

  <Heading :level="HeadingLevelEnum.H2">RadioList</Heading>
  <p>Inline and stacked, with and without a reset option.</p>
  <div class="row">
    <div class="col-12 col-md-4">
      <RadioList
        v-model="radio"
        name="size-inline"
        label="Ship Size"
        :options="radioOptions"
      />
    </div>
    <div class="col-12 col-md-4">
      <RadioList
        v-model="radio"
        name="size-reset"
        label="Ship Size (resettable)"
        reset-label="Any"
        :options="radioOptions"
      />
    </div>
    <div class="col-12 col-md-4">
      <RadioList
        v-model="radio"
        name="size-stacked"
        label="Ship Size (stacked, disabled)"
        :options="radioOptions"
        :inline="false"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FilterGroup</Heading>
  <p>
    Single select, multi select with the selected-options rail, searchable, and
    disabled. Options are static here — in the app they usually come from a
    paginated query.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterSingle"
        name="filter-single"
        label="Ship Size"
        :options="sizeOptions"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterMultiple"
        name="filter-multiple"
        label="Ship Sizes"
        :options="sizeOptions"
        multiple
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterSingle"
        name="filter-searchable"
        label="Ship Size (searchable)"
        search-label="Find a size…"
        :options="sizeOptions"
        searchable
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterSingle"
        name="filter-disabled"
        label="Ship Size (disabled)"
        :options="sizeOptions"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Slider</Heading>
  <p>
    With a percentage tooltip and quarter marks, and a stepped variant with a
    mark per stop.
  </p>
  <div class="row">
    <div class="col-12 col-md-6">
      <Slider
        v-model="sliderValue"
        :marks="sliderMarks"
        :tooltip-formatter="sliderTooltip"
        process
      />
      <p class="text-muted">Value: {{ sliderValue }}</p>
    </div>
    <div class="col-12 col-md-6">
      <Slider
        v-model="sliderStepped"
        :min="0"
        :max="8"
        :interval="1"
        :marks="powerMarks"
        :dot-size="14"
      />
      <p class="text-muted">Pips: {{ sliderStepped }}</p>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Toggle</Heading>
  <p>
    The standalone switch — not a form field, it just emits
    <code>toggle</code>.
  </p>
  <div class="row">
    <div class="col-12">
      <Toggle :active="toggleActive" label="Active" @toggle="toggleTheToggle" />
      <Toggle :active="false" label="Inactive" @toggle="toggleTheToggle" />
      <Toggle
        :active="toggleActive"
        :loading="toggleLoading"
        label="Loading"
        @toggle="fireToggleLoading"
      />
      <Toggle :active="toggleActive" label="Disabled" disabled />
      <Toggle :active="toggleActive" label="Inline" inline />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Error States</Heading>
  <p>
    Fields validated on mount, so the invalid styling shows without interaction.
    The message itself lives in each field's tooltip.
  </p>
  <ErrorStates />

  <Heading :level="HeadingLevelEnum.H2">FormActions</Heading>
  <p>
    The submit/cancel footer. Submitting spins the save button; when
    <code>dirty</code> is set, cancel asks for confirmation first.
  </p>
  <form id="visual-tests-form" @submit.prevent="onSubmit">
    <FormActions
      form-id="visual-tests-form"
      :submitting="submitting"
      dirty
      @cancel="onCancel"
    />
  </form>
  <form id="visual-tests-form-no-cancel" @submit.prevent="onSubmit">
    <FormActions
      form-id="visual-tests-form-no-cancel"
      :submitting="submitting"
      hide-cancel
    />
  </form>
</template>
