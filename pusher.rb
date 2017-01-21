require 'bundler'
require 'kconv'
Bundler.require

require_relative 'tables'

class Push

  # GCMサーバの接続先 (https://android.googleapis.com/gcm/send)
  GCM_HOST = "fcm.googleapis.com"
  GCM_PATH = "/fcm/send"

  def push_entry e
    puts "pusher:push_entry in -> #{e['title']}"
    c = 0;
    while true do
      ids = Array.new

      fcms = Api::Fcm.limit(1000).offset(c * 1000).order(id: :desc)
      if fcms.count == 0 then
        puts "pusher:push_entry out"
        break
      end

      fcms.each do |f|
        ids.push f['reg_id']
      end

      send_entry_message(ids, e)
      c = c + 1
    end
  end

  def push_report r
    puts "pusher:push_report in"
    c = 0;
    while true do
      ids = Array.new

      fcms = Api::Fcm.limit(1000).offset(c * 1000).order(id: :desc)
      if fcms.count == 0 then
        puts "pusher:push_report out"
        break
      end

      fcms.each do |f|
        ids.push f['reg_id']
      end

      send_report_message(ids, r)
      c = c + 1
    end
  end

  private
=begin
puts "title->#{e['title']}"
puts "url->#{e['url']}"
puts "member_id->#{e['member_id']}"
puts "original_raw_image_urls->#{e['original_raw_image_urls']}"
puts "original_thumbnail_urls->#{e['original_thumbnail_urls']}"
puts "uploaded_raw_image_urls->#{e['uploaded_raw_image_urls']}"
puts "uploaded_thumbnail_urls->#{e['uploaded_thumbnail_urls']}"
puts "published->#{e['published']}"
=end
    # ブログ記事用
    def send_entry_message ids, e
      message = {
        "registration_ids" => ids,
        "priority" => "high",
        "delay_while_idle" => false,
        "data" => { "_object_key" => "object_entry",
                    "_id" => e['id'],
                    "_title" => e['title'],
                    "_url" => e['url'],
                    "_original_raw_image_urls" => e['original_raw_image_urls'],
                    "_original_thumbnail_urls" => e['original_thumbnail_urls'],
                    "_uploaded_raw_image_urls" => e['uploaded_raw_image_urls'],
                    "_uploaded_thumbnail_urls" => e['uploaded_thumbnail_urls'],
                    "_member_id" => e['member_id'],
                    "_published" => e['published'],
                    "_member_name" => e.member['name_main'],
                    "_member_image_url" => e.member['image_url']
        }
      }
      post message, ids
    end

    # レポート用
    def send_report_message ids, r
      message = {
        "registration_ids" => ids,
        "priority" => "high",
        "delay_while_idle" => false,
        "data" => { "_object_key" => "object_report",
                    "_id" => r['id'],
                    "_title" => r['title'],
                    "_url" => r['url'],
                    "_published" => r['published'],
                    "_image_url_list" => r['image_url_list'],
                    "_created_at" => r['created_at'],
                    "_updated_at" => r['updated_at']
        }
      }
      post message, ids
    end

    def post message, ids
      puts "pusher:post in"
      # HTTPS POST実行
      http = Net::HTTP.new(GCM_HOST, 443);
      http.use_ssl = true
      http.start{ |w|
        response = w.post(GCM_PATH,
          message.to_json + "\n",
          {"Content-Type" => "application/json; charset=utf-8",
           "Authorization" => "key=#{ENV['PUSH_API_KEY']}"})
        #puts "response code = #{response.code}"
        #puts "response body = #{response.body}"
        hash = JSON.parse response.body
        ret = hash['results']
        ret.each_with_index { |r, i|
          # https://developers.google.com/cloud-messaging/http-server-ref
          # InternalServerError,Unavailable はリトライする
          if r.has_value?('InternalServerError') || r.has_value?('Unavailable') then
            # TODO: retry
            puts "pusher:post:error:retry -> #{r}"
            puts "pusher:post out"
            return
          end
          # 失敗時
          # {"error":"InvalidRegistration"}
          if r.has_key?('error') then
            puts "pusher:post:error -> #{r}"
            if r.has_value?('MissingRegistration') || r.has_value?('InvalidRegistration') || r.has_value?('NotRegistered') then
              # 不要なキーは削除する
              puts "pusher:post:error:delete -> #{ids[i]}"
              fcm = Api::Fcm.where(reg_id: ids[i]).first
              if fcm != nil then
                puts fcm.destroy
              end
            else
              puts "pusher:post:error:unknown -> #{ids[i]}"
            end
          else
            # 成功時
            # {"message_id":"0:1479889709159316%d8e5392f6fbc52cd"}
            puts "pusher:post:success -> #{ids[i]}"
          end
        }
      }
      puts "pusher:post out"
    end
end
