# encoding: UTF-8

$: << File.dirname(__FILE__) + "/../lib"

require "em-ws-client"

EM.run do

  $current = 1
  $count = 0


  def agent
    "em-ws-client/#{EM::WebSocketClient::Version}"
  end

  def report
    puts "Updating reports and shutting down"
    ws = EM::WebSocketClient.new "ws://localhost:9001/updateReports?agent=#{agent}"
    ws.onclose do
      EM.stop
    end
  end

  def next_test
    if $current > $count
      report
    else
      #puts "Running test case #{$current} of #{$count}"
      ws = EM::WebSocketClient.new "ws://localhost:9001/runCase?&case=#{$current}&agent=em-ws-client"
      ws.onmessage do |data, binary|
        begin
          ws.send_data data, binary
        rescue Exception => err
          $count = 0
          puts err
          puts err.backtrace
        end
      end

      ws.onping do |data|
        #ws.close 1000
      end

      ws.onerror do |code, message|
        #puts "Error: #{code} - #{message}"
      end

      ws.onpong do |data|
        #ws.close 1000
      end

      ws.onclose do
        $current += 1
        EM.next_tick do
          next_test
        end
      end
    end
  end

  def first
    # Establish the connection
    ws = EM::WebSocketClient.new("ws://localhost:9001/getCaseCount")

    ws.onopen do
      puts "Prepping"
    end

    ws.onclose do
      puts "Starting #{$count} tests"
      if $count > 0
        EM.next_tick do
          next_test
        end
        ws = nil
      end
    end

    ws.onmessage do |msg|
      $count = msg.to_i
    end
  end

  first

  trap("SIGINT") do 
    EM.next_tick { 
      report
    }
  end


end