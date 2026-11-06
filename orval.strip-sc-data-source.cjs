const REFERENCE = "#/components/parameters/ScDataSourceParameter";

module.exports = (spec) => {
  for (const pathItem of Object.values(spec.paths ?? {})) {
    if (!pathItem.parameters) continue;

    pathItem.parameters = pathItem.parameters.filter(
      (parameter) => parameter.$ref !== REFERENCE,
    );

    if (!pathItem.parameters.length) delete pathItem.parameters;
  }

  delete spec.components?.parameters?.ScDataSourceParameter;

  return spec;
};
