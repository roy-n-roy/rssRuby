#!/usr/bin/ruby
require 'uri'
require 'oauth'
require 'net/https'
require 'net/http'
require 'pp'
require 'json'
require 'rubygems'
require './accessToken_Pocket.rb'

class PocketPost
    include AccessToken_Pocket

    def initialize 
        @uri = URI.parse("https://getpocket.com/v3/add")
        @https = Net::HTTP.new(@uri.host,@uri.port)
        @https.use_ssl = true
        @https.ca_file = "./cacert.pem"
        @https.verify_depth = 5
        @https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    def post(url, title)
                
        @https.start do |hs|
            request = Net::HTTP::Post.new(@uri.request_uri)
            request["Content-Type"] = "application/json; charset=UTF-8"
            request["X-Accept"] = "application/json"
            request.body = { url: url, title: title, 
               consumer_key: CONSUMERKEY_POCKET,
               access_token: ACCESSTOKEN_POCKET
                }.to_json
            hs.request(request) do |response|
                response.read_body do |chunk|
                    #puts chunk
                end
                #puts response
            end
        end

    end
end
