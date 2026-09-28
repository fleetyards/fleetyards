import type { Fleet } from "@/services/fyApi";

// What RSI prints as an organisation's SID: up to ten capitals and digits.
const SID_FORMAT = /^[A-Z0-9]{1,10}$/;

// A fleet ID shaped like an SID could belong to the RSI organisation that
// carries it, and that organisation can claim it by verifying its own fleet.
// Only a fleet verified for that exact SID holds it for sure.
export const fidAtRisk = (
  fleet: Pick<Fleet, "fid" | "rsiSid" | "rsiVerified">,
) => {
  const sid = fleet.fid?.toUpperCase();
  if (!sid || !SID_FORMAT.test(sid)) return false;

  return !(fleet.rsiVerified && fleet.rsiSid === sid);
};
