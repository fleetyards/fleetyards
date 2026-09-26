<script lang="ts">
export default {
  name: "FleetEventEditSchedulePage",
};
</script>

<script lang="ts" setup>
import { useForm, type SubmissionHandler } from "vee-validate";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { BaseSelectVariantsEnum } from "@/shared/components/base/Select/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import EventEditFormShell from "@/frontend/components/Fleets/Events/EventEditFormShell/index.vue";
import {
  type Fleet,
  type FilterOption,
  type FleetEventExtended,
  type FleetEventUpdateInput,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { TIMEZONE_OPTIONS } from "@/shared/utils/Timezones";
import {
  useRecurrence,
  WEEKDAYS_MONDAY_FIRST,
} from "@/frontend/composables/useRecurrence";
import { format, parseISO } from "date-fns";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { weekdayName } = useRecurrence();

const LOCAL_FORMAT = "yyyy-MM-dd'T'HH:mm";

const toLocal = (iso: string | null | undefined) => {
  if (!iso) return "";
  try {
    return format(parseISO(iso), LOCAL_FORMAT);
  } catch {
    return "";
  }
};

const MAX_RECURRENCE_EVERY = 99;

// The weekday an instant falls on in the event's zone rather than the
// browser's: that is the day the server always adds to the pattern.
const wdayIn = (value: string | undefined, zone: string | undefined) => {
  if (!value) return null;
  const date = new Date(value);
  if (isNaN(date.getTime())) return null;
  try {
    const name = new Intl.DateTimeFormat("en-US", {
      weekday: "short",
      timeZone: zone || "UTC",
    }).format(date);
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].indexOf(name);
  } catch {
    return date.getDay();
  }
};

// The start day is implied rather than chosen, so it is left out of the
// selection: moving the start then moves that day with it.
const initialStartWday = wdayIn(props.event.startsAt, props.event.timezone);

const validationSchema = {
  startsAt: "required",
  timezone: "required",
  recurrenceEvery: `required|between:1,${MAX_RECURRENCE_EVERY}`,
};

const { defineField, handleSubmit, meta, setErrors } =
  useForm<FleetEventUpdateInput>({
    initialValues: {
      startsAt: toLocal(props.event.startsAt) as never,
      endsAt: toLocal(props.event.endsAt) as never,
      timezone: props.event.timezone,
      recurring: props.event.recurring ?? false,
      recurrenceInterval: (props.event.recurrenceInterval ?? "weekly") as never,
      recurrenceUntil: props.event.recurrenceUntil ?? null,
      recurrenceCount: props.event.recurrenceCount ?? null,
      recurrenceEvery: props.event.recurrenceEvery ?? 1,
      recurrenceWeekdays: (props.event.recurrenceWeekdays ?? []).filter(
        (wday) => wday !== initialStartWday,
      ),
    },
    validationSchema,
  });

const [startsAt] = defineField("startsAt");
const [endsAt] = defineField("endsAt");
const [timezone, timezoneProps] = defineField("timezone");
const [recurring] = defineField("recurring");
const [recurrenceInterval, recurrenceIntervalProps] =
  defineField("recurrenceInterval");
const [recurrenceUntil] = defineField("recurrenceUntil");
const [recurrenceCount, recurrenceCountProps] = defineField("recurrenceCount");
const [recurrenceEvery] = defineField("recurrenceEvery");

const [recurrenceWeekdays] = defineField("recurrenceWeekdays");

const startWday = computed(() =>
  wdayIn(startsAt.value as string | undefined, timezone.value as string),
);

const weekdayChecked = (wday: number) =>
  wday === startWday.value || (recurrenceWeekdays.value ?? []).includes(wday);

const toggleWeekday = (wday: number) => {
  if (wday === startWday.value) return;
  const days = recurrenceWeekdays.value ?? [];
  recurrenceWeekdays.value = days.includes(wday)
    ? days.filter((day) => day !== wday)
    : [...days, wday];
};

const recurrenceEndKind = ref<"never" | "until" | "count">(
  props.event.recurrenceUntil
    ? "until"
    : props.event.recurrenceCount
      ? "count"
      : "never",
);

const recurrenceIntervalOptions = computed<FilterOption[]>(() =>
  ["daily", "weekly", "monthly"].map((value) => ({
    value,
    label: t(`labels.fleets.events.recurrenceUnit.${value}`),
  })),
);

const timezoneOptions = computed<FilterOption[]>(() => {
  const base = TIMEZONE_OPTIONS.map((tz) => ({
    value: tz.value,
    label: tz.label,
  }));
  const current = (timezone.value as string) || "";
  if (current && !base.some((opt) => opt.value === current)) {
    base.unshift({ value: current, label: current });
  }
  return base;
});

const addHours = (value: string, hours: number) => {
  if (!value) return "";
  const parsed = new Date(value);
  if (isNaN(parsed.getTime())) return "";
  parsed.setHours(parsed.getHours() + hours);
  return format(parsed, LOCAL_FORMAT);
};

// An end nobody has moved follows the start; once it has been set by hand it
// stops following, so editing the start does not overwrite a deliberate end.
let endsAtTouched = !!props.event.endsAt;
watch(endsAt, (newValue) => {
  const start = startsAt.value as string;
  if (!start || !newValue) return;
  if (newValue !== addHours(start, 2)) endsAtTouched = true;
});
watch(startsAt, (newStart) => {
  if (!newStart || endsAtTouched) return;
  endsAt.value = addHours(newStart as string, 2) as never;
});

// vee-validate hands back local datetime strings; the API wants ISO.
const wrapHandleSubmit = (cb: SubmissionHandler<FleetEventUpdateInput>) =>
  handleSubmit((values, ctx) => {
    const endKind = recurrenceEndKind.value;
    return cb(
      {
        ...values,
        startsAt: values.startsAt
          ? (new Date(values.startsAt as string).toISOString() as never)
          : undefined,
        endsAt: values.endsAt
          ? (new Date(values.endsAt as string).toISOString() as never)
          : null,
        recurring: !!values.recurring,
        recurrenceInterval: values.recurring
          ? (values.recurrenceInterval as never)
          : null,
        recurrenceUntil:
          values.recurring && endKind === "until"
            ? (values.recurrenceUntil as never)
            : null,
        recurrenceCount:
          values.recurring && endKind === "count"
            ? Number(values.recurrenceCount || 0) || null
            : null,
        recurrenceEvery: values.recurring
          ? Number(values.recurrenceEvery || 0) || 1
          : 1,
        recurrenceWeekdays:
          values.recurring && values.recurrenceInterval === "weekly"
            ? WEEKDAYS_MONDAY_FIRST.filter(weekdayChecked)
            : [],
      } as never,
      ctx,
    );
  });
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.events.editSchedule") }}</Heading>
  <EventEditFormShell
    :fleet="fleet"
    :event="event"
    :handle-submit="wrapHandleSubmit"
    :meta="meta"
    :set-errors="setErrors"
    form-id="fleet-event-edit-schedule"
  >
    <div class="row">
      <div class="col-12 col-md-6">
        <FormDateTime
          v-model="startsAt"
          name="startsAt"
          :rules="validationSchema.startsAt"
          :minutes-increment="15"
          :label="t('labels.fleets.events.startsAt')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormDateTime
          v-model="endsAt"
          name="endsAt"
          :minutes-increment="15"
          :label="t('labels.fleets.events.endsAt')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="timezone"
          v-bind="timezoneProps"
          :options="timezoneOptions"
          :label="t('labels.fleets.events.timezone')"
          name="timezone"
          :searchable="true"
        />
      </div>
    </div>

    <hr />

    <div class="row">
      <div class="col-12">
        <FormCheckbox
          v-model="recurring"
          name="recurring"
          :label="t('labels.fleets.events.recurring')"
        />
        <p class="text-muted small">
          {{ t("labels.fleets.events.recurringHint") }}
        </p>
      </div>
    </div>

    <template v-if="recurring">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput
            v-model="recurrenceEvery"
            name="recurrenceEvery"
            :rules="validationSchema.recurrenceEvery"
            :type="InputTypesEnum.NUMBER"
            :min="1"
            :max="MAX_RECURRENCE_EVERY"
            :step="1"
            :label="t('labels.fleets.events.recurrenceInterval')"
          >
            <template #suffix>
              <BaseSelect
                v-model="recurrenceInterval"
                v-bind="recurrenceIntervalProps"
                :options="recurrenceIntervalOptions"
                :variant="BaseSelectVariantsEnum.AFFIX"
                :label="t('labels.fleets.events.recurrenceInterval')"
                name="recurrenceInterval"
                :searchable="false"
                unsorted
                no-label
              />
            </template>
          </FormInput>
        </div>
      </div>

      <div v-if="recurrenceInterval === 'weekly'" class="row">
        <div class="col-12">
          <span class="text-muted small">
            {{ t("labels.fleets.events.recurrenceWeekdays") }}
          </span>
          <div class="weekday-picker" data-test="recurrence-weekdays">
            <Chip
              v-for="wday in WEEKDAYS_MONDAY_FIRST"
              :key="wday"
              :state="
                weekdayChecked(wday)
                  ? ChipStatesEnum.INCLUDED
                  : ChipStatesEnum.NEUTRAL
              "
              :disabled="wday === startWday"
              :data-test="`recurrence-weekday-${wday}`"
              @toggle="toggleWeekday(wday)"
            >
              {{ weekdayName(wday) }}
            </Chip>
          </div>
          <p class="text-muted small">
            {{ t("labels.fleets.events.recurrenceWeekdaysHint") }}
          </p>
        </div>
      </div>

      <div class="row">
        <div class="col-12">
          <span class="text-muted small">
            {{ t("labels.fleets.events.recurrenceEnd") }}
          </span>
          <div class="series-end">
            <label class="series-end__option">
              <input
                v-model="recurrenceEndKind"
                type="radio"
                name="recurrenceEndKind"
                value="never"
              />
              <span>{{ t("labels.fleets.events.recurrenceEndNever") }}</span>
            </label>
            <label class="series-end__option">
              <input
                v-model="recurrenceEndKind"
                type="radio"
                name="recurrenceEndKind"
                value="until"
              />
              <span>{{ t("labels.fleets.events.recurrenceEndOn") }}</span>
              <input
                v-model="recurrenceUntil"
                type="date"
                :disabled="recurrenceEndKind !== 'until'"
                class="series-end__input"
              />
            </label>
            <label class="series-end__option">
              <input
                v-model="recurrenceEndKind"
                type="radio"
                name="recurrenceEndKind"
                value="count"
              />
              <span>{{ t("labels.fleets.events.recurrenceEndAfter") }}</span>
              <input
                v-model.number="recurrenceCount"
                v-bind="recurrenceCountProps"
                type="number"
                min="1"
                :disabled="recurrenceEndKind !== 'count'"
                class="series-end__input series-end__input--narrow"
              />
              <span>{{
                t("labels.fleets.events.recurrenceEndOccurrences")
              }}</span>
            </label>
          </div>
        </div>
      </div>
    </template>
  </EventEditFormShell>
</template>

<style lang="scss" scoped>
.weekday-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 6px;
}

.series-end {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 6px;
}

.series-end__option {
  display: flex;
  gap: 8px;
  align-items: center;
  margin: 0;
  font-weight: normal;
}

.series-end__input {
  max-width: 180px;
}

.series-end__input--narrow {
  max-width: 90px;
}
</style>
