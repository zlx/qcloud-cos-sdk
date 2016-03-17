require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'qcloud_cos'

require 'minitest/autorun'
require 'mocha/mini_test'
require 'webmock/minitest'

def init_config
  QcloudCos.configure do |config|
    config.app_id = 'app-id'
    config.secret_id = 'secret_id'
    config.secret_key = 'secret_key'
    config.endpoint = 'http://mock-server.com/v1/'
    config.bucket = 'privatesdkdemo'
  end
end

def stub_client_request(verb, path, request = {}, response = {})
  request.merge!(headers: { 'Authorization' => /\S*/ })
  body = response.key?(:file_path) ? File.new(File.expand_path("test/fixtures/#{response.delete(:file_path)}")) : response[:body]
  headers = { 'Content-Type' => 'application/json' }.merge(response[:headers] || {})
  response.merge!(
    status: response[:status] || 200,
    body: body || { code: 0 }.to_json,
    headers: headers
  )
  url = "#{QcloudCos.config.endpoint}#{QcloudCos.config.app_id}/#{QcloudCos.config.bucket}#{path}"
  stub_request(verb, url).with(request).to_return(response)
end

def reset_const(klass, const_name, value)
  klass.send(:remove_const, const_name) if klass.const_defined?(const_name)
  klass.const_set(const_name, value)
end
