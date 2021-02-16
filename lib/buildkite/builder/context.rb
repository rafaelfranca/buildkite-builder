module Buildkite
  module Builder
    class Context
      include Definition::Helper

      PIPELINE_DEFINITION_FILE = Pathname.new('pipeline.rb').freeze

      attr_reader :logger
      attr_reader :root
      attr_reader :pipeline

      def self.build(root, logger: nil)
        context = new(root, logger: logger)
        context.build
        context
      end

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
      end

      def build
        unless @pipeline
          @pipeline = Pipelines::Pipeline.new

          load_manifests
          load_templates
          load_processors
          load_pipeline
          run_processors
        end

        @pipeline
      end

      private

      def load_manifests
        Loaders::Manifests.load(root).each do |name, asset|
          Manifest[name] = asset
        end
      end

      def load_templates
        Loaders::Templates.load(root).each do |name, asset|
          pipeline.template(name, &asset)
        end
      end

      def load_processors
        Loaders::Processors.load(root)
      end

      def run_processors
        pipeline.processors.each do |processor|
          processor.process(self)
        end
      end

      def load_pipeline
        pipeline.instance_eval(&pipeline_definition)
      end

      def pipeline_definition
        @pipeline_definition ||= load_definition(root.join(PIPELINE_DEFINITION_FILE), Definition::Pipeline)
      end
    end
  end
end