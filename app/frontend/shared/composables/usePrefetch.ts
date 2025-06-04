const getByKey = function getByKey(key: string) {
  return (window.DATA_PREFETCH || {})[key];
};

const cleanData = function cleanData(key: string) {
  if (!window.DATA_PREFETCH || !window.DATA_PREFETCH[key]) {
    return;
  }
  window.DATA_PREFETCH[key] = null;
};

const keyExists = function keyExists(key: string) {
  return !!(window.DATA_PREFETCH && window.DATA_PREFETCH[key]);
};

const fetchData = function fetchData<T>(key: string): T | undefined {
  const json = getByKey(key);

  cleanData(key);

  if (!json) {
    return undefined;
  }

  const element = JSON.parse(json) as T;

  return element;
};

export const usePrefetch = () => {
  return {
    keyExists,
    fetchData,
  };
};
