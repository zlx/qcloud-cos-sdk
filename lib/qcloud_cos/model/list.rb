require 'qcloud_cos/model/file_object'
require 'qcloud_cos/model/folder_object'
require 'forwardable'

module QcloudCos
  class List
    include Enumerable
    extend Forwardable

    attr_reader :context, :dircount, :filecount, :has_more
    def_delegators :@objects, :[], :each, :size, :inspect

    # 自动将 Hash 构建成对象
    def initialize(result)
      @context = result['context']
      @dircount = result['dircount']
      @filecount = result['filecount']
      @has_more = result['has_more']
      @objects = build_objects(result['infos'])
    end

    private

    def build_objects(objects)
      objects.map do |obj|
        if obj.key?('access_url')
          QcloudCos::FileObject.new(obj)
        else
          QcloudCos::FolderObject.new(obj)
        end
      end
    end
  end
end
