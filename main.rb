require 'bundler'
require 'kconv'
Bundler.require
# プログラムを定期実行するためのライブラリを読み込む
require 'eventmachine'
# データベースにアクセスするためのライブラリを読み込む
#require 'sinatra/activerecord'

require_relative 'htmlparser'
require_relative 'downloader'
#require_relative 'parseapiclient'
require_relative 'crawler'
require_relative 'xmlparser'
require_relative 'tables'
require_relative 'pusher'
require_relative 'uploader'

def fetch(published, url, needpush)

  HTMLParser.fetch(url) { |data|

    if data != nil then
      data[:published] = published
      data[:uploaded_thumbnail_url] = Array.new()
      data[:uploaded_raw_image_url] = Array.new()

      Downloader.save_image(data) { |url_origin, saved_file_name, type|
        upload_url = Uploader.upload(saved_file_name)

        if type == Downloader::Thumbnail then
          data[:uploaded_thumbnail_url].push(upload_url)
        else
          data[:uploaded_raw_image_url].push(upload_url)
        end
      }
      member = Api::Member.where('rss_url = ?', data[:rss_url]).first
      data[:member_id] = member['id']
      save_and_push data
    else
      puts "entry is nil"
    end
  }
end

def save_and_push d
  e = Api::Entry.new
  e['title'] = d[:entrytitle]
  e['url'] = d[:article_url]
  e['member_id'] = d[:member_id]
  e['original_raw_image_urls'] = d[:raw_img_url_arr]
  e['original_thumbnail_urls'] = d[:thumbnail_url_arr]
  e['uploaded_raw_image_urls'] = d[:uploaded_raw_image_url]
  e['uploaded_thumbnail_urls'] = d[:uploaded_thumbnail_url]
  e['published2'] = d[:published]
  #e.save
  Push.new.push_entry e if e.save
end

def get_all_entry
=begin
  ParseApiClient.all_member_feed { |rss_url|
    XMLParser.parse(rss_url) { |published, url|
      sleep 1
      fetch(published, url, false) if ParseApiClient.is_new?(url)
    }
  }
=end
  Api::Member.all.each do |m|
    XMLParser.parse(m['rss_url']) { |published, url|
      sleep 1
      fetch(published, url, false) if ParseApiClient.is_new?(url)
    }
  end
end

# TODO:過去の記事のURLすべてを取得する
#url_arr = Crawler.past_entry_url
#url_arr.each do |url|
#  # 10000件が上限なので9500を超えた場合は古いレコードを削除する
#  if Entries.count >= 9500
#    Entries.first.delete
#  end
#  # URLをDBに保存
#  Entries.where(:url => url).first_or_create do |e|
#    puts "new record -> #{e}"
#    # 各URLをパースしてDBへ保存する
#    # とりあえずDBに格納して上限になったらどうなるか調査
#    fetch(url)
#  end
#end

#get_all_entry

# TODO:新着を記事を監視する
=begin
EM.run do
  EM::PeriodicTimer.new(60) do
    puts "routine work start..."
    XMLParser.parse("http://blog.nogizaka46.com/atom.xml") { |published, url|
      fetch(published, url, true) if Api::Entry.where('url = ?', url) == nil
    }
    puts "routine work finish !!!"
  end
end
=end
EM.run do
  EM::PeriodicTimer.new(60) do
    puts "routine work start..."
    Api::Member.all.each do |m|
      XMLParser.parse(m['rss_url']) { |published, url|
        fetch(published, url, true) if Api::Entry.where('url = ?', url).first == nil
      }
    end
    puts "routine work finish !!!"
  end
end
