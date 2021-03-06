# A wrapper for all low level http client stuff

require 'uri'
require 'curl'
require 'yajl/json_gem'
require 'queryparams'
require 'nokogiri'
require 'pathbuilder'
require 'active_support'

module Pebblebed
  class HttpError < StandardError
    attr_reader :status, :message, :response

    def initialize(message, status = nil, response = nil)
      @message = message
      @status = status
      @response = response
    end

    def not_found?
      @status_code == 404
    end

    def to_s
      "#<#{self.class.name} #{@status} #{message}>"
    end

    def inspect
      to_s
    end
  end

  class HttpNotFoundError < HttpError

  end

  module Http
    class CurlResult
      def initialize(curl_result)
        @curl_result = curl_result
      end

      def status
        @curl_result.response_code
      end

      def url
        @curl_result.url
      end

      def body
        @curl_result.body_str
      end
    end

    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)
      handle_curl_response(Curl::Easy.perform(url_with_params(url, params)))
    end

    def self.post(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      handle_curl_response(Curl::Easy.http_post(url.to_s, body) do |curl|
        curl.headers['Accept'] = 'application/json'
        curl.headers['Content-Type'] = content_type
      end)
    end

    def self.put(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      handle_curl_response(Curl::Easy.http_put(url.to_s, body) do |curl|
        curl.headers['Accept'] = 'application/json'
        curl.headers['Content-Type'] = content_type
      end)
    end

    def self.delete(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      handle_curl_response(Curl::Easy.http_delete(url_with_params(url, params)))
    end

    private

    def self.serialize_params(params)
      if String === params
        content_type, body = 'text/plain', params
      else
        content_type, body = 'application/json', JSON.dump(params)
      end
      if body.respond_to?(:encoding) and body.encoding != Encoding::UTF_8
        content_type << "; charset=#{body.encoding}"
      end
      return content_type, body
    end

    def self.handle_http_errors(result)
      if result.status == 404
        errmsg = "Resource not found: '#{result.url}'"
        errmsg << extract_error_summary(result.body)
        # ActiveSupport::SafeBuffer.new is the same as errmsg.html_safe in rails
        raise HttpNotFoundError.new(ActiveSupport::SafeBuffer.new(errmsg), result.status)
      elsif result.status >= 400
        errmsg = "Service request to '#{result.url}' failed (#{result.status}):"
        errmsg << extract_error_summary(result.body)
        raise HttpError.new(ActiveSupport::SafeBuffer.new(errmsg), result.status, result)
      end
      result
    end

    def self.handle_curl_response(curl_response)
      handle_http_errors(CurlResult.new(curl_response))
    end

    def self.url_with_params(url, params)
      url.query = QueryParams.encode(params || {})
      url.to_s
    end

    def self.url_and_params_from_args(url, params = nil, &block)
      url = URI.parse(url) unless url.is_a?(URI)
      if block_given?
        pathbuilder = PathBuilder.new.send(:instance_eval, &block)
        url = url.dup
        url.path = url.path.chomp("/")+pathbuilder.path
        (params ||= {}).merge!(pathbuilder.params)
      end
      [url, params]
    end

    def self.extract_error_summary(body)
      # Supports Sinatra error pages
      extract = Nokogiri::HTML(body).css('#summary').text.gsub(/\s+/, ' ').strip
      # TODO: Rails?
      return body if extract == ''
      extract
    end

  end
end
