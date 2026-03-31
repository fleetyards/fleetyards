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
