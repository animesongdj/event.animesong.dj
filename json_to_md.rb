require 'json'
require 'fileutils'
require 'time'
require 'uri'

def json_to_md(json_file)
  events = JSON.parse(File.read(json_file))
  events.each do |event|
    date = Time.parse(event['startDate']).strftime('%Y-%m-%d')
    title = event['name']
    event_url = event['url']
    filename_part = event_url.split('/').last
    filename = "_posts/#{date}-#{filename_part}.md"
    
    content = <<~MARKDOWN
      ---
      layout: post
      title: "#{title}"
      date: #{date}
      og_title: "#{title}"
      og_description: "#{event['description']}"
      og_image: "#{event['image']}"
      og_url: "#{event['url']}"
      ---
      
      ## #{title}
      
      **日時**: #{event['startDate']}
      
      **場所**: #{event['location']['name']}
      
      **主催者**: [#{event['organizer']['name']}](#{event['organizer']['url']})
      
      **説明**: #{event['description']}
      
      ![フライヤー](#{event['image']})
      
      [イベントページ](#{event['url']})
    MARKDOWN

    File.open(filename, 'w:UTF-8') do |file|
      file.write(content)
    end
    puts "Generated: #{filename}"
    
    # 1秒のディレイを追加
    sleep 1
  end
end

def convert_all_json_to_md
  json_files = Dir.glob('json-ld/*.json')
  puts "Total JSON files: #{json_files.size}"
  json_files.each do |json_file|
    puts "Processing: #{json_file}"
    json_to_md(json_file)
  end
end

if __FILE__ == $0
  FileUtils.mkdir_p('_posts')
  convert_all_json_to_md
  puts "Markdown files generated successfully."
end