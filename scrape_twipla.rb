require 'nokogiri'
require 'open-uri'
require 'uri'
require 'fileutils'
require 'json'
require 'time'

def scrape_twipla_search(query, existing_urls, page = 1)
  encoded_query = URI.encode_www_form_component(query)
  search_url = "https://twipla.jp/events/search/page~#{page}/keyword~#{encoded_query}/"
  puts "Scraping page #{page}: #{search_url}"
  html = URI.open(search_url).read
  doc = Nokogiri::HTML.parse(html, nil, 'UTF-8')

  events = []

  doc.css('ol.links li').each do |event|
    link_element = event.css('a').first
    next unless link_element # リンクがない場合はスキップ
    link = link_element['href']
    event_url = "https://twipla.jp#{link}"

    # 既存のJSON-LDと重複する場合は終了
    return events if existing_urls.include?(event_url)

    location_element = event.css('span.status-body span.black').last
    next unless location_element # 場所がない場合はスキップ
    location = location_element.text.strip

    # 各イベントページにアクセスして詳細を取得
    puts "Fetching event details: #{event_url}"
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

    # 場所の後にある店舗名を取得
    venue_element = event_doc.at('div.bluetext:contains("場所") + div')
    venue = venue_element ? venue_element.text.strip.gsub('道順を調べる', '') : '店舗名なし'

    date_element = event.css('span.status-body strong.black').first
    date = date_element ? date_element.text.strip : '日付なし'

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
        "name": venue
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

  # イベント件数が10件を下回る場合は終了
  return events if events.size < 10

  # 次へのリンクが切れている場合は終了
  next_link = doc.at('a:contains("次へ")')
  return events unless next_link

  # 次のページを再帰的にスクレイピング
  events + scrape_twipla_search(query, existing_urls, page + 1)
end

def generate_json_ld(events)
  FileUtils.mkdir_p('json-ld')
  events.group_by { |event| event[:startDate].split(' ').first.split('-').first(2).join('-') }.each do |date, events_on_date|
    formatted_date = date.gsub('/', '-')
    filename = "json-ld/twipla_events_#{formatted_date}.json"
    File.open(filename, 'w') do |file|
      file.puts JSON.pretty_generate(events_on_date)
    end
    puts "Generated JSON-LD file: #{filename}"
  end
end

if __FILE__ == $0
  query = 'アニソンDJ'
  existing_events = Dir.glob('json-ld/*.json').flat_map { |file| JSON.parse(File.read(file)) } rescue []
  existing_urls = existing_events.map { |event| event['url'] }
  events = scrape_twipla_search(query, existing_urls)
  generate_json_ld(events)
  puts "JSON-LD files generated successfully."
end