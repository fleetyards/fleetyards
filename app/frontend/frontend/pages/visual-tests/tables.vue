<script lang="ts">
export default {
  name: "VisualTestsTablesPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import BaseTable2 from "@/shared/components/base/Table2/index.vue";
import { type BaseTableCol as BaseTableCol2 } from "@/shared/components/base/Table2/types";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { displaySuccess } = useAppNotifications();

type TestRecord = {
  name: string;
  description: string;
  age: number;
  email: string;
};

const records = [
  {
    name: "John Doe",
    description: "Software Engineer",
    age: 30,
    email: "john.doe@example.com",
  },
  {
    name: "Jane Smith",
    description: "Product Manager",
    age: 25,
    email: "jane.smith@example.com",
  },
  {
    name: "Alice Johnson",
    description: "UX Designer",
    age: 35,
    email: "alice.johnson@example.com",
  },
  {
    name: "Bob Brown",
    description: "Data Scientist",
    age: 40,
    email: "bob.brown@example.com",
  },
  {
    name: "Charlie White",
    description: "DevOps Engineer",
    age: 28,
    email: "charlie.white@example.com",
  },
  {
    name: "Diana Green",
    description: "QA Engineer",
    age: 32,
    email: "diana.green@example.com",
  },
] as TestRecord[];

const columns = [
  {
    name: "name",
    label: "Name",
    width: "30%",
    attributeKey: "name",
  },
  {
    name: "description",
    label: "Description",
    attributeKey: "description",
  },
  {
    name: "age",
    label: "Age",
    attributeKey: "age",
  },
  { name: "email", label: "Email", sortable: true, attributeKey: "email" },
] as BaseTableCol<TestRecord>[];

const columns2 = [
  {
    name: "name",
    label: "Name",
    width: "30%",
    attributeKey: "name",
  },
  {
    name: "description",
    label: "Description",
    attributeKey: "description",
  },
  {
    name: "age",
    label: "Age",
    attributeKey: "age",
  },
  { name: "email", label: "Email", sortable: true, attributeKey: "email" },
] as BaseTableCol2<TestRecord>[];
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Base Table</Heading>
  <div class="row">
    <div class="col-12">
      <BaseTable
        id="basic-table"
        :columns="columns"
        primary-key="email"
        title="Basic Table"
        :records="records"
        selectable
      >
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-age="{ record }"> {{ record.age }} years </template>
        <template #col-email="{ record }">
          <a :href="'mailto:' + record.email">{{ record.email }}</a>
        </template>
        <template #actions="{ record }">
          <Btn
            size="small"
            inline
            @click="displaySuccess({ text: `Edit ${record.name}` })"
          >
            <i class="fa fa-edit" />
          </Btn>
        </template>
      </BaseTable>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseTable
        id="basic-table-empty"
        :columns="columns"
        primary-key="email"
        title="Basic Table | Empty"
        :records="[]"
        empty-visible
        :loading="false"
        selectable
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseTable
        id="basic-table-loading"
        :columns="columns"
        primary-key="email"
        title="Basic Table | Loading"
        :records="[]"
        loading
        selectable
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseTable
        id="basic-table-without-selection"
        :columns="columns"
        primary-key="email"
        title="Basic Table | Without Selection"
        :records="records"
        :selectable="false"
      >
        <template #actions="{ record }">
          <Btn
            size="small"
            inline
            @click="displaySuccess({ text: `Edit ${record.name}` })"
          >
            <i class="fa fa-edit" />
          </Btn>
        </template>
      </BaseTable>
    </div>
  </div>
  <hr />
  <Heading :level="HeadingLevelEnum.H2">Base Table 2</Heading>
  <div class="row">
    <div class="col-12">
      <BaseTable2
        id="basic-table2"
        :columns="columns2"
        primary-key="email"
        title="Basic Table 2"
        :records="records"
        selectable
      >
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-age="{ record }"> {{ record.age }} years </template>
        <template #col-email="{ record }">
          <a :href="'mailto:' + record.email">{{ record.email }}</a>
        </template>
        <template #actions="{ record }">
          <Btn
            size="small"
            inline
            @click="displaySuccess({ text: `Edit ${record.name}` })"
          >
            <i class="fa fa-edit" />
          </Btn>
        </template>
      </BaseTable2>
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseTable2
        id="basic-table2-empty"
        :columns="columns2"
        primary-key="email"
        title="Basic Table 2 | Empty"
        :records="[]"
        empty-visible
        selectable
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseTable2
        id="basic-table2-loading"
        :columns="columns2"
        primary-key="email"
        title="Basic Table 2 | Loading"
        :records="[]"
        loading
        selectable
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseTable2
        id="basic-table2-without-selection"
        :columns="columns2"
        primary-key="email"
        title="Basic Table 2 | Without Selection"
        :records="records"
      >
        <template #actions="{ record }">
          <Btn
            size="small"
            inline
            @click="displaySuccess({ text: `Edit ${record.name}` })"
          >
            <i class="fa fa-edit" />
          </Btn>
        </template>
      </BaseTable2>
    </div>
  </div>
</template>
