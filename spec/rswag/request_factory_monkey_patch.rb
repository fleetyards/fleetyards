# frozen_string_literal: true

# Patch based on https://github.com/rswag/rswag/pull/397/files
Rswag::Specs::RequestFactory.class_eval do
  def add_path(request, metadata, swagger_doc, parameters, example)
    template = if doc_version(swagger_doc).start_with?("2")
      (swagger_doc[:basePath] || "")
    else
      base_path_from_servers(swagger_doc)
    end

    template += metadata[:path_item][:template]

    request[:path] = template.tap do |path_template|
      parameters.select { |p| p[:in] == :path }.each do |p|
        path_template.gsub!("{#{p[:name]}}", example.send(p[:name]).to_s)
      end

      parameters.select { |p| p[:in] == :query }.each_with_index do |p, i|
        path_template.concat(i.zero? ? "?" : "&")
        path_template.concat(build_query_string_part(p, example.send(p[:name])))
      end
    end
  end

  def base_path_from_servers(swagger_doc)
    return "" unless swagger_doc.key?(:servers)

    server = swagger_doc[:servers].first

    variables = {}
    server.fetch(:variables, {}).each_pair do |k, v|
      variables[k] = v[:default]
    end

    url = server[:url].gsub(/\{(.*?)\}/) { variables[Regexp.last_match(1).to_sym] }
    URI(url).path
  end
end
