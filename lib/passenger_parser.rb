require 'nokogiri'
require 'json'

# Parses JR East passenger HTML pages and extracts station ranking data.
# The 2012 (latest) page uses a different column layout than older pages:
#   - Latest:  rank=col0, city=col1, total=col4
#   - Older:   rank=col0, city=col1, total=col2
class PassengerParser
  LATEST_URL = 'http://www.jreast.co.jp/passenger/'.freeze

  # Parse HTML content and return an array of hashes with :rank, :city, :total.
  #
  # @param html_content [String] raw HTML of the JR East passenger page
  # @param url [String] source URL (used to determine column layout)
  # @return [Array<Hash>] parsed station entries
  def self.parse(html_content, url)
    doc = Nokogiri::HTML.parse(html_content)
    is_latest = (url == LATEST_URL)
    results = []

    doc.xpath('//tr[td[@class="text-m" and @bgcolor="#ffffff"]]').each do |tr|
      tds = {}
      tr.xpath('td').each_with_index do |td, count|
        tds[:rank] = td.text if count == 0
        tds[:city] = td.text.strip if count == 1
        # :total is only set when the expected column index exists in the row.
        # Rows with fewer columns will not have a :total key.
        if is_latest
          tds[:total] = td.text.delete(',').to_i if count == 4
        else
          tds[:total] = td.text.delete(',').to_i if count == 2
        end
      end
      results << tds
    end

    results
  end
end
