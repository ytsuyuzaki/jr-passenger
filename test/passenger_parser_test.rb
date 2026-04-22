require_relative 'test_helper'
require 'passenger_parser'

class PassengerParserTest < Minitest::Test
  LATEST_URL  = PassengerParser::LATEST_URL
  LEGACY_URL  = 'http://www.jreast.co.jp/passenger/2005.html'

  FIXTURE_DIR = File.expand_path('../fixtures', __FILE__)

  def latest_html
    File.read(File.join(FIXTURE_DIR, '2012_sample.html'))
  end

  def legacy_html
    File.read(File.join(FIXTURE_DIR, 'legacy_sample.html'))
  end

  # ---------------------------------------------------------------------------
  # Latest (2012) page format — total is in column index 4
  # ---------------------------------------------------------------------------

  def test_latest_returns_array
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_instance_of Array, result
  end

  def test_latest_returns_correct_number_of_entries
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_equal 4, result.length
  end

  def test_latest_rank_of_first_entry
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_equal '1', result[0][:rank]
  end

  def test_latest_city_of_first_entry
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_equal '新宿', result[0][:city]
  end

  def test_latest_total_of_first_entry
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_equal 742_833, result[0][:total]
  end

  def test_latest_total_is_integer
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_instance_of Integer, result[0][:total]
  end

  def test_latest_strips_commas_from_total
    result = PassengerParser.parse(latest_html, LATEST_URL)
    # 550,756 → 550756
    assert_equal 550_756, result[1][:total]
  end

  def test_latest_strips_whitespace_from_city
    # The fixture has "  渋谷  " for rank 3
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_equal '渋谷', result[2][:city]
  end

  def test_latest_handles_total_without_comma
    # rank=4 has "9876" (no comma)
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_equal 9876, result[3][:total]
  end

  def test_latest_entries_have_required_keys
    result = PassengerParser.parse(latest_html, LATEST_URL)
    result.each do |entry|
      assert entry.key?(:rank),  "Missing :rank key in #{entry.inspect}"
      assert entry.key?(:city),  "Missing :city key in #{entry.inspect}"
      assert entry.key?(:total), "Missing :total key in #{entry.inspect}"
    end
  end

  def test_latest_rank_sequence
    result = PassengerParser.parse(latest_html, LATEST_URL)
    assert_equal ['1', '2', '3', '4'], result.map { |e| e[:rank] }
  end

  # ---------------------------------------------------------------------------
  # Legacy page format (pre-2012) — total is in column index 2
  # ---------------------------------------------------------------------------

  def test_legacy_returns_array
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_instance_of Array, result
  end

  def test_legacy_returns_correct_number_of_entries
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_equal 4, result.length
  end

  def test_legacy_rank_of_first_entry
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_equal '1', result[0][:rank]
  end

  def test_legacy_city_of_first_entry
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_equal '新宿', result[0][:city]
  end

  def test_legacy_total_of_first_entry
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_equal 728_083, result[0][:total]
  end

  def test_legacy_total_is_integer
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_instance_of Integer, result[0][:total]
  end

  def test_legacy_strips_commas_from_total
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    # 523,492 → 523492
    assert_equal 523_492, result[1][:total]
  end

  def test_legacy_strips_whitespace_from_city
    # The fixture has "  渋谷  " for rank 3
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_equal '渋谷', result[2][:city]
  end

  def test_legacy_handles_total_without_comma
    # rank=4 has "5000" (no comma)
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    assert_equal 5000, result[3][:total]
  end

  def test_legacy_entries_have_required_keys
    result = PassengerParser.parse(legacy_html, LEGACY_URL)
    result.each do |entry|
      assert entry.key?(:rank),  "Missing :rank key in #{entry.inspect}"
      assert entry.key?(:city),  "Missing :city key in #{entry.inspect}"
      assert entry.key?(:total), "Missing :total key in #{entry.inspect}"
    end
  end

  # ---------------------------------------------------------------------------
  # Column layout isolation: latest URL uses col4, others use col2
  # ---------------------------------------------------------------------------

  def test_column_layout_differs_between_latest_and_legacy
    # Parsing latest HTML with LATEST_URL should pick column 4 (742833),
    # while parsing the same HTML with a legacy URL would leave :total nil
    # because the fixture only has data at column 4, not column 2.
    latest_result = PassengerParser.parse(latest_html, LATEST_URL)
    legacy_result = PassengerParser.parse(latest_html, LEGACY_URL)

    assert_equal 742_833, latest_result[0][:total]
    # Column 2 in the 2012 fixture is "JR" (a line name), delete(',').to_i => 0
    assert_equal 0, legacy_result[0][:total]
  end

  # ---------------------------------------------------------------------------
  # Edge cases
  # ---------------------------------------------------------------------------

  def test_empty_html_returns_empty_array
    result = PassengerParser.parse('<html><body></body></html>', LATEST_URL)
    assert_equal [], result
  end

  def test_empty_html_legacy_returns_empty_array
    result = PassengerParser.parse('<html><body></body></html>', LEGACY_URL)
    assert_equal [], result
  end

  def test_html_with_no_matching_rows_returns_empty_array
    html = <<~HTML
      <html><body>
        <table>
          <tr><td class="other">1</td><td class="other">Station</td></tr>
        </table>
      </body></html>
    HTML
    result = PassengerParser.parse(html, LATEST_URL)
    assert_equal [], result
  end

  def test_rows_without_matching_bgcolor_are_ignored
    html = <<~HTML
      <html><body>
        <table>
          <tr>
            <td class="text-m" bgcolor="#cccccc">1</td>
            <td class="text-m" bgcolor="#cccccc">新宿</td>
            <td class="text-m" bgcolor="#cccccc">JR</td>
            <td class="text-m" bgcolor="#cccccc">Tokyo</td>
            <td class="text-m" bgcolor="#cccccc">742,833</td>
          </tr>
        </table>
      </body></html>
    HTML
    result = PassengerParser.parse(html, LATEST_URL)
    assert_equal [], result
  end

  def test_single_row_latest
    html = <<~HTML
      <html><body>
        <table>
          <tr>
            <td class="text-m" bgcolor="#ffffff">1</td>
            <td class="text-m" bgcolor="#ffffff">新宿</td>
            <td class="text-m" bgcolor="#ffffff">JR</td>
            <td class="text-m" bgcolor="#ffffff">Kanto</td>
            <td class="text-m" bgcolor="#ffffff">742,833</td>
          </tr>
        </table>
      </body></html>
    HTML
    result = PassengerParser.parse(html, LATEST_URL)
    assert_equal 1, result.length
    assert_equal '1',     result[0][:rank]
    assert_equal '新宿',  result[0][:city]
    assert_equal 742_833, result[0][:total]
  end

  def test_single_row_legacy
    html = <<~HTML
      <html><body>
        <table>
          <tr>
            <td class="text-m" bgcolor="#ffffff">1</td>
            <td class="text-m" bgcolor="#ffffff">新宿</td>
            <td class="text-m" bgcolor="#ffffff">728,083</td>
          </tr>
        </table>
      </body></html>
    HTML
    result = PassengerParser.parse(html, LEGACY_URL)
    assert_equal 1, result.length
    assert_equal '1',     result[0][:rank]
    assert_equal '新宿',  result[0][:city]
    assert_equal 728_083, result[0][:total]
  end

  def test_large_total_with_multiple_commas
    html = <<~HTML
      <html><body>
        <table>
          <tr>
            <td class="text-m" bgcolor="#ffffff">1</td>
            <td class="text-m" bgcolor="#ffffff">新宿</td>
            <td class="text-m" bgcolor="#ffffff">1,234,567</td>
          </tr>
        </table>
      </body></html>
    HTML
    result = PassengerParser.parse(html, LEGACY_URL)
    assert_equal 1_234_567, result[0][:total]
  end

  def test_total_of_zero_for_missing_column
    # Legacy format: row has only rank and city columns, no total column
    html = <<~HTML
      <html><body>
        <table>
          <tr>
            <td class="text-m" bgcolor="#ffffff">1</td>
            <td class="text-m" bgcolor="#ffffff">新宿</td>
          </tr>
        </table>
      </body></html>
    HTML
    result = PassengerParser.parse(html, LEGACY_URL)
    assert_equal 1, result.length
    # :total key should be absent when column 2 does not exist
    refute result[0].key?(:total)
  end
end
