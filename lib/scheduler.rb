class Scheduler
  # This value should normally be 2^14 (16384) bytes. Smaller values may be used
  # but are usually not needed except in rare cases like a piece
  # length not divisible by 16384.

  # The observant reader will note that a block is typically smaller than a
  # piece (which is commonly >= 2^18 bytes). A client may close the connection
  # if it receives a request for more than 16384 bytes.
  BLOCK_SIZE = 2**14 # 16384

  PENDING_AMOUNT = 20 # increase if poor internet quality

  attr_reader :request_queue

  def initialize(peers, meta_info)
    @peers = peers
    @meta_info = meta_info
    @block_requests = Queue.new
    @request_queue = Queue.new

    store!
    assign_requests
  end

  def assign_requests
    @peers.each do |peer|
      PENDING_AMOUNT.times { assign_request(peer, @block_requests.pop) }
    end
  end

  def store!
    (0...pieces_count - 1).each do |piece_num|
      (0..blocks_in_piece_count - 1).each do |block_num|
        store_request(piece_num, block_offset(block_num), BLOCK_SIZE)
      end
    end

    # last piece
    (0...blocks_in_last_piece_count).each do |block_num|
      store_request(pieces_count - 1, block_offset(block_num), BLOCK_SIZE)
    end

    # last block
    store_request(pieces_count - 1, last_block_offset, last_block_size)
  end

  def store_request(index, offset, size)
    @block_requests.push(index: index, offset: offset, size: size)
  end

  def assign_request(peer, request)
    peer.pending_requests << request
    @request_queue.push(assign_peer(peer, request))
  end

  def process(incoming_block)
    request = next_request
    enqueue_request(incoming_block, request) if request
  end

  def next_request
    if @block_requests.empty?
      oldest_pending_request
    else
      @block_requests.pop
    end
  end

  def enqueue_request(incoming_block, request)
    incoming_block.peer.pending_requests << request
    @request_queue.push(assign_peer(incoming_block.peer, request))
  end

  def oldest_pending_request
    slowest_peer = @peers.sort_by { |peer| peer.pending_requests.length }.first
    slowest_peer.pending_requests.last
  end

  def assign_peer(peer, request)
    { connection: peer.connection,
      index: request[:index],
      offset: request[:offset],
      size: request[:size] }
  end

  def pieces_count
    (@meta_info.total_size.to_f / @meta_info.piece_length).ceil
  end

  def last_block_size
    @meta_info.total_size % BLOCK_SIZE
  end

  def full_blocks_count
    @meta_info.total_size / BLOCK_SIZE
  end

  def blocks_in_piece_count
    (@meta_info.piece_length.to_f / BLOCK_SIZE).ceil
  end

  def blocks_in_last_piece_count
    full_blocks_count % blocks_in_piece_count
  end

  def last_block_offset
    BLOCK_SIZE * blocks_in_last_piece_count
  end

  def block_offset(block_num)
    BLOCK_SIZE * block_num
  end
end
