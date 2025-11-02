# frozen_string_literal: true

# RSwag用のカスタムパターン設定
# モジュラーモノリス構造に対応
Rake::Task["rswag:specs:swaggerize"].clear if Rake::Task.task_defined?("rswag:specs:swaggerize")

namespace :rswag do
  namespace :specs do
    desc "Generate Swagger from integration specs (including packages)"
    RSpec::Core::RakeTask.new(:swaggerize) do |t|
      t.pattern = [
        "spec/requests/**/*_spec.rb",
        "spec/api/**/*_spec.rb",
        "spec/integration/**/*_spec.rb",
        "app/packages/**/spec/integration/**/*_spec.rb"
      ].join(",")
      t.rspec_opts = [ "--format Rswag::Specs::SwaggerFormatter", "--dry-run", "--order defined" ]
    end
  end
end
