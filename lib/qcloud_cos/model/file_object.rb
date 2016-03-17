require 'qcloud_cos/model/objectable'

module QcloudCos
  class FileObject
    include Objectable
    attr_accessor :access_url
    attr_accessor :source_url
    attr_accessor :biz_attr
    attr_accessor :ctime
    attr_accessor :filelen
    attr_accessor :filesize
    attr_accessor :mtime
    attr_accessor :name
    attr_accessor :sha
  end
end
