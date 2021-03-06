##
# Represents TrackerInfo class
# contains info about tracer and generates tracker params
#
class TrackerInfo
  attr_reader :min_interval, :tracker_id, :peers
  attr_reader :complete, :incomplete
  TRACKER_EVENT = { started: 'started',
                    completed: 'completed',
                    stopped: 'stopped' }.freeze

  # create peer_id in Azureus-style
  # see https://wiki.theory.org/BitTorrentSpecification#peer_id for reference
  CLIENT_ID = '-UT3130-112233000000'.freeze

  def initialize(min_interval, tracker_id, complete, incomplete, peers)
    @min_interval = min_interval
    @tracker_id = tracker_id
    @complete = complete
    @incomplete = incomplete
    @peers = peers
  end

  # returns Hash of tracker params to send to uri
  # defined in the torrent file -- @meta_info.announce
  # @param [MetaInfo] meta_info instance of MetaInfo
  # @param [Fixnum] downloaded total number of bytes downloaded
  # @param [Symbol] event event sent to tracker.
  # If specified, must be one of started, completed, stopped
  def self.tracker_params(meta_info, downloaded, event)
    { info_hash: meta_info.info_hash,
      peer_id: CLIENT_ID,
      port: '6881',
      # should set total number of bytes uploaded (will track on seeding)
      # Keep hardcoded for now
      uploaded: '0',
      # should set total number of bytes downloaded
      downloaded: downloaded,
      # partial download after pause/interrupt is currently not supported
      left: meta_info.total_size - downloaded,
      compact: '1',
      no_peer_id: '0',
      event: TRACKER_EVENT[event] }
  end
end
