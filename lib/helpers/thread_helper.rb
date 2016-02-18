require 'thread'

module ThreadHelper

  def join_thread_list
    Thread.list.each { |thread| thread.join unless thread == Thread.current }
  end

end