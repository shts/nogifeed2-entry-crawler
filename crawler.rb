
# URLにアクセスするためのライブラリを読み込む
require 'open-uri'

# HTMLをパースするためのライブラリを読み込む
require 'nokogiri'

# 日付を扱うためのライブラリを読み込む
require 'date'

# 公式サイトの不具合で記事の反映がRSSより遅いので初回ページ読み込みで何件の記事かは漏れる
class Crawler

  BaseUrl = "http://blog.nogizaka46.com/"
  # 一番古い月のアーカイブURL
  LastUrl = "http://blog.nogizaka46.com/?p=0&d=201111"
  # TODO: debug
  #LastUrl = "http://blog.nogizaka46.com/?p=0&d=201306"

  # 日付ddは固定値
  Day = 1

  def self.past_entry_url
    # TODO:本日から2011/11までさかのぼる
    date = Date.today
    # TODO:debug
    #date = Date.new(2013, 7, 1)
    req_url = to_url(date)

    url_arr = Array.new()
    loop do
      a_month_article_url_arr(req_url) { |url|
        puts "#{url}"
        url_arr.push(url)
      }
      # 終端までいったら終了
      break if req_url == LastUrl
      # 前月を取得(loopスコープ外の変数に格納すること)
      date = prev_month(date)
      # URLに変換
      req_url = to_url(date)
    end
    # 重複したURLを削除
    url_arr.uniq!
    # 作成したURLを逆順(古 -> 新)にする
    url_arr.reverse!
    url_arr
  end

  private
  def self.to_url(date)
    month = date.month.to_i < 10 ? "0#{date.month}" : "#{date.month}"
    BaseUrl + "?p=0&d=#{date.year}#{month}"
  end

  def self.prev_month(current)
    if current.month == 1 then
      Date.new(current.year - 1, 12, Day)
    else
      Date.new(current.year, current.month - 1, Day)
    end
  end

  def self.a_month_article_url_arr(req_url)
    # ページネーションタグからその月のページすべてを取得する
    doc = Nokogiri::HTML(open(req_url))
    doc.css('div.paginate').css('a').each do |e|
      #puts e
      # 各ページから記事のURLを取得する
      doc2 = Nokogiri::HTML(open(BaseUrl + e[:href]))
      doc2.css('span.entrytitle').css('a').each do |article_url|
        yield(article_url[:href])
      end
    end
  end

end

#Crawler.past_entry_url
