require 'rubygems'
require 'open-uri'
require 'net/https'
require 'hpricot'

module WWW
  class Favicon
    VERSION = '0.0.3'

    def initialize(options = {})
      @options = options
    end

    def find(url)
      html = request(URI(url)).body
      find_from_html(html, url)
    end

    def find_from_html(html, url)
      uri = URI(url)
      favicon_url = find_from_link(html, uri) || try_default_path(uri)
      if @options[:verify]
        favicon_url = nil unless valid_favicon_url?(favicon_url)
      end
      favicon_url
    end

    def valid_favicon_url?(url)
      response = request(URI.parse(url))

      (
        response.code =~ /\A2/ &&
        response.body.to_s != '' &&
        response.content_type =~ /image/i
      ) ? true : false
    end

    private

    def find_from_link(html, uri)
      doc = Hpricot(html)

      doc.search('//link').each do |link|
        if link[:rel] =~ /^(shortcut )?icon$/i
          favicon_url_or_path = link[:href]

          if favicon_url_or_path =~ /^http/
            return favicon_url_or_path
          else
            return URI.join(uri.to_s, favicon_url_or_path).to_s
          end
        end
      end

      nil
    end

    def try_default_path(uri)
      uri.path = '/favicon.ico'
      %w[query fragment].each do |element|
        uri.send element + '=', nil
      end

      response = request(uri, 'head')

      case response.code.split('').first
      when '2'
        return uri.to_s
      when '3'
        return response['Location']
      end

      nil
    end

    def request(uri, method = 'get')
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
