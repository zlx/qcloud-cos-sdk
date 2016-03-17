require 'test_helper'
require 'qcloud_cos/cli'

describe QcloudCos::Cli do
  let(:qcloud_file) { 'test-qcloud-cos.yml' }
  let(:list_result) { QcloudCos::List.new(JSON.load(File.read(File.expand_path('test/fixtures/list.json')))['data']) }
  let(:empty_list_result) { QcloudCos::List.new(JSON.load(File.read(File.expand_path('test/fixtures/empty_list.json')))['data']) }
  let(:clear_config) { FileUtils.rm_f(qcloud_file) }

  subject { QcloudCos::Cli.init }

  before do
    init_config
    @old_config = QcloudCos::QCLOUD_COS_CONFIG
    reset_const(QcloudCos, 'QCLOUD_COS_CONFIG', qcloud_file)

    File.open(qcloud_file, "w") do |file|
      file.puts "app_id=#{QcloudCos.config.app_id}"
      file.puts "secret_id=#{QcloudCos.config.secret_id}"
      file.puts "secret_key=#{QcloudCos.config.secret_key}"
      file.puts "endpoint=#{QcloudCos.config.endpoint}"
      file.puts "bucket=#{QcloudCos.config.bucket}"
    end
  end

  after do
    reset_const(QcloudCos, 'QCLOUD_COS_CONFIG', @old_config)
    clear_config
  end

  describe "config" do
    before do
      clear_config
    end

    it "should raise when missing app id" do
      Commander::UI.expects(:say_error).with('Missing Qcloud COS APP ID')
      Commander::UI.stubs(:ask).returns('')
      QcloudCos::Cli.config(qcloud_file)
    end

    it "should raise when missing secret_id" do
      Commander::UI.expects(:say_error).with('Missing Qcloud COS Secret ID')
      Commander::UI.stubs(:ask).returns('app-id', '')
      QcloudCos::Cli.config(qcloud_file)
    end

    it "should raise when missing secret_key" do
      Commander::UI.expects(:say_error).with('Missing Qcloud COS Secret Key')
      Commander::UI.stubs(:ask).returns('app-id', 'secret-id', '')
      QcloudCos::Cli.config(qcloud_file)
    end

    it "should not raise when missing bucket" do
      Commander::UI.expects(:say_error).never
      Commander::UI.stubs(:ask).returns('app-id', 'secret-id', 'secret-key', '', '')
      QcloudCos::Cli.config(qcloud_file)
    end

    it "should not raise when missing bucket" do
      expected_content = "app_id=app-id\nsecret_id=secret-id\nsecret_key=secret-key\nendpoint=http://mock-server/\nbucket=bucket\nssl_ca_file=\nmax_retry_times=\n"
      Commander::UI.expects(:say_error).never
      Commander::UI.stubs(:ask).returns('app-id', 'secret-id', 'secret-key', 'http://mock-server/', 'bucket')
      QcloudCos::Cli.config(qcloud_file)
      assert_equal(expected_content, File.read(qcloud_file))
    end
  end

  describe "without config" do
    it "should raise" do
      clear_config
      Commander::UI.expects(:say_error).with('Use `qcloud-cos config` first or export your environments').returns(true)
      assert_equal(false, QcloudCos::Cli.environment_configed?)
    end

    it "should not raise when have environment" do
      clear_config
      ENV.stubs(:[]).with('QCLOUD_COS_APP_ID').returns('app-id')
      Commander::UI.expects(:say_error).never
      assert_equal(true, QcloudCos::Cli.environment_configed?)
    end
  end

  describe "info" do

    it 'Obtain bucket information' do
      bucket_info = { authority: 'eWRPrivate' }
      QcloudCos.expects(:stat).with('/', {}).returns({'data' => bucket_info })
      assert_equal(bucket_info, subject.info([], OpenStruct.new))
    end

    it 'Obtain information for /test/' do
      folder_info = { name: 'test' }
      QcloudCos.expects(:stat).with('/test/', {}).returns({'data' => folder_info })
      assert_equal(folder_info, subject.info(['/test/'], OpenStruct.new))
    end

    it 'Obtain information for /production.log' do
      file_info = { name: 'production.log' }
      QcloudCos.expects(:stat).with('/production.log', {}).returns({'data' => file_info })
      assert_equal(file_info, subject.info(['/production.log'], OpenStruct.new))
    end

    it 'Obtain information for /production.log from bucket2' do
      file_info = { name: 'production.log' }
      QcloudCos.expects(:stat).with('/production.log', { bucket: 'bucket2' }).returns({'data' => file_info })
      assert_equal(file_info, subject.info(['/production.log'], OpenStruct.new(bucket: 'bucket2')))
    end
  end

  describe "list" do
    subject { QcloudCos::Cli.init }

    it 'List all objects under /' do
      QcloudCos.expects(:list).with('/', { num: 100 }).returns(list_result)
      assert_equal(["/test2/", "/sdk.zip"], subject.list([], OpenStruct.new(num: 100)))
    end

    it 'List all objects under /test/' do
      QcloudCos.expects(:list).with('/test/', { num: 100 }).returns(list_result)
      assert_equal(["/test/test2/", "/test/sdk.zip"], subject.list(['/test/'], OpenStruct.new(num: 100)))
    end

    it 'List first 10 objects under /test/' do
      QcloudCos.expects(:list).with('/test/', { num: 20}).returns(list_result)
      assert_equal(["/test/test2/", "/test/sdk.zip"], subject.list(['/test/'], OpenStruct.new(num: 20)))
    end

    it 'List all objects under / for bucket: bucket2' do
      QcloudCos.expects(:list).with('/', { bucket: 'bucket2', num: 100 }).returns(list_result)
      assert_equal(["/test2/", "/sdk.zip"], subject.list(['/'], OpenStruct.new(bucket: 'bucket2', num: 100)))
    end
  end

  describe "upload" do
    let(:file_path) { File.expand_path('test/fixtures/sample.txt') }
    let(:folder_path) { File.expand_path('test/fixtures/test/') }
    subject { QcloudCos::Cli.init }

    it "should raise when missing args" do
      Commander::UI.expects(:say_error).with('file missing, see example: $ qcloud-cos upload -h').returns(true)
      subject.upload([], OpenStruct.new(size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end

    it "should raise when path not exist" do
      Commander::UI.expects(:say_error).with('file noexist not exist').returns(true)
      subject.upload(['noexist'], OpenStruct.new(size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end

    it "should raise when dest_path not end with /" do
      Commander::UI.expects(:say_error).with('dest_path must end with /, see example: $ qcloud-cos upload -h').returns(true)
      subject.upload([file_path, '/data'], OpenStruct.new(size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end

    it 'Upload sample.txt to /' do
      Commander::UI.expects(:say_ok).with("#{file_path} uploaded to /sample.txt...")
      QcloudCos.expects(:upload).with('/sample.txt', kind_of(IO), {}).returns(true)
      subject.upload([file_path], OpenStruct.new(size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end

    it 'Upload sample.txt to / with slice_size and min' do
      Commander::UI.expects(:say_ok).with("#{file_path} uploaded to /sample.txt...")
      QcloudCos.expects(:upload_slice).with('/sample.txt', file_path, { slice_size: 100 }).returns(true)
      subject.upload([file_path], OpenStruct.new(size: 100, min: 10))
    end

    it 'Upload sample.txt to / failed' do
      Commander::UI.expects(:say_error).with("Failed when uploaded #{file_path} ===> Boom!")
      QcloudCos.expects(:upload).with('/sample.txt', kind_of(IO), {}).raises(StandardError.new('Boom!'))
      subject.upload([file_path], OpenStruct.new(size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end

    it 'Upload sample.txt to /data/' do
      Commander::UI.expects(:say_ok).with("#{file_path} uploaded to /data/sample.txt...")
      QcloudCos.expects(:upload).with('/data/sample.txt', kind_of(IO), {}).returns(true)
      subject.upload([file_path, '/data/'], OpenStruct.new(size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end

    it 'Upload all files under ./test/ to /data/' do
      Commander::UI.expects(:say_ok).with("#{folder_path}/sample.txt uploaded to /data/sample.txt...")
      Commander::UI.expects(:say_ok).with("#{folder_path}/test1/sample.txt uploaded to /data/test1/sample.txt...")
      QcloudCos.expects(:upload).with('/data/sample.txt', kind_of(IO), {}).returns(true)
      QcloudCos.expects(:upload).with('/data/test1/sample.txt', kind_of(IO), {}).returns(true)
      subject.upload(["#{folder_path}/", '/data/'], OpenStruct.new(size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end

    it 'Upload all files under ./test/ to /data/ with other bucket: bucket2' do
      Commander::UI.expects(:say_ok).with("#{folder_path}/sample.txt uploaded to /data/sample.txt...")
      Commander::UI.expects(:say_ok).with("#{folder_path}/test1/sample.txt uploaded to /data/test1/sample.txt...")
      QcloudCos.expects(:upload).with('/data/sample.txt', kind_of(IO), { bucket: 'bucket2' }).returns(true)
      QcloudCos.expects(:upload).with('/data/test1/sample.txt', kind_of(IO), { bucket: 'bucket2' }).returns(true)
      subject.upload(["#{folder_path}/", '/data/'], OpenStruct.new(bucket: 'bucket2', size: QcloudCos::DEFAULT_SLICE_SIZE, min: QcloudCos::MIN_SLICE_FILE_SIZE * 1024 * 1024))
    end
  end

  describe "download" do
    let(:endpoint) { 'http://mock-server/' }
    let(:file_link) { "#{endpoint}data/production.log" }
    subject { QcloudCos::Cli.init }

    it "should raise" do
      Commander::UI.expects(:say_error).with('missing path, see example: $ qcloud-cos download -h')
      subject.download([], OpenStruct.new)
    end

    it 'Download file from /data/production.log and save current path' do
      Commander::UI.expects(:say_ok).with("Save /data/production.log to ./production.log")
      QcloudCos.expects(:public_url).with('/data/production.log', {}).returns(file_link)
      stub_request(:get, "http://mock-server/data/production.log").to_return(body: 'Content')
      subject.download(['/data/production.log'], OpenStruct.new)
      FileUtils.rm_f('production.log')
    end

    it 'Download file from /data/production.log and save under ./data/' do
      '$ qcloud-cos download /data/production.log ./data'
      Commander::UI.expects(:say_ok).with("Save /data/production.log to ./data/production.log")
      QcloudCos.expects(:public_url).with('/data/production.log', {}).returns(file_link)
      stub_request(:get, "http://mock-server/data/production.log").to_return(body: 'Content')
      subject.download(['/data/production.log', './data'], OpenStruct.new)
      FileUtils.rm_rf('data')
    end

    it 'Download file from /data/production.log failed' do
      Commander::UI.expects(:say_error).with('Failed when Download /data/production.log  ===> Boom!')
      QcloudCos.expects(:public_url).with('/data/production.log', {}).returns(file_link)
      HTTParty.stubs(:get).raises(StandardError.new('Boom!'))
      subject.download(['/data/production.log'], OpenStruct.new)
      FileUtils.rm_f('production.log')
    end

    it 'Download whole folder /data/test/ and save under ./data/' do
      file_link1 = "#{endpoint}data/test/sdk.zip"
      file_link2 = "#{endpoint}data/test/test2/sdk.zip"
      Commander::UI.expects(:say_ok).with('Save /data/test/ to ./data/')
      Commander::UI.expects(:say_ok).with('Save /data/test/test2/ to ./data/test2/')
      Commander::UI.expects(:say_ok).with('Save /data/test/test2/sdk.zip to ./data/test2/sdk.zip')
      Commander::UI.expects(:say_ok).with('Save /data/test/sdk.zip to ./data/sdk.zip')
      QcloudCos.expects(:list).with('/data/test/', {}).returns(list_result)
      QcloudCos.expects(:list).with('/data/test/test2/', {}).returns(empty_list_result)
      stub_request(:get, %r[.*]).to_return(body: 'Content')
      subject.download(['/data/test/', './data'], OpenStruct.new)
      FileUtils.rm_rf('data')
    end

    it 'Download whole folder /data/test/ from bucket2 and save under ./data/' do
      '$ qcloud-cos download --bucket bucket2 /data/test/ ./data'
      file_link1 = "#{endpoint}data/test/sdk.zip"
      file_link2 = "#{endpoint}data/test/test2/sdk.zip"
      Commander::UI.expects(:say_ok).with('Save /data/test/ to ./data/')
      Commander::UI.expects(:say_ok).with('Save /data/test/test2/ to ./data/test2/')
      Commander::UI.expects(:say_ok).with('Save /data/test/test2/sdk.zip to ./data/test2/sdk.zip')
      Commander::UI.expects(:say_ok).with('Save /data/test/sdk.zip to ./data/sdk.zip')
      QcloudCos.expects(:list).with('/data/test/', { bucket: 'bucket2' }).returns(list_result)
      QcloudCos.expects(:list).with('/data/test/test2/', { bucket: 'bucket2' }).returns(empty_list_result)
      stub_request(:get, %r[.*]).to_return(body: 'Content')
      subject.download(['/data/test/', './data'], OpenStruct.new(bucket: 'bucket2'))
      FileUtils.rm_rf('data')
    end
  end

  describe "remove" do
    subject { QcloudCos::Cli.init }

    it 'Remove file /data/production.log' do
      QcloudCos.expects(:delete_file).with('/data/production.log', {})
      subject.remove(['/data/production.log'], OpenStruct.new)
    end

    it 'Remove folder /data/test/' do
      QcloudCos.expects(:delete_folder).with('/data/test/', { recursive: false })
      subject.remove(['/data/test/'], OpenStruct.new)
    end

    it 'Remove folder /data/test/ in recursive' do
      QcloudCos.expects(:delete_folder).with('/data/test/', { recursive: true })
      subject.remove(['/data/test/'], OpenStruct.new(bucket: nil, recursive: true))
    end

    it 'Remove folder /data/test/ from bucket2' do
      QcloudCos.expects(:delete_folder).with('/data/test/', { bucket: 'bucket2', recursive: true })
      subject.remove(['/data/test/'], OpenStruct.new(bucket: 'bucket2', recursive: true))
    end

    it 'should raise when missing args' do
      Commander::UI.expects(:say_error).with('missing dest_path, see example: $ qcloud-cos remove -h')
      subject.remove([], OpenStruct.new)
    end
  end

end
