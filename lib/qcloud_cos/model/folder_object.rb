# encoding: utf-8
require 'qcloud_cos/model/objectable'

module QcloudCos
  class FolderObject
    include Objectable
    MAXLENGTH = 20
    RETAINED_SYMBOLS = %w(/ ? * : | \ < > ")
    RETAINED_FIELDS = %w(con aux nul prn com0 com1 com2 com3 com4 com5 com6 com7 com8 com9 lpt0 lpt1 lpt2 lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9)

    attr_accessor :biz_attr
    attr_accessor :ctime
    attr_accessor :mtime
    attr_accessor :name

    # 校验文件夹路径
    #
    # @param path [String] 文件夹路径
    #
    # @raise InvalidFolderPathError 如果文件夹路径不合法
    def self.validate(path)
      if !path.end_with?('/')
        fail InvalidFolderPathError, '文件夹路径必须以 / 结尾'
      elsif !(names = path.split('/')).empty?
        validate_name(names)
      end
    end

    # 校验文件夹名字
    def self.validate_name(names)
      if names.detect { |name| RETAINED_FIELDS.include?(name.downcase) }
        fail InvalidFolderPathError, %(文件夹名字不能是保留字段: '#{RETAINED_FIELDS.join("', '")}')
      elsif names.detect { |name| name.match(/[\/?*:|\\<>"]/) }
        fail InvalidFolderPathError, %(文件夹名字不能包含保留字符: '#{RETAINED_SYMBOLS.join("', '")}')
      elsif names.detect { |name| name.length > MAXLENGTH }
        fail InvalidFolderPathError, %(文件夹名字不能超过#{MAXLENGTH}个字符)
      end
    end
  end
end
