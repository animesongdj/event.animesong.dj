require 'nokogiri'
require 'open-uri'
require 'uri'
require 'fileutils'
require 'json'
require 'time'

def scrape_twipla_search(query, page = 1)
  encoded_query = URI.encode_www_form_component(query)
  search_url = "https://twipla.jp/events/search/page~#{page}/keyword~#{encoded_query}/"
  html = URI.open(search_url).read
  doc = Nokogiri::HTML.parse(html, nil, 'UTF-8')

  events = []

  doc.css('ol.links li').each do |event|
    link_element = event.css('a').first
    next unless link_element # リンクがない場合はスキップ
    link = link_element['href']
    event_url = "https://twipla.jp#{link}"

    location_element = event.css('span.status-body span.black').last
    next unless location_element # 場所がない場合はスキップ
    location = location_element.text.strip

    # 各イベントページにアクセスして詳細を取得
    event_html = URI.open(event_url).read
    event_doc = Nokogiri::HTML.parse(event_html, nil, 'UTF-8')

    title = event_doc.css('title').text.strip.gsub(' - TwiPla', '')
    description_element = event_doc.css('div#event_main p').first
    description = description_element ? description_element.text.strip : '説明なし'
    flyer_element = event_doc.css('img[src^="/imgs/"]').first
    flyer = flyer_element ? "https://twipla.jp#{flyer_element['src']}" : 'フライヤーなし'
    organizer_element = event_doc.css('a[href^="/users/"]').first
    organizer_name = organizer_element ? organizer_element.text.strip : '主催者なし'
    organizer_url = organizer_element ? "https://twipla.jp#{organizer_element['href']}" : 'リンクなし'

    date_element = event.css('span.status-body strong.black').first
    date = date_element ? date_element.text.strip : '日付なし'

    location_element = event_doc.css('span.status-body span.black').last
    location = location_element ? location_element.text.strip : '場所なし'

    events << {
      "@context": "https://schema.org",
      "@type": "MusicEvent",
      "name": title,
      "url": event_url,
      "startDate": date,
      "description": description,
      "image": flyer,
      "location": {
        "@type": "Place",
        "name": location
      },
      "organizer": {
        "@type": "Person",
        "name": organizer_name,
        "url": organizer_url
      }
    }

    # 1秒のディレイを追加
    sleep 1
  end

  events
end

def generate_json_ld(events)
  FileUtils.mkdir_p('json-ld')
  filename = "json-ld/twipla_events_#{Time.now.strftime('%Y-%m-%d')}.json"
  File.open(filename, 'w') do |file|
    file.puts JSON.pretty_generate(events)
  end
end

if __FILE__ == $0
  query = 'アニソンDJ'
  page = 1
  events = scrape_twipla_search(query, page)
  generate_json_ld(events)
  puts "JSON-LD file generated successfully."
end