# encoding: utf-8
require 'test_helper'

describe QcloudCos::FolderObject do
  before do
    init_config
  end

  it "should validate folder path" do
    e = assert_raises(QcloudCos::InvalidFolderPathError) { QcloudCos::FolderObject.validate('/test') }
    assert_equal('文件夹路径必须以 / 结尾', e.message)

    e = assert_raises(QcloudCos::InvalidFolderPathError) { QcloudCos::FolderObject.validate('/test\t/') }
    assert_equal(%{文件夹名字不能包含保留字符: '#{QcloudCos::FolderObject::RETAINED_SYMBOLS.join("', '")}'}, e.message)

    e = assert_raises(QcloudCos::InvalidFolderPathError) { QcloudCos::FolderObject.validate('/test<t/') }
    assert_equal(%{文件夹名字不能包含保留字符: '#{QcloudCos::FolderObject::RETAINED_SYMBOLS.join("', '")}'}, e.message)

    e = assert_raises(QcloudCos::InvalidFolderPathError) { QcloudCos::FolderObject.validate('/con/') }
    assert_equal(%{文件夹名字不能是保留字段: '#{QcloudCos::FolderObject::RETAINED_FIELDS.join("', '")}'}, e.message)

    e = assert_raises(QcloudCos::InvalidFolderPathError) { QcloudCos::FolderObject.validate("/#{'c' * 21}/") }
    assert_equal(%{文件夹名字不能超过#{QcloudCos::FolderObject::MAXLENGTH}个字符}, e.message)
  end
end
