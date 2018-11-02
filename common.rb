require 'open-uri'
require 'selenium-webdriver'
require 'active_record'
require 'nokogiri'
require 'socket'
require 'aws-sdk'

#親ディレクトリ名＝DB名として接続
SERVER_NAME = Socket.gethostname.split('.').first.freeze
dbname = File.dirname(File.expand_path(__FILE__)).split('/').last

host = 'localhost'
user = 'root'
pass = ''

ActiveRecord::Base.establish_connection(
      :adapter  => 'mysql2',
      :charset => 'utf8mb4',
      :encoding => 'utf8mb4',
      :collation => 'utf8mb4_general_ci',
      :database => dbname,
      :host     => host,
      :username => user,
      :password => pass
)

# DBのタイムゾーン設定
Time.zone_default =  Time.find_zone! 'Tokyo' # config.time_zone
ActiveRecord::Base.default_timezone = :local # config.active_record.default_timezone

class VideoAd < ActiveRecord::Base
end

class User < ActiveRecord::Base
end
