##
# Describes PrettyLog class and its methods
# used for colored logging
#
class PrettyLog
  def self.single_line_log(message)
    print " #{message} "
    print "\\\r"
    print "|\r"
    print "/\r"
  end

  def self.error(message)
    colored(message, 31)
  end

  def self.info(message)
    colored(message, 32)
  end

  def self.colored(message, color_code)
    puts "\e[#{color_code}m#{message}\e[0m"
  end
end
