module QcloudCos
  module ConvenientApi
    # 获取 Bucket 信息
    #
    # @param bucket_name [String] :bucket (config.bucket) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Hash] 返回 Bucket 信息
    def bucket_info(bucket_name = nil)
      bucket_name ||= config.bucket
      stat('/', bucket: bucket_name)['data']
    rescue
      {}
    end

    # 返回该路径下文件和文件夹的数目
    #
    # @param path [String] 指定路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Hash]
    #
    # @example
    #  QcloudCos.count('/path/to/folder/') #=> { folder_count: 100, file_count: 1000 }
    def count(path = '/', options = {})
      result = list_folders(path, options.merge(num: 1))
      {
        folder_count: result.dircount || 0,
        file_count: result.filecount || 0
      }
    end

    # 判断该路径下是否为空
    #
    # @param path [String] 指定路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Boolean]
    def empty?(path = '/', options = {})
      count(path, options).values.uniq == 0
    end

    # 判断该路径下是否有文件
    #
    # @param path [String] 指定路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Boolean]
    def contains_file?(path = '/', options = {})
      !count(path, options)[:file_count].zero?
    end

    # 判断该路径下是否有文件夹
    #
    # @param path [String] 指定路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Boolean]
    def contains_folder?(path = '/', options = {})
      !count(path, options)[:folder_count].zero?
    end

    # 判断文件或者文件夹是否存在
    #
    # @param path [String] 指定文件路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Boolean]
    def exists?(path = '/', options = {})
      return true if path == '/' || path.to_s.empty?
      result = stat(path, options)
      result.key?('data') && result['data'].key?('name')
    rescue
      false
    end
    alias_method :exist?, :exists?

    # 获取文件外网访问地址
    #
    # @param path [String] 指定文件路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :expired (600) 指定有效期, 秒为单位
    #
    # @raise [FileNotExistError] 如果文件不存在
    # @raise [InvalidFilePathError] 如果文件路径不合法
    #
    # @return [String] 下载地址
    def public_url(path, options = {})
      path = fixed_path(path)
      bucket = validates(path, options)

      result = stat(path, options)
      if result.key?('data') && result['data'].key?('access_url')
        expired = options['expired'] || PUBLIC_EXPIRED_SECONDS
        sign = authorization.sign(bucket, expired)
        "#{result['data']['access_url']}?sign=#{sign}"
      else
        fail FileNotExistError
      end
    end

    # 列出所有文件或者目录
    #
    # @param path [String] 指定目标路径, 以 / 结尾, 则列出该目录下文件或者文件夹，不以 / 结尾，就搜索该前缀的文件或者文件夹
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [String] :pattern (eListBoth) 指定拉取的内容，可选值: eListBoth, eListDirOnly, eListFileOnly
    # @option options [Integer] :order (0) 指定拉取文件的顺序, 默认为正序(=0), 可选值: 0, 1
    #
    # @return [Hash]
    def all(path, options = {})
      results = []
      loop do
        objects = QcloudCos.list(path, options)
        results += objects.to_a
        break unless objects.has_more
        options['context'] = objects.context
      end
      results
    end
  end
end
