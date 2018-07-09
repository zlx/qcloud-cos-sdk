# encoding: utf-8
require 'qcloud_cos/utils'
require 'qcloud_cos/multipart'
require 'qcloud_cos/model/list'

module QcloudCos
  module Api
    # 列出文件或者目录
    #
    # @param path [String] 指定目标路径, 以 / 结尾, 则列出该目录下文件或者文件夹，不以 / 结尾，就搜索该前缀的文件或者文件夹
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :num (100) 指定需要拉取的条目, 可选范围: 1~199
    # @option options [String] :pattern (eListBoth) 指定拉取的内容，可选值: eListBoth, eListDirOnly, eListFileOnly
    # @option options [Integer] :order (0) 指定拉取文件的顺序, 默认为正序(=0), 可选值: 0, 1
    # @option options [String] :context ("") 透传字段，查看第一页，则传空字符串。若需要翻页，需要将前一页返回值中的context透传到参数中。order用于指定翻页顺序。若order填0，则从当前页正序/往下翻页；若order填1，则从当前页倒序/往上翻页。
    #
    # @return [Hash]
    def list(path = '/', options = {})
      path = fixed_path(path)
      bucket = validates(path, options, 'both')

      query = {
        'op' => 'list',
        'num' => 100
      }.merge(Utils.hash_slice(options, 'num', 'pattern', 'order', 'context'))

      url = generate_rest_url(bucket, path)
      sign = authorization.sign(bucket)

      result = http.get(url, query: query, headers: { 'Authorization' => sign }).parsed_response
      QcloudCos::List.new(result['data'])
    end

    # 列出所有文件
    #
    # @param path [String] 指定目标路径, 以 / 结尾, 则列出该目录下文件，不以 / 结尾，就搜索该前缀的文件
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :num (100) 指定需要拉取的条目
    # @option options [Integer] :order (0) 指定拉取文件的顺序, 默认为正序(=0), 可选值: 0, 1
    # @option options [String] :context ("") 透传字段，查看第一页，则传空字符串。若需要翻页，需要将前一页返回值中的context透传到参数中。order用于指定翻页顺序。若order填0，则从当前页正序/往下翻页；若order填1，则从当前页倒序/往上翻页。
    #
    # @return [Hash]
    def list_files(path = '/', options = {})
      Utils.stringify_keys!(options)
      list(path, options.merge('pattern' => 'eListFileOnly'))
    end

    # 列出所有目录
    #
    # @param path [String] 指定目标路径, 以 / 结尾, 则列出该目录下文件夹，不以 / 结尾，就搜索该前缀的文件夹
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :num (100) 指定需要拉取的条目
    # @option options [Integer] :order (0) 指定拉取文件的顺序, 默认为正序(=0), 可选值: 0, 1
    # @option options [String] :context ("") 透传字段，查看第一页，则传空字符串。若需要翻页，需要将前一页返回值中的context透传到参数中。order用于指定翻页顺序。若order填0，则从当前页正序/往下翻页；若order填1，则从当前页倒序/往上翻页。
    #
    # @return [Hash]
    def list_folders(path = '/', options = {})
      Utils.stringify_keys!(options)
      list(path, options.merge('pattern' => 'eListDirOnly'))
    end

    # 创建目录
    #
    # @param path [String] 指定要创建的文件夹名字，支持级联创建
    # @param options [Hash] options
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :biz_attr 指定目录的 biz_attr 由业务端维护, 会在文件信息中返回
    #
    # @return [Hash]
    def create_folder(path, options = {})
      path = fixed_path(path)
      bucket = validates(path, options, :folder_only)

      url = generate_rest_url(bucket, path)

      query = { 'op' => 'create' }.merge(Utils.hash_slice(options, 'biz_attr'))

      headers = {
        'Authorization' => authorization.sign(bucket),
        'Content-Type' => 'application/json'
      }

      http.post(url, body: query.to_json, headers: headers).parsed_response
    end

    # 上传文件
    #
    # @param path [String] 指定上传文件的路径
    # @param file_or_bin [File||String] 指定文件或者文件内容
    # @param options [Hash] options
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :biz_attr 指定文件的 biz_attr 由业务端维护, 会在文件信息中返回
    #
    # @return [Hash]
    def upload(path, file_or_bin, options = {})
      path = fixed_path(path)
      bucket = validates(path, options)

      url = generate_rest_url(bucket, path)

      query = {
        'op' => 'upload'
      }.merge(Utils.hash_slice(options, 'biz_attr')).merge(generate_file_query(file_or_bin))

      http.post(url, query: query, headers: { 'Authorization' => authorization.sign(bucket) }).parsed_response
    end
    alias_method :create, :upload

    # 分片上传
    #
    # @example
    #
    #   upload_slice('/data/test.log', 'test.log') do |pr|
    #     puts "uploaded #{pr * 100}%"
    #   end
    #
    # @param dst_path [String] 指定文件的目标路径
    # @param src_path [String] 指定文件的本地路径
    # @param block [Block] 指定 Block 来显示进度提示
    # @param options [Hash] options
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :biz_attr 指定文件的 biz_attr 由业务端维护, 会在文件信息中返回
    # @option options [Integer] :session 指定本次分片上传的 session
    # @option options [Integer] :slice_size 指定分片大小
    #
    # @raise [MissingSessionIdError] 如果缺少 session
    # @raise [FileNotExistError] 如果本地文件不存在
    # @raise [InvalidFilePathError] 如果目标路径是非法文件路径
    #
    # @return [Hash]
    def upload_slice(dst_path, src_path, options = {}, &block)
      dst_path = fixed_path(dst_path)
      fail FileNotExistError unless File.exist?(src_path)
      bucket = validates(dst_path, options)

      multipart = QcloudCos::Multipart.new(
        dst_path,
        src_path,
        options.merge(bucket: bucket, authorization: authorization)
      )
      multipart.upload(&block)
      multipart.result
    end

    # 初始化分片上传
    #
    # @param path [String] 指定上传文件的路径
    # @param filesize [Integer] 指定文件总大小
    # @param sha [String] 指定该文件的 sha 值
    # @param options [Hash] options
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Integer] :biz_attr 指定文件的 biz_attr 由业务端维护, 会在文件信息中返回
    # @option options [Integer] :session 如果想要断点续传,则带上上一次的session
    # @option options [Integer] :slice_size 指定分片大小
    #
    # @return [Hash]
    def init_slice_upload(path, filesize, sha, options = {})
      path = fixed_path(path)
      bucket = validates(path, options)

      url = generate_rest_url(bucket, path)
      query = generate_slice_upload_query(filesize, sha, options)
      sign = options['sign'] || authorization.sign(bucket)

      http.post(url, query: query, headers: { 'Authorization' => sign }).parsed_response
    end

    # 上传分片数据
    #
    # @param path [String] 指定上传文件的路径
    # @param session [String] 指定分片上传的 session id
    # @param offset [Integer] 本次分片位移
    # @param content [Binary] 指定文件内容
    # @param options [Hash] options
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Hash]
    def upload_part(path, session, offset, content, options = {})
      path = fixed_path(path)
      bucket = validates(path, options)

      url = generate_rest_url(bucket, path)
      query = generate_upload_part_query(session, offset, content)
      sign = options['sign'] || authorization.sign(bucket)

      http.post(url, query: query, headers: { 'Authorization' => sign }).parsed_response
    end

    # 更新文件或者目录信息
    #
    # @param path [String] 指定文件或者目录路径
    # @param biz_attr [String] 指定文件或者目录的 biz_attr
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Hash]
    def update(path, biz_attr, options = {})
      path = fixed_path(path)
      bucket = validates(path, options, 'both')
      url = generate_rest_url(bucket, path)

      query = { 'op' => 'update', 'biz_attr' => biz_attr }

      resource = "/#{bucket}#{Utils.url_encode(path)}"
      headers = {
        'Authorization' => authorization.sign_once(bucket, resource),
        'Content-Type' => 'application/json'
      }

      http.post(url, body: query.to_json, headers: headers).parsed_response
    end

    # 删除文件或者目录
    #
    # @param path [String] 指定文件或者目录路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Hash]
    def delete(path, options = {})
      path = fixed_path(path)
      bucket = validates(path, options, 'both')
      url = generate_rest_url(bucket, path)

      query = { 'op' => 'delete' }

      resource = "/#{bucket}#{Utils.url_encode(path)}"
      headers = {
        'Authorization' => authorization.sign_once(bucket, resource),
        'Content-Type' => 'application/json'
      }

      http.post(url, body: query.to_json, headers: headers).parsed_response
    end

    # 删除目录
    #
    # @param path [String] 指定目录路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    # @option options [Boolean] :recursive (false) 指定是否需要级连删除
    #
    # @raise [InvalidFolderPathError] 如果路径是非法文件夹路径
    #
    # @return [Hash]
    def delete_folder(path, options = {})
      validates(path, options, 'folder_only')

      return delete(path, options) if options['recursive'] != true

      all(path, options).each do |object|
        if object.is_a?(QcloudCos::FolderObject)
          delete_folder("#{path}#{object.name}/", options)
        elsif object.is_a?(QcloudCos::FileObject)
          delete_file("#{path}#{object.name}", options)
        end
      end
      delete(path)
    end

    # 删除文件
    #
    # @param path [String] 指定文件路径
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @raise [InvalidFilePathError] 如果文件路径不合法
    #
    # @return [Hash]
    def delete_file(path, options = {})
      fail InvalidFilePathError if path.end_with?('/')
      delete(path, options)
    end

    # 查看文件或者文件夹信息
    #
    # @param path [String] 指定文件或者文件夹目录
    # @param options [Hash] 额外参数
    # @option options [String] :bucket (config.bucket_name) 指定当前 bucket, 默认是配置里面的 bucket
    #
    # @return [Hash]
    def stat(path, options = {})
      path = fixed_path(path)
      bucket = validates(path, options, 'both')
      url = generate_rest_url(bucket, path)

      query = { 'op' => 'stat' }
      sign = authorization.sign(bucket)

      http.get(url, query: query, headers: { 'Authorization' => sign }).parsed_response
    end

    private

    def generate_slice_upload_query(filesize, sha, options)
      {
        'op' => 'upload_slice',
        'filesize' => filesize,
        'sha' => sha,
        'filecontent' => Tempfile.new("temp-#{Time.now.to_i}")
      }.merge(Utils.hash_slice(options, 'biz_attr', 'session', 'slice_size'))
    end

    def generate_upload_part_query(session, offset, content)
      {
        'op' => 'upload_slice',
        'session' => session,
        'offset' => offset
      }.merge(generate_file_query(content))
    end

    def generate_file_query(file_or_bin)
      query = {}
      if file_or_bin.respond_to?(:read)
        query['filecontent'] = file_or_bin
        query['sha'] = Utils.generate_sha(IO.binread(file_or_bin))
      else
        query['filecontent'] = generate_tempfile(file_or_bin)
        query['sha'] = Utils.generate_sha(file_or_bin)
      end
      query
    end

    def ensure_utf8_encoding(file_content)
      file_content.force_encoding('UTF-8')
    end

    def generate_tempfile(file_or_bin)
      tempfile = Tempfile.new("temp-#{Time.now.to_i}")
      tempfile.write(ensure_utf8_encoding(file_or_bin))
      tempfile.rewind
      tempfile
    end
  end
end
