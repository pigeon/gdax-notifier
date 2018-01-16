#!/usr/bin/env ruby
require 'coinbase/exchange'
require 'faraday'
require 'json'
require 'yaml'
require 'telegram/bot'


#require './../environment.rb'
#require 'pry'

class Notifier
  def initialize(seconds)
    @rest_api = Coinbase::Exchange::Client.new(
      ENV['GDAX_API_KEY'],
      ENV['GDAX_API_SECRET'],
      ENV['GDAX_API_PASS']
    )

    @telegram_token = ENV['TELEGRAM_TOKEN']

    #@maker_event = ENV.fetch('MAKER_EVENT')
    #@maker_key = ENV.fetch('MAKER_KEY')
    @fill_cache = create_fill_cache(seconds)
  end

  def create_fill_cache(seconds)
    fills(Time.now.utc - seconds).map { |m| m['order_id'] }
  end

  def fills(start_date = Time.now.utc)
    @rest_api.fills(start_date: start_date)
  end

  # test function to make sure telegram can send messages
  def poll2(frequency = 1)
     @rest_api.accounts do |resp|
        resp.each do |account|
          send_notification("#{account.id}: %.2f #{account.currency} available for trading" % account.available)
        end
     end
  end

  def poll(frequency = 1)
    while true
      check_seconds = frequency * 60 * 60
      fills(Time.now.utc - check_seconds).each do |fill|
        next if @fill_cache.include? fill['order_id']

        puts fill['order_id']
        @fill_cache << fill['order_id']
        send_notification(compile_message(fill))
      end
      sleep(frequency)
    end
  end

  def compile_message(fill)
      product_id = fill['product_id']
      side = fill['side'].capitalize
      size = fill['size'].to_f.round(2)
      price = fill['price'].to_f.round(4)
      info = "GDAX #{product_id} #{side} #{size} @ #{price}"
      return info
      #send_notification(info)
  end

def list_of_customers(path) 
  parsed = begin
    YAML.load(File.open(path))

  rescue Errno::ENOENT => e
    puts "Could not parse YAML: #{e.message}"
  end  
end

  def send_notification(info)


      path = File.join(Dir.pwd,"users.yml")  


      customers = list_of_customers(path)

      if customers == nil 
        return
      end

      customers.each do |id,customer|

        Telegram::Bot::Client.run(@telegram_token) do |bot|
          bot.api.send_message(chat_id: id, text: info)
          puts info
        end
      end
  end 

  # def send_notification(fill)
  #   product_id = fill['product_id']
  #   side = fill['side'].capitalize
  #   size = fill['size'].to_f.round(2)
  #   price = fill['price'].to_f.round(4)
  #   info = "#{size} @ #{price}"
  #   puts info

    # conn = Faraday.new('https://maker.ifttt.com/')
    # conn.post do |req|
    #   req.url "/trigger/#{@maker_event}/with/key/#{@maker_key}"
    #   req.headers['Content-Type'] = 'application/json'
    #   req.body = {
    #     value1: product_id,
    #     value2: side,
    #     value3: info
    #   }.to_json
    # end
#  end
end
