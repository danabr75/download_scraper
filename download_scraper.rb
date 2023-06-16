#!/usr/bin/env ruby
# ex usage: ruby download_scraper.rb -u https://example.com -d ~/Downloads -t zip,pdf

require 'nokogiri'
require 'open-uri'
require 'openssl'
require 'net/http'
require 'fileutils'
require 'uri'
require 'addressable/uri'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: download_scraper.rb [options]"

  opts.on('-uURL', '--url=URL', 'URL to download files from') { |v| options[:url] = v }
  opts.on('-dDIR', '--dir=DIR', 'Directory to download files to') { |v| options[:dir] = v }
  opts.on('-tTYPES', '--types=TYPES', 'File types to download (comma-separated)') { |v| options[:types] = v }
end.parse!

# URL of the webpage you want to download files from
url = options[:url]

# Define your download directory
download_dir = File.expand_path(options[:dir])

# Ensure the download directory exists
FileUtils.mkdir_p(download_dir)

# File types to download
types = options[:types].split(',')

# Create URI and HTTP objects
uri = URI.parse(url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # You may want to remove this in a production setting

# Request webpage
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)

# Parse the webpage with Nokogiri
page = Nokogiri::HTML(response.body)

# Check if the page is nil
if page.nil?
  puts "Could not retrieve webpage."
  exit
end

# Find all links on the webpage
page.css('a').each do |link|
  href = link['href']

  # If the link ends with one of the provided file types
  if href =~ /.*\.(#{types.join('|')})$/
    # Make sure href is an absolute url
    href = href.start_with?('/') ? URI.join(url, Addressable::URI.encode(href)).to_s : href

    # Sanitize filename by removing invalid characters
    filename = File.basename(Addressable::URI.unencode(href)).gsub(/[^0-9A-Za-z.\-]/, '_')

    # Create the full path to the file to be saved
    download_path = File.join(download_dir, filename)

    # Download the file
    begin
      download = URI.open(href).read 
      File.open(download_path, 'wb') { |file| file.write(download) }
    rescue StandardError => e
      puts "There was an error downloading the file #{href}: #{e.message}"
    end
  end
end