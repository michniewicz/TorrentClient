class TrackerInfo
  attr_reader :min_interval, :tracker_id, :complete, :incomplete, :peers, :failure_reason

  def initialize(min_interval, tracker_id, complete, incomplete, peers, failure_reason)
    @min_interval = min_interval
    @tracker_id = tracker_id
    @complete = complete
    @incomplete = incomplete
    @peers = peers
    @failure_reason = failure_reason
  end
end