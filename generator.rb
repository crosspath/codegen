module Generator
  module_function

  @actions = []

  def add_actions(&block)
    @actions << block
  end

  def run_all(answers)
    @actions.each { |x| x.call(answers) }
  end
end
