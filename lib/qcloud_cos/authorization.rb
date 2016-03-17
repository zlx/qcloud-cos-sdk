# encoding: utf-8

require 'base64'
require 'openssl'
require 'digest'

module QcloudCos
  class Authorization
    attr_reader :config

    # 用于对请求进行签名
    # @param config [Configration] specify configuration for sign
    #
    def initialize(config)
      @config = config
    end

    # 生成单次有效签名
    #
    # @param bucket [String] 指定 Bucket 名字
    # @param fileid [String] 指定要签名的资源
    def sign_once(bucket, fileid)
      sign_base(bucket, fileid, 0)
    end

    # 生成多次有效签名
    #
    # @param bucket [String] 指定 Bucket 名字
    # @param expired [Integer] (EXPIRED_SECONDS) 指定签名过期时间, 秒作为单位
    def sign_more(bucket, expired = EXPIRED_SECONDS)
      sign_base(bucket, nil, current_time + expired)
    end
    alias_method :sign, :sign_more

    private

    def sign_base(bucket, fileid, expired)
      fileid = "/#{app_id}#{fileid}" if fileid

      src_str = "a=#{app_id}&b=#{bucket}&k=#{secret_id}&e=#{expired}&t=#{current_time}&r=#{rdm}&f=#{fileid}"

      Base64.encode64("#{OpenSSL::HMAC.digest('sha1', secret_key, src_str)}#{src_str}").delete("\n").strip
    end

    def app_id
      config.app_id
    end

    def secret_id
      config.secret_id
    end

    def secret_key
      config.secret_key
    end

    def current_time
      Time.now.to_i
    end

    def rdm
      rand(10**9)
    end
  end
end
