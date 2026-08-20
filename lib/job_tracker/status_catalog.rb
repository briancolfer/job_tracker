require "tempfile"
require "yaml"

module JobTracker
  class StatusCatalog
    class ValidationError < StandardError; end

    CODE_PATTERN = /\A[a-z][a-z0-9_]*\z/

    class << self
      def config_path
        Rails.root.join("config/job_statuses.yml")
      end

      def definitions(path: config_path)
        raw = YAML.safe_load_file(path, permitted_classes: [], aliases: false)
        raise ValidationError, "Status catalog must be a mapping" unless raw.is_a?(Hash)

        raw.each_with_object({}) do |(code, attributes), result|
          result[code.to_s] = attributes.transform_keys(&:to_s)
        end
      rescue Errno::ENOENT
        raise ValidationError, "Status catalog not found: #{path}"
      end

      def definition(code, path: config_path)
        definitions(path: path)[code.to_s]
      end

      def codes(path: config_path)
        definitions(path: path).keys
      end

      def enum_mapping(path: config_path)
        definitions(path: path).transform_values { |attributes| attributes.fetch("value") }
      end

      def default_code(path: config_path)
        code, = definitions(path: path).find { |_status_code, attributes| attributes["default"] }
        raise ValidationError, "Status catalog must define one default status" unless code

        code
      end

      def terminal_codes(path: config_path)
        definitions(path: path).filter_map do |code, attributes|
          code if attributes["terminal"]
        end
      end

      def label(code, path: config_path)
        definition(code, path: path)&.fetch("label", nil) || code.to_s.humanize
      end

      def options(path: config_path)
        definitions(path: path).map { |code, attributes| [ attributes.fetch("label"), code ] }
      end

      def add(code, label:, terminal: false, path: config_path)
        status_code = code.to_s
        validate_code!(status_code)
        validate_label!(label)

        current = definitions(path: path)
        raise ValidationError, "Status '#{status_code}' already exists" if current.key?(status_code)

        current[status_code] = {
          "value" => current.values.map { |attributes| attributes.fetch("value") }.max.to_i + 1,
          "label" => label.strip,
          "terminal" => !!terminal
        }
        write(current, path: path)
        current.fetch(status_code)
      end

      def update(code, new_code: nil, label: nil, terminal: nil, path: config_path)
        status_code = code.to_s
        current = definitions(path: path)
        attributes = current[status_code]
        raise ValidationError, "Status '#{status_code}' not found" unless attributes

        target_code = new_code.presence || status_code
        validate_code!(target_code)
        validate_label!(label) unless label.nil?
        if target_code != status_code && current.key?(target_code)
          raise ValidationError, "Status '#{target_code}' already exists"
        end
        if target_code == status_code && label.nil? && terminal.nil?
          raise ValidationError, "Specify --new-code, --label, --terminal, or --no-terminal"
        end

        updated_attributes = attributes.merge(
          "label" => label.nil? ? attributes.fetch("label") : label.strip,
          "terminal" => terminal.nil? ? attributes.fetch("terminal", false) : !!terminal
        )
        updated = current.each_with_object({}) do |(existing_code, existing_attributes), result|
          if existing_code == status_code
            result[target_code] = updated_attributes
          else
            result[existing_code] = existing_attributes
          end
        end

        write(updated, path: path)
        updated.fetch(target_code)
      end

      private

      def validate_code!(code)
        return if CODE_PATTERN.match?(code)

        raise ValidationError, "Status code must use lowercase snake_case"
      end

      def validate_label!(label)
        return if label.to_s.strip.present?

        raise ValidationError, "Display label is required"
      end

      def write(content, path:)
        path = Pathname(path)
        Tempfile.create([ "job_statuses", ".yml" ], path.dirname) do |temporary_file|
          temporary_file.write(YAML.dump(content))
          temporary_file.flush
          temporary_file.fsync
          temporary_file.close
          File.rename(temporary_file.path, path)
        end
      end
    end
  end
end
