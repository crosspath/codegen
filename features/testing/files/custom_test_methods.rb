module CustomTestMethods
  def json
    @json ||= JSON.parse(response.body, symbolize_names: true)
  end
end
