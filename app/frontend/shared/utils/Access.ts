export const checkAccess = (
  resourceAccess?: string[],
  access?: string[],
): boolean => {
  if (!access || !access.length || access.includes("all")) {
    return true;
  }

  if (!resourceAccess || !resourceAccess.length) {
    return false;
  }

  return access.some((privilege) => {
    return resourceAccess.includes(privilege);
  });
};

// A route's `meta.feature` is one flag or several stacked ones -- a fleet's
// tours need the tours feature *and* the fleet one -- and a stack is only
// satisfied when every flag in it is on.
export const checkFeatures = <T extends string>(
  feature: T | T[] | undefined,
  isEnabled: (feature: T) => boolean,
): boolean => {
  if (!feature) {
    return true;
  }

  const features: T[] = Array.isArray(feature) ? feature : [feature];

  return features.every((entry) => isEnabled(entry));
};
