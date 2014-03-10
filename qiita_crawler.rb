# coding: utf-8
require 'anemone'
require 'mail'
require 'erb'
require 'yaml'

conf = YAML.load_file('config/config.yml')

qiita_url = conf['default']['company']['url']
@item_list = []
f = open("url_collection.txt","a+")

Anemone.crawl(qiita_url) do |anemone|
  anemone.focus_crawl do |page|
    # 条件に一致するリンクだけ残す
    # この `links` はanemoneが次にクロールする候補リスト
    page.links.keep_if { |link|
      link.to_s.match(/#{conf['default']['company']['name_regEx']}\?page.*/)
    } 
  end

  anemone.on_every_page do |page|
    item = page.doc.xpath('//*[@id="main"]/div/div/div[2]/div/article')

    item.each do |i|
      name = i.xpath('div/div[1]/strong/a/text()').to_s
      title = i.xpath('div/div[2]/h1/a/text()').to_s
      url = i.xpath('div/div[2]/h1/a/@href').to_s
      if f.grep(/#{url}/).empty?
        temp_item = {
          name: name,
          title: title,
          url: url
        }   
        @item_list.push(temp_item)
      end
      f.rewind
    end

  end
end

puts @item_list
erb = ERB.new(File.read('body.txt.erb'))
puts erb.result(binding)

unless @item_list.empty?
  mail = Mail.new do
    sender  conf['default']['mail']['sender']
    to      conf['default']['mail']['to']
    subject "#{conf['default']['company']['name']}のQiita Organization更新情報"
    #body    item_list
    body    erb.result
  end
  # mail.delivery_method(:sendmail)
  mail.charset = 'utf-8' # It's important!
  mail.deliver!
end
#File.open("url_collection.txt","a+") do |f|
#  f.each_line do |line|
#    puts line
#  end
#  f.puts(item_list)
#end
f.puts(@item_list)
f.close
