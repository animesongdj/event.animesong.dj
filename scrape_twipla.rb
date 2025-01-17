require 'nokogiri'
require 'open-uri'
require 'uri'
require 'fileutils'

def scrape_twipla_search(query, page = 1)
  encoded_query = URI.encode_www_form_component(query)
  search_url = "https://twipla.jp/events/search/page~#{page}/keyword~#{encoded_query}/"
  html = URI.open(search_url)
  doc = Nokogiri::HTML(html)

  # Save HTML to file
  FileUtils.mkdir_p('html')
  html_filename = "html/twipla_search_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.html"
  File.open(html_filename, 'w') { |file| file.write(html) }

  events = []

  doc.css('ol.links li').each do |event|
    title = event.css('span.status-body span.black').text.strip
    link_element = event.css('a').first
    link = link_element ? link_element['href'] : 'リンクなし'
    date = event.css('span.status-body strong.black').text.strip
    description = event.css('span.status-body span.graysmall').text.strip

    events << {
      title: title,
      link: link,
      date: date,
      description: description
    }
  end

  events
end

def generate_markdown(events)
  FileUtils.mkdir_p('_posts')
  filename = "_posts/#{Time.now.strftime('%Y-%m-%d')}-twipla-events.md"
  File.open(filename, 'w') do |file|
    file.puts "---"
    file.puts "layout: post"
    file.puts "title: 'Twipla イベント一覧'"
    file.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
    file.puts "---"
    file.puts
    events.each do |event|
      file.puts "## #{event[:title]}"
      file.puts "- **リンク**: [#{event[:link]}](#{event[:link]})"
      file.puts "- **日付**: #{event[:date]}"
      file.puts "- **説明**: #{event[:description]}"
      file.puts
    end
  end
end

if __FILE__ == $0
  query = 'アニソンDJ'
  page = 1
  events = scrape_twipla_search(query, page)
  generate_markdown(events)
  puts "Markdown file and HTML file generated successfully."
end
