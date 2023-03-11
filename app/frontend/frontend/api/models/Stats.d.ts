type TQuickStats = {
  total: number;
};

type TChartStats = {
  name: string;
  y: number;
  selected?: boolean;
  sliced?: boolean;
};

type TBarChartStats = {
  label: string;
  count: number;
  tooltip: string;
};
