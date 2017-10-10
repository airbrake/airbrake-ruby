module Helpers
  def fixture_path(filename)
    File.expand_path(File.join('spec', 'fixtures', filename))
  end
end
