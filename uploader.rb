require 'bundler'
require 'kconv'
Bundler.require

#http://qiita.com/tamikura@github/items/a6f819a0ce2b6c79bec7
class Uploader
  #  nogifeed.s3-website-ap-northeast-1.amazonaws.com
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Client.html#put_object-instance_method
  @@client = Aws::S3::Client.new(
                               :region => 'ap-northeast-1',
                               :access_key_id => ENV['AWS_KEY_ID'],
                               :secret_access_key => ENV['AWS_KEY_ID_SECRET'],
                               )
  def self.upload filename
    filepath = "tmp/" + filename
    @@client.put_object({
      acl: "public-read",
      bucket: "nogifeed",
      #bucket: "tonjiru",
      key: filename,
      body: File.open(filepath),
    })
    #"https://s3-ap-northeast-1.amazonaws.com/tonjiru/" + filename
    "https://s3-ap-northeast-1.amazonaws.com/nogifeed/" + filename
  end
end
