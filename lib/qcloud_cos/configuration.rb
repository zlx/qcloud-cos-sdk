module QcloudCos
  class Configuration
    attr_accessor :app_id, :secret_id, :secret_key, :bucket, :endpoint, :ssl_ca_file, :max_retry_times

    def max_retry_times
      @max_retry_times || MAX_RETRY_TIMES
    end

    def max_retry_times=(times)
      @max_retry_times = times.to_i
      @max_retry_times = MAX_RETRY_TIMES if @max_retry_times.zero?
    end
  end
end
