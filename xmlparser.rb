# http://docs.ruby-lang.org/ja/2.1.0/library/rexml=2fdocument.html
# http://d.hatena.ne.jp/aoi_273/20090311/1236764850

# URLにアクセスするためのライブラリを読み込む
require 'open-uri'

# XMLをパースするためのライブラリを読み込む
require 'rexml/document'

require_relative 'useragent'

class XMLParser

  def self.parse(url)
    begin
      # RSSフィードを取得する
      #url = 'http://blog.nogizaka46.com/atom.xml'
      xml = open(url, 'User-Agent' => UserAgents.agent)
      # 取得したフィード(XML)の読み込み
      doc = REXML::Document.new(xml)
      # 解析する
      doc.elements.each('feed/entry') do |e|
        published = e.elements['published'].text
        url = e.elements['link'].attribute('href')
        yield("#{published}", "#{url}")
      end
    rescue OpenURI::HTTPError, REXML::Attribute => ex
      if ex == OpenURI::HTTPError then
        if ex.message == '404 Not Found' then
          # ありえないケース.公式ブログのバグ
          # TODO: メールで通知したい
        else
          sleep 5
          puts "*****************************************"
          puts " HTTPError ex-> #{ex.message} with retry!!!"
          puts "*****************************************"
          retry
        end
      elsif ex == REXML::Attribute then
        sleep 5
        puts "*****************************************"
        puts " REXML::Attribute ex-> #{ex.message}"
        puts "*****************************************"
        retry
      end
    end
  end

end
