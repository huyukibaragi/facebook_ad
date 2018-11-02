require_relative 'common.rb'
require 'pp'

def insert_ad_info(hash)
  VideoAd.find_or_create_by(hash)
end

def get_ad_info(article,email,count)
  hash = {}
  image_url = ""
  video_url = ""
  post_url = ""
  external_url = ""
  install_url = ""
  text = ""
  advertiser_name = ""
  advertiser_id = ""
  appearance_id = ""
  movie_file = ""
  video_file_url = ""

  post_url = article.find_element(:css, "._5msj").attribute("href") #動画詳細URL
  advertiser_name = article.find_element(:css, "._52jd._52jb._52jh._5qc3._3rc4").text
  text = article.find_element(:css, "._5rgt._5nk5._5msi").text
  unless article.find_elements(:css, "._53mw._4gbu").empty?
    video_url = article.find_element(:css, "._53mw._4gbu").attribute("data-store").gsub(/^.*?"src":"/,"").gsub(/","width".*$/,"").gsub("\\","")
    fileName = video_url.match(/\d{1,}_\d{1,}_\d{1,}/).to_s + '.mp4'#mp4ファイルの個別idをファイル名称とする。
    open(video_url) do |url|
      movie_file = url.read# mp4ファイルの書き出し。
    end
    s3_upload(fileName,movie_file)#s3へのアップロード処理
    video_file_url = '' + fileName#S3で生成されるファイル固有のURLを作成。
  end
  image_url = article.find_element(:css, ".img.img._4s0y").attribute("style").gsub('background-image: url(',"") unless article.find_elements(:css, ".img.img._4s0y").empty?
  external_url = article.find_element(:css, "._5s61._5cn0 a").attribute("href") unless article.find_elements(:css, "._5s61._5cn0 a").empty?
  adv_url = article.find_element(:class, "_4g34").find_element(:tag_name, "a").attribute("href") unless article.find_element(:class, "_4g34").find_element(:tag_name, "a").attribute("href").nil?

  hash = {
    :user_id => email,
    :image_url => image_url,
    :video_url => video_url, #未対応
    :video_file_url => video_file_url, #未対応
    :post_url => post_url, #未対応
    :external_url => external_url,
    :install_url => install_url, #未対応
    :text => text,
    :advertiser_name => advertiser_name,
    :advertiser_id => advertiser_id, #未対応
    :appearance_id => `uuidgen`.chomp,
    :crawled_at => Time.now
  }
  insert_ad_info(hash)
end

def s3_upload(fileName,movie_file)
  Aws.config.update({#S3に接続するための処理
  region: '',
  credentials: Aws::Credentials.new('', ''),
  })
  s3 = Aws::S3::Resource.new
  output_file = s3.bucket('').object(fileName)
  output_file.put(body: movie_file)
end

def crawlr_articles(articles,email,count)
  articles.each do |article|
    headers = article.find_elements(:tag_name, "header")
    headers.length.times do |i|
      if headers[i].text.include?("広告")
        get_ad_info(article,email,count)
        break
      end
    end
  end
end

def main(user)
  output_ary = []
  count = 0
  @session.navigate.to "https://m.facebook.com/"
  #トップニュースフィード取得
  articles = @session.find_element(:id, "u_ps_0_0_1").find_elements(:tag_name, "article")
  crawlr_articles(articles,user.email,count)
  #ニュースフィード取得
  50.times do
    count += 1
    sleep 2
    begin
      @session.execute_script('window.scrollTo(0, document.body.scrollHeight);')
      section = @session.find_element(:css, "#MNewsFeed > section:nth-child(#{count})")
      articles = section.find_elements(:tag_name, "article")
      crawlr_articles(articles,user.email,count)
    rescue => e
      p e
    end
  end
end

def login(user)
  id = @session.find_element(:name, "email")
  pass = @session.find_element(:name, "pass")
  sleep 1
  # @session.execute_script("arguments[0].removeAttribute('readonly')" , id)
  # @session.execute_script("arguments[0].removeAttribute('readonly')" , pass)
  id.send_keys(user.email)
  pass.send_keys(user.password)
  @session.find_element(:name, "login").click
  sleep 3
  #@session.find_element(:text, "後で").click
end

def save_cookies(user)
  cookies = @session.manage.all_cookies
  user.update(cookie: Marshal.dump(cookies))
end

def load_cookies(user)
  cookies = Marshal.load(user[:cookie])
  cookies.each do |cookie|
    @session.manage.add_cookie(
    {
      name: cookie[:name],
      value: cookie[:value],
      path: cookie[:path],
      secure: cookie[:secure],
      domain: cookie[:domain]
    }
  )
  end
end

def set_cookies(user)
  if cookies?(user)
    load_cookies(user)
  else
    p "cookie情報がりません。"
    sleep 5
    login(user)
    save_cookies(user)
  end
end

def cookies?(user)
  !(user[:cookie].nil? || user[:cookie].empty?)
end

def start
  user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36"
  capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs('phantomjs.page.settings.userAgent' => user_agent,'phantomjs.page.settings.loadImages' => false)
  @session= Selenium::WebDriver.for :phantomjs, :desired_capabilities => capabilities
  @session.manage.timeouts.implicit_wait = 3 # 待ち時間指定
  @session.navigate.to "https://m.facebook.com/"
  sleep 2
end

users = User.where(active: 1)
users.each do |user|
  start
  set_cookies(user)
  main(user)
  save_cookies(user)
  @session.quit
  sleep 60
end
