module QcloudCos
  class Utils
    class << self
      # 对 path 进行 url_encode
      def url_encode(path)
        ERB::Util.url_encode(path).gsub('%2F', '/')
      end

      # 计算 content 的大小
      def content_size(content)
        if content.respond_to?(:size)
          content.size
        elsif content.is_a?(IO)
          content.stat.size
        end
      end

      # 生成 content 的 sha
      def generate_sha(content)
        Digest::SHA1.hexdigest content
      end

      # 生成文件的 sha1 值
      def generate_file_sha(file_path)
        Digest::SHA1.file(file_path).hexdigest
      end

      # 将 hash 的 key 统一转化为 string
      def stringify_keys!(hash)
        hash.keys.each do |key|
          hash[key.to_s] = hash.delete(key)
        end
      end

      # @example
      #
      #   Utils.hash_slice({ 'a' => 1, 'b' => 2, 'c' => 3 }, 'a', 'c') # { 'a' => 1, 'c' => 3 }
      #
      # 获取 Hash 中的一部分键值对
      def hash_slice(hash, *selected_keys)
        new_hash = {}
        selected_keys.each { |k| new_hash[k] = hash[k] if hash.key?(k) }
        new_hash
      end
    end
  end
end
