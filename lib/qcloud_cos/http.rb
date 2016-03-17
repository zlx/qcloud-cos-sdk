require 'httparty'
require 'httmultiparty'
require 'addressable/uri'
require 'qcloud_cos/error'

module QcloudCos
  class Http
    include HTTParty
    include HTTMultiParty

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def get(url, options = {})
      request('GET', url, options)
    end

    def post(url, options = {})
      request('POST', url, options)
    end

    private

    def request(verb, url, options = {})
      query = options.fetch(:query, {})
      headers = options.fetch(:headers, {})
      body = options.delete(:body)

      append_headers!(headers, verb, body, options)
      options = { headers: headers, query: query, body: body }
      append_options!(options, url)

      wrap(self.class.__send__(verb.downcase, url, options))
    end

    def wrap(response)
      if response.code == 200 && response.parsed_response['code'] == 0
        response
      else
        fail RequestError, response
      end
    end

    def append_headers!(headers, _verb, body, _options)
      append_default_headers!(headers)
      append_body_headers!(headers, body)
    end

    def append_options!(options, url)
      options.merge!(uri_adapter: Addressable::URI)
      if config.ssl_ca_file
        options.merge!(ssl_ca_file: config.ssl_ca_file)
      elsif url.start_with?('https://')
        options.merge!(verify_peer: true)
      end
    end

    def append_default_headers!(headers)
      headers.merge!(default_headers)
    end

    def append_body_headers!(headers, body)
      headers.merge!('Content-Length' => Utils.content_size(body).to_s) if body
    end

    def default_headers
      {
        'User-Agent' => user_agent,
        'Host' => 'web.file.myqcloud.com'
      }
    end

    def user_agent
      "qcloud-cos-sdk-ruby/#{QcloudCos::VERSION} " \
      "(#{RbConfig::CONFIG['host_os']} ruby-#{RbConfig::CONFIG['ruby_version']})"
    end
  end
end
