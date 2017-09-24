require 'bundler'
require 'kconv'
Bundler.require # gemを一括require

require_relative 'useragent'
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
# XMLをパースするためのライブラリを読み込む
require 'rexml/document'

class Banner

  URL = "http://www.nogizaka46.com/xml/topbannerdata.xml"

  def parse()
    begin
      # RSSフィードを取得する
      #url = 'http://blog.nogizaka46.com/atom.xml'
      xml = open(URL, 'User-Agent' => UserAgents.agent)
      # 取得したフィード(XML)の読み込み
      doc = REXML::Document.new(xml)
      # 解析する
      doc.elements.each('idxbnr/array_item') do |e|
        title = e.elements['alttext'].text
        thumurl = e.elements['thumurl'].text
        bnrurl = e.elements['bnrurl'].text
        linkurl = e.elements['linkurl'].text
        data = {
          :title => title,
          :thumurl => thumurl,
          :bnrurl => bnrurl,
          :linkurl => linkurl
        }
        yield(data)
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
