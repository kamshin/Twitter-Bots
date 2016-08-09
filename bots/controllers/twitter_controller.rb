require 'twitter'
require 'curb'
require 'hashie'
$host = ENV['HOST']
$user_streaming = true
$deleted_streaming = true

puts "TwitterController"

class Tweet
  class << self

    def config
      Twitter::Streaming::Client.new do |config|
        config.consumer_key    = ENV["CONSUMER_KEY"]
        config.consumer_secret = ENV["CONSUMER_SECRET"]
        config.access_token    = ENV["ACCESS_TOKEN"]
        config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      end
    end

    def config_rest
      Twitter::REST::Client.new do |config|
        config.consumer_key    = ENV["CONSUMER_KEY"]
        config.consumer_secret = ENV["CONSUMER_SECRET"]
        config.access_token    = ENV["ACCESS_TOKEN"]
        config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      end
    end

    def slack_post(attachments)
      conf = { channel: "#bot_tech", username: "Lavender", icon_url: "http://19.xmbs.jp/img_fget.php/_bopic_/923/e05cec.png"}.merge(attachments)
      Curl.post( ENV['WEBHOOKS'],JSON.pretty_generate(conf))
      puts JSON.pretty_generate(conf)
    end

    def slack_post_options(tweet)
      attachments = [{
        author_icon: tweet.user.profile_image_url.to_s,
        author_name: tweet.user.name,
        author_subname: "@#{tweet.user.screen_name}",
        text: tweet.full_text,
        author_link: tweet.uri.to_s,
        color: tweet.user.profile_link_color,
        actions: [
          {
            name: "favo",
            text: "Favo",
            type: "button",
            value: "favo"
          },
          {
            name: "rt",
            text: "RT",
            type: "button",
            value: "rt"
          }
        ]
      }] 
      if tweet.media
        tweet.media.each_with_index do |v,i|
          attachments[i] ||= {}
          attachments[i].merge!({image_url: v.media_uri })
        end
      end
      Tweet.slack_post({attachments: attachments})
    end

    def database_post(tweet)
      Curl.post(
        "#{$host}/stocking_tweet",
        ({ 
          tweet_id: tweet.id,
          name: tweet.user.screen_name,
          user_name: tweet.user.name,
          text: tweet.full_text,
          icon: tweet.user.profile_image_url,
          url:tweet.uri, 
          color: tweet.user.profile_link_color
        }).to_json)
    end

    def list_join_members(list_id)
      Tweet.config_rest.list_members(list_id, count: 1000).map{ |user| user.screen_name }
    end

    def tweet(text)
      Tweet.config_rest.update(text)
    end
  end

  class DeletedStreaming < Tweet
    def self.stop!
      $deleted_streaming = false
    end
    def self.start!
      $deleted_streaming = true
    end
  end

  class UserStreaming < Tweet
     def self.stop!
       $user_streaming = false
    end
    def self.start!
      $user_streaming = true
    end
  end
end
