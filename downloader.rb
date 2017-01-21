
# http://source.hatenadiary.jp/entry/2014/10/12/151836
# http://qiita.com/Oakbow/items/802da14fa3cf67763ba7
# http://blog.ruedap.com/2011/04/14/ruby-heroku-rmagick-display-generate-image
#Downloader.save_image("http://dcimg.awalker.jp/img2.php?sec_key=zX28g6c0rXk4CHhwTCXTdJspTKC2wl2d8dMRsFMIJOnrk4KBVfctmlHX3l5SPpPWjBLCTBrJgcZyhYJVTplsxI5Cn4CiSTqeoxsqCdT44r7QmXKNdrWrnR0dMqUEdB9QEwKdV3amly2xLVFBzpVd1mHGXHrYwdhRNiQ6XzJYe2vzrinr8vtpwdv7v304wQAjM3ISnSij")

class Downloader

  # TODO: Heroku環境用
  #Dirname = './tmp/'
  # TODO: Windowsデバッグ用
  #Dirname = "C:/Users/saito_shota/Desktop/"
  # TODO: Windowsデバッグ用
  Dirname = "./tmp/"

  Thumbnail = "Thumbnail"
  RawImage = "RawImage"

  def self.save_image(data)
    puts "start save_image"
    save_thumbnail_image(data) { |url_origin, file_name|
      yield(url_origin, file_name, Thumbnail)
    }
    save_raw_image(data) { |url_origin, file_name|
      yield(url_origin, file_name, RawImage)
    }
  end

  def self.save_thumbnail_image(data)
    counter = 0;
    data[:thumbnail_url_arr].count { |url|
      file_name = new_file_name(data[:article_url]) + "_thumb_#{counter}.jpeg"
      file_path = Dirname + file_name

      FileUtils.mkdir_p(Dirname) unless FileTest.exist?(Dirname)
      # open(url, 'User-Agent' => 'ruby')
      open(file_path, 'wb') do |output|
        open(url, 'User-Agent' => 'ruby') do |data|
          output.write(data.read)
          yield(url, file_name)
        end
      end
      counter = counter + 1
    } if data[:thumbnail_url_arr] != nil
  end

  def self.save_raw_image(data)
    counter = 0;
    data[:raw_img_url_arr].count { |url|
      open(url) { |f|
        # アクセス時のクッキーを取得してダウンロード時に利用する
        cookie = {"Cookie" => f.meta['set-cookie']}
        # クッキーを取得したページからダウンロード用URLを取得する
        doc = Nokogiri::HTML(f)
        valid_url = doc.css("img")[0][:src]

        file_name = new_file_name(data[:article_url]) + "_raw_#{counter}.jpeg"
        file_path = Dirname + file_name

        FileUtils.mkdir_p(Dirname) unless FileTest.exist?(Dirname)

        open(file_path, 'wb') do |output|
          open(valid_url, cookie) do |data|
            output.write(data.read)
            yield(url, file_name)
          end
        end
      }
      counter = counter + 1
    } if data[:raw_img_url_arr] != nil
  end

  private
  def self.new_file_name(article_url)
    # http://blog.nogizaka46.com/miona.hori/2015/10/025340.php
    arr = article_url.split("/")
    name = arr[arr.count - 4].gsub(".", "_")
    year = arr[arr.count - 3]
    month = arr[arr.count - 2]
    daytime = arr[arr.count - 1].gsub(".php", "")
    "#{name}_#{year}_#{month}_#{daytime}"
  end

end

#puts Downloader.new_file_name("http://blog.nogizaka46.com/miona.hori/2015/10/025340.php")
