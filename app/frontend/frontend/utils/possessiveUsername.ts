export const possessiveUsername = (username: string) => {
  const title = username[0].toUpperCase() + username.slice(1);

  if (title.endsWith("s") || title.endsWith("x") || title.endsWith("z")) {
    return title;
  }

  return `${title}'s`;
};
