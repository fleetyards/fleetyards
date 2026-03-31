import { request } from "@playwright/test";
import config from "../../../playwright.config";

const contextPromise = request.newContext({
  baseURL: config.use ? config.use.baseURL : "http://127.0.0.1:8280",
});

const appCommands = async (data) => {
  const context = await contextPromise;
  const response = await context.post("/__e2e__/command", { data });

  if (!response.ok()) {
    const body = await response.text();
    throw new Error(
      `/__e2e__/command failed with status ${response.status()}: ${body}`,
    );
  }
  return response.json();
};

const app = (name, options = {}) =>
  appCommands({ name, options }).then((body) => body[0]);
const appScenario = (name, options = {}) => app("scenarios/" + name, options);
const appEval = (code) => app("eval", code);
const appFactories = (options) => app("factory_bot", options);

export { appCommands, app, appScenario, appEval, appFactories };
