import { RsiHandleVerifiedViaEnum } from "@/services/fyApi";

// A handle proved through Citizen iD is badged by the link to its Citizen iD
// profile; one proved through the RSI bio has no profile to link to, so it is
// badged by this instead.
export const handleVerifiedViaProfile = (record: {
  rsiHandleVerifiedVia?: RsiHandleVerifiedViaEnum;
}) => record.rsiHandleVerifiedVia === RsiHandleVerifiedViaEnum.RSI_PROFILE;
