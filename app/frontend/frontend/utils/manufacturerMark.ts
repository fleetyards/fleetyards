import { type Manufacturer } from "@/services/fyApi";

// The icon before the logo: the export's square mark sits at a small size where
// a curated wordmark does not. A vector carries only `url`.
export const manufacturerMark = (manufacturer?: Manufacturer) => {
  const { icon, logo } = manufacturer ?? {};

  return icon?.smallUrl || icon?.url || logo?.smallUrl || logo?.url;
};
