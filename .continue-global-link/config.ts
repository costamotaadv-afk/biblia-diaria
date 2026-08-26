export function modifyConfig(config: Config): Config {
  // Continue 2.0.0 does not reliably preserve Responses API reasoning items
  // between tool calls. Force OpenAI models to use Chat Completions until the
  // upstream fix is available.
  config.models = config.models.map((model) => {
    if (model.provider !== "openai") {
      return model;
    }

    return {
      ...model,
      useResponsesApi: false,
    };
  });

  return config;
}