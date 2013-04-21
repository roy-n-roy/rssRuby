#!/usr/bin/ruby
    require 'net/https'
    require 'rubygems'
    require 'uri'
    require 'oauth'
    require 'json'
    require 'pp'
    require '/home/pi/rss/access_token.rb'
    require '/home/pi/rss/pocket/pocketPost.rb'
module TwitterBot
    class Bot
        include AccessToken

        MY_SCREEN_NAME="zwranian_rss"
        BOT_USER_AGENT="rssRubyScript"
        HTTPS_CA_FILE_PATH="./verisign.cer"

        def initialize 
            @consumer = OAuth::Consumer.new(CONSUMER_KEY,
                                            CONSUMER_SECRET,
                                            :site => 'https://api.twitter.com'
                                            )
            @access_token = OAuth::AccessToken.new(@consumer,
                                                    ACCESS_TOKEN,
                                                    ACCESS_TOKEN_SECRET
                                                    )
            @pocketPost =PocketPost.new()
        end

        def connect 
            uri = URI.parse("https://userstream.twitter.com/1.1/user.json?track=#{MY_SCREEN_NAME}")
            
            https = Net::HTTP.new(uri.host, uri.port)
            https.use_ssl = true
            https.ca_file = HTTPS_CA_FILE_PATH
            https.verify_mode = OpenSSL::SSL::VERIFY_PEER
            https.verify_depth = 5
            
            https.start do |https|
                request = Net::HTTP::Get.new(uri.request_uri)
                request["User-Agent"] = BOT_USER_AGENT
                request.oauth!(https,@consumer,@access_token)

                buf=""
                https.request(request) do |response|
                    response.read_body do |chunk|
                        buf << chunk
                        while (line = buf[/.+?(\r\n)+/m]) != nil
                            begin
                                buf.sub!(line,"")
                                line.strip!
                                status = JSON.parse(line)
                            rescue
                                break
                            end
                          yield status
                      end
                   end
               end
            end
        end

        def run
            loop do
                begin 
                    connect do |json|
                        if (json['event']=='favorite') 
                            if(json['target_object']['favorited'])
                                if(json['source']['screen_name'] == 'zwranian')
                                    text = json['target_object']['text']
                                    text_split = text.split("-")
                                    url   = text_split[text_split.size-1].strip #空白を除去してURLを取得
                                    title = ""
                                    text_split.delete_at(text_split.size-1)
                                    text_split.each {|t|
                                        title = title+t
                                    }
                                    puts "title: "+title+", url: "+url
                                    @pocketPost.post(url,title)
                                end
                            end
                        else
                            #puts JSON.pretty_generate(json) 
                        end
                    end
                rescue Timeout::Error,StandardError
                    puts "re connnect"
                end
            end
        end     
    end  
end
      TwitterBot::Bot.new.run          
