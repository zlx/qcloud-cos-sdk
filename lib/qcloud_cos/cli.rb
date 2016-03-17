# encoding: utf-8
require 'rubygems'
require 'commander'
require 'awesome_print'
require 'qcloud_cos'

module QcloudCos
  class Cli
    include Commander::Methods

    QCLOUD_COS_ENV_MAPPING = {
      app_id: 'QCLOUD_COS_APP_ID',
      secret_id: 'QCLOUD_COS_SECRET_ID',
      secret_key: 'QCLOUD_COS_SECRET_KEY',
      endpoint: 'QCLOUD_COS_ENDPOINT',
      bucket: 'QCLOUD_COS_BUCKET',
      ssl_ca_file: 'QCLOUD_COS_SSL_CA_FILE',
      max_retry_times: 'QCLOUD_COS_MAX_RETRY_TIMES'
    }

    # 交互模式配置环境
    # 命令: $ qcloud-cos config
    def self.config(config_path = nil)
      config_path ||= QcloudCos::QCLOUD_COS_CONFIG
      return Commander::UI.say_error("#{config_path} already exist, remove it first or direct edit it!") if File.exist?(config_path)

      app_id = Commander::UI.ask 'Qcloud COS APP ID: '
      return Commander::UI.say_error('Missing Qcloud COS APP ID') if app_id.empty?

      secret_id = Commander::UI.ask 'Qcloud COS Secret ID: '
      return Commander::UI.say_error('Missing Qcloud COS Secret ID') if secret_id.empty?

      secret_key = Commander::UI.ask 'Qcloud COS Secret Key: '
      return Commander::UI.say_error('Missing Qcloud COS Secret Key') if secret_key.empty?

      endpoint = Commander::UI.ask "Default Qcloud COS Endpoint [#{QcloudCos::DEFAULT_ENDPOINT}]: "
      endpoint = QcloudCos::DEFAULT_ENDPOINT if endpoint.empty?
      bucket = Commander::UI.ask 'Default Qcloud COS Bucket: '

      write_config(config_path, app_id: app_id, secret_id: secret_id, secret_key: secret_key, endpoint: endpoint, bucket: bucket)
    end

    # 检查环境是否配置
    #
    # @return [Boolean]
    def self.environment_configed?
      configed = File.exist?(QcloudCos::QCLOUD_COS_CONFIG) || !ENV['QCLOUD_COS_APP_ID'].to_s.empty?
      Commander::UI.say_error('Use `qcloud-cos config` first or export your environments') unless configed
      configed
    end

    # 检查环境，初始化 Cli
    def self.init
      QcloudCos.configure do |config|
        load_config.each { |k, v| config.send("#{k}=", v) }
      end

      new
    end

    # 查看信息
    # 命令： $ qcloud-cos info [options] [dest_path]
    #
    # @example
    #   # 查看 Bucket 信息
    #   qcloud-cos info
    #
    #   # 查看 /production.log 信息
    #   qcloud-cos info /production.log
    #
    #   # 查看 /test/ 信息
    #   qcloud-cos info /test/
    #
    #   # 查看 bucket2 上的 /production.log 信息
    #   qcloud-cos info --bucket bucket2 /production.log
    def info(args, options)
      path = args.shift || '/'
      opts = parse_options(options)

      QcloudCos.stat(path, opts)['data']
    end

    # 列出文件或者文件夹
    # 使用： $ qcloud-cos list [options] [dest_path]
    #
    # @example
    #
    #   # 列出 / 下面的所有对象
    #   qcloud-cos list
    #
    #   # 列出 /test/ 下面的所有对象
    #   qcloud-cos list /test/
    #
    #   # 列出 /test/ 下面的前 10 个对象
    #   qcloud-cos list --num 10 /test/
    #
    #   # 列出 bucket2 的 /test/ 下面的所有对象
    #   qcloud-cos list --bucket bucket2 /test/
    #
    def list(args, options)
      path = args.shift || '/'
      opts = parse_options(options)

      objects = QcloudCos.list(path, opts)
      objects.map do |object|
        File.join(path, object.is_a?(QcloudCos::FolderObject) ? "#{object.name}/" : object.name)
      end
    end

    # 上传文件或者目录到 COS
    # 命令: qcloud-cos upload [options] file [dest_path]
    #
    # @example
    #
    #   # 把 production.log 上传到 /
    #   qcloud-cos upload production.log
    #
    #   # 把 production.log 上传到 /data/ 下面
    #   qcloud-cos upload production.log /data/
    #
    #   # 把 ./test/ 整个文件夹上传到 /data/ 下面
    #   qcloud-cos upload test/ /data/
    #
    #   # 把 ./test/ 整个文件夹上传到 bucket2 的 /data/ 下面
    #   qcloud-cos upload --bucket bucket2 test/ /data/
    def upload(args, options)
      path = args.shift
      return Commander::UI.say_error('file missing, see example: $ qcloud-cos upload -h') unless path
      return Commander::UI.say_error("file #{path} not exist") unless File.exist?(path)

      dest_path = args.shift || '/'
      return Commander::UI.say_error('dest_path must end with /, see example: $ qcloud-cos upload -h') unless dest_path.end_with?('/')

      if path.end_with?('/')
        upload_folder(path, dest_path, parse_options(options))
      else
        upload_file(path, dest_path, parse_options(options))
      end
    end

    # 下载文件或者目录
    # 命令: $ qcloud-cos download [options] dest_path [save_path]
    #
    # @example
    #
    #   # 把 /data/production.log 下载到当前目录
    #   qcloud-cos download /data/production.log
    #
    #   # 把 /data/production.log 下载到 ./data/ 下
    #   qcloud-cos download /data/production.log ./data
    #
    #   # 把 /data/test/ 整个目录下载并保存到 ./data/ 目录下面
    #   qcloud-cos download /data/test/ ./data
    #
    #   # 把 bucket2 下的 /data/test/ 整个目录下载并保存到 ./data/ 下面
    #   qcloud-cos download --bucket bucket2 /data/test/ ./data
    #
    def download(args, options)
      path = args.shift
      return Commander::UI.say_error('missing path, see example: $ qcloud-cos download -h') unless path
      opts = parse_options(options)
      save_path = args.shift || '.'

      if path.end_with?('/')
        download_folder(path, save_path, opts)
      else
        download_file(path, save_path, opts)
      end
    end

    # 删除目录或者文件夹
    # 命令: $ qcloud-cos remove [options] dest_path
    #
    # @example
    #
    #   # 删除文件/data/production.log
    #   qcloud-cos remove /data/production.log
    #
    #   # 删除目录 /data/test/， 目录非空会失败
    #   qcloud-cos remove /data/test/
    #
    #   # 级联删除目录 /data/test/
    #   qcloud-cos remove --recursive /data/test/
    #
    #   # 删除 bucket2 下面的目录 /data/test/
    #   qcloud-cos remove --bucket bucket2 /data/test/
    def remove(args, options)
      path = args.shift
      return Commander::UI.say_error('missing dest_path, see example: $ qcloud-cos remove -h') unless path
      opts = parse_options(options)

      if path.end_with?('/')
        QcloudCos.delete_folder(path, opts.merge(recursive: !!options.recursive))
      else
        QcloudCos.delete_file(path, opts)
      end
    end

    private

    def upload_file(path, dest_path, opts)
      dest_path = File.join(dest_path, path.split('/').last)

      create_file_with_lint(path, dest_path) do
        if File.size(path) > opts[:min]
          QcloudCos.upload_slice(dest_path, path, Utils.hash_slice(opts, :bucket).merge(slice_size: opts[:size]))
        else
          QcloudCos.upload(dest_path, File.new(path), Utils.hash_slice(opts, :bucket))
        end
      end
    end

    def create_file_with_lint(path, dest_path, &block)
      yield if block_given?
      Commander::UI.say_ok "#{path} uploaded to #{dest_path}..."
    rescue => e
      Commander::UI.say_error "Failed when uploaded #{path} ===> #{e.message}"
    end

    def upload_folder(path, dest_path, opts)
      path_map = find_upload_path_map(path, dest_path)

      path_map.each do |file_path, dest|
        if file_path.end_with?('/')
          create_folder_with_lint(dest, opts)
        else
          upload_file(file_path, dest, opts)
        end
      end
    end

    def create_folder_with_lint(dest, opts)
      QcloudCos.create_folder(dest, opts)
      Commander::UI.say_ok "Create folder #{dest}"
    rescue => e
      Commander::UI.say_ok "Failed when create folder #{dest} ====> #{e.message}"
    end

    def find_upload_path_map(path, dest_path)
      path_map = Hash[Dir.glob("#{path}**/*").map do |file_path|
        file_path = File.join(file_path, '') unless File.file?(file_path)
        [file_path, find_upload_dest_path(file_path, path, dest_path)]
      end]
      remove_subdirectories!(path_map)
      path_map
    end

    def find_upload_dest_path(file_path, parent_path, dest_path)
      split_path = file_path.sub(parent_path, '').split('/')
      if File.file?(file_path)
        split_path.size > 1 ? File.join(dest_path, *split_path[0..-2]) : dest_path
      else
        File.join(dest_path, *split_path, '')
      end
    end

    def download_file(path, save_path, opts)
      FileUtils.mkdir_p(save_path) unless File.exist?(save_path)

      file_path = File.join(save_path, path.split('/').last)
      signed_access_url = opts[:access_url] ? opts.delete(:access_url) : QcloudCos.public_url(path, opts)
      save_to_file(signed_access_url, file_path)
      Commander::UI.say_ok("Save #{path} to #{file_path}")
    rescue => e
      Commander::UI.say_error("Failed when Download #{path}  ===> #{e.message}")
    end

    def download_folder(path, save_path, opts)
      mkdir_with_lint(path, save_path)

      QcloudCos.all(path, opts).each do |object|
        new_path = "#{path}#{object.name}"

        if object.is_a?(QcloudCos::FolderObject)
          download_folder(File.join(new_path, ''), File.join(save_path, object.name), opts)
        elsif object.is_a?(QcloudCos::FileObject)
          download_file(new_path, save_path, opts.merge(access_url: object.access_url))
        end
      end
    end

    def mkdir_with_lint(path, save_path)
      return if File.exist?(save_path)
      FileUtils.mkdir_p(save_path)
      Commander::UI.say_ok "Save #{path} to #{save_path}/"
    end

    def self.load_config
      file_config = load_file_config

      config = {}
      QCLOUD_COS_ENV_MAPPING.each do |key, env_name|
        config[key] = ENV[env_name] || file_config[key.to_s]
      end
      config
    end

    def self.load_file_config
      return {} unless File.exist?(QcloudCos::QCLOUD_COS_CONFIG)

      Hash[File.open(QcloudCos::QCLOUD_COS_CONFIG).map do |line|
        key, value = line.split('=')
        value.chomp!.empty? ? nil : [key, value]
      end.compact]
    end

    def parse_options(options)
      opts = {}
      opts[:bucket] = options.bucket if options.bucket
      opts[:min] = options.min if options.min
      opts[:size] = options.size if options.size
      opts[:num] = options.num if options.num
      opts
    end

    def remove_subdirectories!(path_map)
      new_map = path_map.dup
      new_map.each do |_, dest_path|
        path_map.reject! do |file_path, dest|
          file_path.end_with?('/') && dest_path.start_with?(dest)
        end
      end
    end

    def save_to_file(access_url, file_path)
      File.open(file_path, 'wb') do |f|
        f.write HTTParty.get(access_url)
      end
    end

    def self.write_config(config_path, options)
      File.open(config_path, 'w') do |file|
        file.puts "app_id=#{options[:app_id]}"
        file.puts "secret_id=#{options[:secret_id]}"
        file.puts "secret_key=#{options[:secret_key]}"
        file.puts "endpoint=#{options[:endpoint]}"
        file.puts "bucket=#{options[:bucket]}"
        file.puts 'ssl_ca_file='
        file.puts 'max_retry_times='
      end
    end
  end
end
