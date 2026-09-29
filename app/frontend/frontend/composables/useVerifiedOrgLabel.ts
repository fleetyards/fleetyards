import { useIntervalFn, useNow } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";

type VerifiedOrgMember = {
  verifiedOrgSid?: string;
  verificationCheckedAt?: string;
};

// The shield's tooltip, on the avatar and beside the name alike. Saying when
// the org list was last read lets a manager judge how fresh the claim is.
export const useVerifiedOrgLabel = () => {
  const { t, timeDistance } = useI18n();

  // Read inside the label, so a roster left open keeps the age current.
  const now = useNow({ scheduler: (tick) => useIntervalFn(tick, 60_000) });

  return (member: VerifiedOrgMember) => {
    if (!member.verifiedOrgSid) return undefined;

    return member.verificationCheckedAt && now.value
      ? t("labels.fleet.members.verifiedOrgMemberChecked", {
          sid: member.verifiedOrgSid,
          checked: timeDistance(member.verificationCheckedAt),
        })
      : t("labels.fleet.members.verifiedOrgMember", {
          sid: member.verifiedOrgSid,
        });
  };
};
