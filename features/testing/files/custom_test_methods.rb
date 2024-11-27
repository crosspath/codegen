# frozen_string_literal: true

module CustomTestMethods
  def json
    @json ||= JSON.parse(response.body, symbolize_names: true)
  end

  def spec
    @spec ||= self.class.parent_groups.last
  end

  def spec_class
    @spec_class ||= spec.metadata[:described_class] || spec.metadata[:description].constantize
  end
end
