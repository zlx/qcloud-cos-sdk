require 'qcloud_cos/version'
require 'qcloud_cos/configuration'
require 'qcloud_cos/authorization'
require 'qcloud_cos/http'
require 'qcloud_cos/api'
require 'qcloud_cos/convenient_api'

module QcloudCos
  EXPIRED_SECONDS = 60 # 60 seconds
  PUBLIC_EXPIRED_SECONDS = 600 # 10 minutes
  DEFAULT_SLICE_SIZE = 3_145_728 # 3M
  MIN_SLICE_FILE_SIZE = 10 # 10M
  MAX_RETRY_TIMES = 3
  QCLOUD_COS_CONFIG = '.qcloud-cos.yml'
  DEFAULT_ENDPOINT = 'http://web.file.myqcloud.com/files/v1/'

  class << self
    include Api
    include ConvenientApi

    def configure
      @configuration ||= Configuration.new
      yield @configuration
      @configuration
    end

    def config
      @configuration
    end

    private

    def http
      Http.new(config)
    end

    def authorization
      Authorization.new(config)
    end

    def validates(path, options, path_validate = :file_only)
      Utils.stringify_keys!(options)

      file_validates(path, path_validate)
      num_validates(options['num'].to_i) if options['num']
      bucket_validates(options['bucket'])
    end

    def fixed_path(path)
      path.start_with?('/') ? path : "/#{path}"
    end

    def generate_rest_url(bucket, path)
      "#{config.endpoint}#{config.app_id}/#{bucket}#{path}"
    end

    def file_validates(path, path_validate)
      case path_validate.to_s
      when 'file_only'
        fail InvalidFilePathError if path.end_with?('/')
      when 'folder_only'
        FolderObject.validate(path)
      end
    end

    def num_validates(number)
      fail InvalidNumError unless number.between?(1, 199)
    end

    def bucket_validates(bucket_name)
      bucket = bucket_name || config.bucket
      fail MissingBucketError unless bucket
      bucket
    end
  end
end
