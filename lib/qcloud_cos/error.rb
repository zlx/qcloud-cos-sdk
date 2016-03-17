# encoding: utf-8
module QcloudCos
  class Error < StandardError; end

  class RequestError < Error
    attr_reader :code
    attr_reader :message
    attr_reader :origin_response

    def initialize(response)
      if response.parsed_response.key?('code')
        @code = response.parsed_response['code']
        @message = response.parsed_response['message']
      end
      @origin_response = response
      super("API ERROR Code=#{@code}, Message=#{@message}")
    end
  end

  class InvalidFolderPathError < Error
    def initialize(msg)
      super(msg)
    end
  end

  class InvalidFilePathError < Error
    def initialize
      super('文件名不能以 / 结尾')
    end
  end

  class FileNotExistError < Error
    def initialize
      super('文件不存在')
    end
  end

  class MissingBucketError < Error
    def initialize
      super('缺少 Bucket 参数或者 Bucket 不存在')
    end
  end

  class MissingSessionIdError < Error
    def initialize
      super('分片上传不能缺少 Session ID')
    end
  end

  class InvalidNumError < Error
    def initialize
      super('单次列取目录数量必须在1~199')
    end
  end
end
