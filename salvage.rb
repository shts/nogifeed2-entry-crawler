require 'bundler'
require 'kconv'
Bundler.require # gemを一括require

require_relative 'useragent'
require_relative 'htmlparser'
require_relative 'downloader'
require_relative 'crawler'
require_relative 'xmlparser'
require_relative 'tables'
require_relative 'pusher'
require_relative 'uploader'
require 'date'
require 'open-uri'

def log text
=begin
  File.open("log.txt", "a") do |f|
    f.puts(text)
  end
=end
end

def fetch(e)
  url = e['url']
  begin
    d = Nokogiri::HTML(open(url, 'User-Agent' => UserAgents.agent))
    #d.xpath('//*[@id="sheet"]/div[3]')
    d.css('div.entrybottom').text
  rescue OpenURI::HTTPError, URI::InvalidURIError, Net::OpenTimeout => ex
    if ex == OpenURI::HTTPError then
      puts "******************************************************************************************"
      puts "HTTPError : url(#{url}) then #{ex.message} with retry!!!"
      puts "******************************************************************************************"
      #log "HTTPError : url(#{url}) then #{ex.message} with retry!!!"
      sleep 5
      retry
    elsif ex == Net::OpenTimeout then
      puts "******************************************************************************************"
      puts "HTTPError : url(#{url}) then #{ex.message} with retry!!!"
      puts "******************************************************************************************"
      log "HTTPError : url(#{url}) then #{ex.message} with retry!!!"
      sleep 5
      retry
    else
      # 無効なURLは処理をせずnilを返却する
      puts "******************************************************************************************"
      puts "HTTPError : url(#{url}) then #{ex.message} !!!"
      puts "******************************************************************************************"
      if ex.message == "404 Not Found" then
        e.destroy
        log "HTTPError : url(#{url}) then #{ex.message}"
      elsif ex.message == "403 Forbidden" then
        sleep 5
        retry
      end
    end
  end
end


Api::Entry.all.each do |e|
  if e['published2'].present? == false then
    # 403対策
    sleep 10

    s = fetch e
    if s == nil then
      puts "published is nil-> #{e['url']}"
    else
      d = DateTime.parse s
      puts d
      if d == nil then
        puts "d is nil -> #{e['url']}"
      else
        e['published2'] = d
        e.save
      end
    end
  else
    puts "already have published2 -> #{e['url']}"
  end
end

#puts fetch "http://blog.nogizaka46.com/yumi.wakatsuki/2017/01/036673.php"
