require_relative 'test_helper'
require 'json'

# Validates the JSON data files shipped in source/javascripts/json/.
# These files are the output of the rake json:create task and are loaded
# by the browser at runtime, so it is important that they are present,
# structurally valid, and contain sensible data.
class JsonDataTest < Minitest::Test
  JSON_DIR       = File.expand_path('../../source/javascripts/json', __FILE__)
  EXPECTED_YEARS = (1999..2012).map(&:to_s).freeze

  # ---------------------------------------------------------------------------
  # Presence
  # ---------------------------------------------------------------------------

  def test_all_expected_json_files_exist
    EXPECTED_YEARS.each do |year|
      path = File.join(JSON_DIR, "#{year}.json")
      assert File.exist?(path), "Missing JSON file for year #{year}: #{path}"
    end
  end

  def test_no_unexpected_json_files
    existing = Dir[File.join(JSON_DIR, '*.json')].map { |f| File.basename(f, '.json') }.sort
    assert_equal EXPECTED_YEARS.sort, existing, "Unexpected JSON files found"
  end

  # ---------------------------------------------------------------------------
  # Valid JSON
  # ---------------------------------------------------------------------------

  def test_all_files_contain_valid_json
    EXPECTED_YEARS.each do |year|
      path = File.join(JSON_DIR, "#{year}.json")
      begin
        JSON.parse(File.read(path))
      rescue JSON::ParserError => e
        flunk "#{year}.json contains invalid JSON: #{e.message}"
      end
    end
  end

  def test_all_files_contain_json_arrays
    EXPECTED_YEARS.each do |year|
      data = parsed_json(year)
      assert_instance_of Array, data, "#{year}.json should be a JSON array"
    end
  end

  # ---------------------------------------------------------------------------
  # Structure of each entry
  # ---------------------------------------------------------------------------

  def test_all_entries_have_rank_key
    EXPECTED_YEARS.each do |year|
      parsed_json(year).each_with_index do |entry, idx|
        assert entry.key?('rank'),
          "#{year}.json entry[#{idx}] missing 'rank' key: #{entry.inspect}"
      end
    end
  end

  def test_all_entries_have_city_key
    EXPECTED_YEARS.each do |year|
      parsed_json(year).each_with_index do |entry, idx|
        assert entry.key?('city'),
          "#{year}.json entry[#{idx}] missing 'city' key: #{entry.inspect}"
      end
    end
  end

  def test_all_entries_have_total_key
    EXPECTED_YEARS.each do |year|
      parsed_json(year).each_with_index do |entry, idx|
        assert entry.key?('total'),
          "#{year}.json entry[#{idx}] missing 'total' key: #{entry.inspect}"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Data integrity
  # ---------------------------------------------------------------------------

  def test_all_totals_are_positive_integers
    EXPECTED_YEARS.each do |year|
      parsed_json(year).each_with_index do |entry, idx|
        total = entry['total']
        assert_kind_of Integer, total,
          "#{year}.json entry[#{idx}] total should be an Integer, got #{total.inspect}"
        assert total > 0,
          "#{year}.json entry[#{idx}] total should be positive, got #{total}"
      end
    end
  end

  def test_all_city_names_are_non_empty_strings
    EXPECTED_YEARS.each do |year|
      parsed_json(year).each_with_index do |entry, idx|
        city = entry['city']
        assert_kind_of String, city,
          "#{year}.json entry[#{idx}] city should be a String"
        refute city.empty?,
          "#{year}.json entry[#{idx}] city should not be empty"
      end
    end
  end

  def test_all_city_names_have_no_leading_or_trailing_whitespace
    EXPECTED_YEARS.each do |year|
      parsed_json(year).each_with_index do |entry, idx|
        city = entry['city']
        assert_equal city.strip, city,
          "#{year}.json entry[#{idx}] city has leading/trailing whitespace: #{city.inspect}"
      end
    end
  end

  def test_all_rank_values_are_non_empty_strings
    EXPECTED_YEARS.each do |year|
      parsed_json(year).each_with_index do |entry, idx|
        rank = entry['rank']
        assert_kind_of String, rank,
          "#{year}.json entry[#{idx}] rank should be a String"
        refute rank.empty?,
          "#{year}.json entry[#{idx}] rank should not be empty"
      end
    end
  end

  def test_each_file_has_at_least_one_entry
    EXPECTED_YEARS.each do |year|
      data = parsed_json(year)
      assert data.length > 0, "#{year}.json should have at least one entry"
    end
  end

  def test_each_file_has_at_most_100_entries
    EXPECTED_YEARS.each do |year|
      data = parsed_json(year)
      assert data.length <= 100,
        "#{year}.json has #{data.length} entries, expected at most 100"
    end
  end

  # ---------------------------------------------------------------------------
  # Known top-ranked stations
  # ---------------------------------------------------------------------------

  def test_shinjuku_is_ranked_first_in_2012
    data = parsed_json('2012')
    first = data[0]
    assert_equal '新宿', first['city'],
      "Expected 新宿 to be ranked #1 in 2012, got #{first['city']}"
  end

  def test_shinjuku_appears_in_every_year
    EXPECTED_YEARS.each do |year|
      cities = parsed_json(year).map { |e| e['city'] }
      assert cities.include?('新宿'),
        "新宿 not found in #{year}.json"
    end
  end

  def test_2012_shinjuku_total_is_correct
    data   = parsed_json('2012')
    shinjuku = data.find { |e| e['city'] == '新宿' }
    assert_equal 742_833, shinjuku['total']
  end

  # ---------------------------------------------------------------------------
  # No duplicate cities within a year
  # ---------------------------------------------------------------------------

  def test_no_duplicate_cities_within_a_year
    EXPECTED_YEARS.each do |year|
      cities    = parsed_json(year).map { |e| e['city'] }
      duplicates = cities.group_by(&:itself).select { |_, v| v.length > 1 }.keys
      assert duplicates.empty?,
        "#{year}.json contains duplicate city entries: #{duplicates.inspect}"
    end
  end

  private

  def parsed_json(year)
    path = File.join(JSON_DIR, "#{year}.json")
    JSON.parse(File.read(path))
  end
end
