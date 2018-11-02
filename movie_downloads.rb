require_relative 'common.rb'


@path = ''
fileName = @path.match(/\d{1,}_\d{1,}_\d{1,}/).to_s + '_n.mp4'
open(@path) do |data|
  @movie_file = data.read
end

Aws.config.update({#S3に接続するための処理
  region: '',
  credentials: Aws::Credentials.new('', ''),
})
s3 = Aws::S3::Resource.new
output_file = s3.bucket('').object(fileName)
output_file.put(body: @movie_file)
