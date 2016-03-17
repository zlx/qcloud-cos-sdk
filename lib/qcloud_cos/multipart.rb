module QcloudCos
  class Multipart
    attr_reader :dst_path, :src_path, :bucket, :authorization, :result, :options

    def initialize(dst_path, src_path, options = {})
      @dst_path = dst_path
      @src_path = src_path
      @options = options
      @bucket = options.delete(:bucket)
      @authorization = options.delete(:authorization)
    end

    def upload(&block)
      init_multipart
      return if complete?
      fail QcloudCos::MissingSessionIdError unless session

      offset = @result['offset'] || 0

      while offset < filesize
        filecontent = IO.read(src_path, slice_size, offset)
        break if upload_part(offset, filecontent, &block)
        offset += slice_size
      end
    end

    private

    def init_multipart
      @result ||= QcloudCos.init_slice_upload(dst_path, filesize, sha, options.merge('sign' => sign))['data']
    end

    def upload_part(offset, content, &block)
      retry_for(QcloudCos.config.max_retry_times) do
        @result = QcloudCos.upload_part(dst_path, session, offset, content, options)['data']
        notify_progress(offset + slice_size, &block)

        return true if complete?
      end
    end

    def complete?
      @result.key?('url')
    end

    def notify_progress(progress, &block)
      progress = [progress, filesize].min
      yield((progress.to_f / filesize).round(2)) if block_given?
    end

    def filesize
      @filesize ||= File.size(src_path)
    end

    def sha
      @sha ||= Utils.generate_file_sha(src_path)
    end

    def sign
      @sign ||= authorization.sign(bucket)
    end

    def slice_size
      @slice_size ||= @result['slice_size'] || QcloudCos::DEFAULT_SLICE_SIZE
    end

    def session
      @session ||= @result['session'] || options['session']
    end

    def retry_for(max_times, &block)
      retry_times = 0
      begin
        yield if block_given?
      rescue => e
        retry_times += 1
        retry if retry_times <= max_times
        raise e
      end
    end
  end
end
