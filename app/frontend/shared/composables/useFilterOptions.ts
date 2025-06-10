import { useI18n } from "@/shared/composables/useI18n";

export const useFilterOptions = () => {
  const { t } = useI18n();

  const booleanOptions = [
    {
      label: t("labels.false"),
      value: "false",
    },
    {
      label: t("labels.true"),
      value: "true",
    },
  ];

  const priceOptions = [
    {
      value: "-200000",
      label: `< 200K ${t("labels.uec")}`,
    },
    {
      value: "200000-500000",
      label: `200K ${t("labels.uec")} - 500K ${t("labels.uec")}`,
    },
    {
      value: "500000-2000000",
      label: `500K ${t("labels.uec")} - 2M ${t("labels.uec")}`,
    },
    {
      value: "2000000-10000000",
      label: `2M ${t("labels.uec")} - 10M ${t("labels.uec")}`,
    },
    {
      value: "10000000-25000000",
      label: `10M ${t("labels.uec")} - 25M ${t("labels.uec")}`,
    },
    {
      value: "25000000-50000000",
      label: `25M ${t("labels.uec")} - 50M ${t("labels.uec")}`,
    },
    {
      value: "50000000-100000000",
      label: `50M ${t("labels.uec")} - 100M ${t("labels.uec")}`,
    },
    {
      value: "100000000-250000000",
      label: `100M ${t("labels.uec")} - 250M ${t("labels.uec")}`,
    },
    {
      value: "250000000-500000000",
      label: `250M ${t("labels.uec")} - 500M ${t("labels.uec")}`,
    },
    {
      value: "500000000-1000000000",
      label: `500M ${t("labels.uec")} - 1B ${t("labels.uec")}`,
    },
  ];

  const pledgePriceOptions = [
    {
      value: "-25",
      label: "< $25",
    },
    {
      value: "25-50",
      label: "$25 - $49",
    },
    {
      value: "50-75",
      label: "$50 - $74",
    },
    {
      value: "75-100",
      label: "$75 - $99",
    },
    {
      value: "100-150",
      label: "$100 - $149",
    },
    {
      value: "150-200",
      label: "$150 - $199",
    },
    {
      value: "200-350",
      label: "$200 - $349",
    },
    {
      value: "350-500",
      label: "$350 - $499",
    },
    {
      value: "500-1000",
      label: "$500 - $999",
    },
    {
      value: "1000-",
      label: "> $1000",
    },
  ];

  return {
    booleanOptions,
    priceOptions,
    pledgePriceOptions,
  };
};
