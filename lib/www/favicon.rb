require 'rubygems'
require 'open-uri'
require 'net/https'
require 'hpricot'

module WWW
  class Favicon
    VERSION = '0.0.4'

    def find(url)
      html = request(url).body
      find_from_html(html, url)
    end

    def find_from_html(html, url)
      favicon_url = find_from_link(html, url) || default_path(url)

      return nil unless valid_favicon_url?(favicon_url)

      favicon_url
    end

    def valid_favicon_url?(url, limit = 10)
      return false if limit == 0

      response = request(url)

      if response.kind_of?(Net::HTTPRedirection)
        valid_favicon_url?(response['Location'], limit - 1)
      else
        (
          response.code =~ /\A2/ &&
          response.body.to_s != '' &&
          response.content_type =~ /image/i
          ) ? true : false
      end
    end

    private

    def find_from_link(html, url)
      doc = Hpricot(html)

      doc.search('//link').each do |link|
        if link[:rel] =~ /^(shortcut )?icon$/i
          favicon_url_or_path = link[:href]

          if favicon_url_or_path =~ /^http/
            return favicon_url_or_path
          else
            return URI.join(url, favicon_url_or_path).to_s
          end
        end
      end

      nil
    end

    def default_path(url)
      uri = URI(url)
      uri.path = '/favicon.ico'
      %w[query fragment].each do |element|
        uri.send element + '=', nil
      end

      uri.to_s
    end

    def request(url, method = 'get')
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.start do |http|
        path =
          (uri.path.empty? ? '/' : uri.path) +
          (uri.query       ? '?' + uri.query : '') +
          (uri.fragment    ? '#' + uri.fragment : '')
        response = http.send(method, path)
      end
    end
  end
end
