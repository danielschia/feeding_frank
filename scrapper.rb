require 'selenium-webdriver'
require 'thread'

class ConcurrentWebScrapingBot
  def initialize(urls, cooldown)
    @urls = urls
    @cooldown = cooldown
    @threads = []
  end

  def scrape_url(url)
    driver = Selenium::WebDriver.for :chrome
    begin
      driver.navigate.to url

      # Wait for the page to fully load
      sleep 5

      # Extract only the content from the <section class="article-info">
      article_info_section = driver.find_element(css: 'section.article-info')

      if article_info_section
        article_info_html = article_info_section.attribute('innerHTML')
        match = url.match(/articles\/(.+)/)

        if match
          result = match[1]
          result = "#{result}.html"
          File.open(result, 'w') do |file|
            file.write(article_info_html.strip)
          end
          puts "Extracted content from article-info: #{result}"
        else
          puts "No match found for URL: #{url}"
        end
      else
        puts "No 'article-info' section found for URL: #{url}"
      end
    rescue StandardError => e
      puts "An error occurred while scraping #{url}: #{e.message}"
    ensure
      driver.quit
    end
  end

  def scrape
    @urls.each do |url|
      @threads << Thread.new do
        scrape_url(url)
        sleep @cooldown
      end
    end

    # Wait for all threads to finish
    @threads.each(&:join)
  end
end

# List of URLs to scrape
urls = [
  'https://support.duda.co/hc/en-us/articles/26519221644439-Editor-Overview',
  'https://support.duda.co/hc/en-us/articles/26519259154199-Editor-Versions',
  # Add more URLs here
]

# Cooldown period in seconds
cooldown_period = 5  # Adjust as necessary

# Create a bot instance and start scraping
bot = ConcurrentWebScrapingBot.new(urls, cooldown_period)
bot.scrape
