module TestHelper
  def self.read(file, start, length)
    file.seek(start)
    file.read(length)
  end
end
