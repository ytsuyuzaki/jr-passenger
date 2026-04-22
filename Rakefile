require_relative 'lib/passenger_parser'
require 'rake/testtask'

namespace :json do
  desc "乗車人員のjsonファイル作成"
  task :create do
    require 'open-uri'
    require 'json'
    urls = {
      '2012' => 'http://www.jreast.co.jp/passenger/',
      '2011' => 'http://www.jreast.co.jp/passenger/2011.html',
      '2010' => 'http://www.jreast.co.jp/passenger/2010.html',
      '2009' => 'http://www.jreast.co.jp/passenger/2009.html',
      '2008' => 'http://www.jreast.co.jp/passenger/2008.html',
      '2007' => 'http://www.jreast.co.jp/passenger/2007.html',
      '2006' => 'http://www.jreast.co.jp/passenger/2006.html',
      '2005' => 'http://www.jreast.co.jp/passenger/2005.html',
      '2004' => 'http://www.jreast.co.jp/passenger/2004.html',
      '2003' => 'http://www.jreast.co.jp/passenger/2003.html',
      '2002' => 'http://www.jreast.co.jp/passenger/2002.html',
      '2001' => 'http://www.jreast.co.jp/passenger/2001.html',
      '2000' => 'http://www.jreast.co.jp/passenger/2000.html',
      '1999' => 'http://www.jreast.co.jp/passenger/1999.html',
    }

    urls.each do |year, url|
      html_content = open(url).read
      trs = PassengerParser.parse(html_content, url)
      open("source/javascripts/json/#{year}.json", 'w') do |io|
        JSON.dump(trs, io)
      end
    end
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task default: :test
