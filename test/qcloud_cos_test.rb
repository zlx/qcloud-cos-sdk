require 'test_helper'

describe QcloudCos do
  before do
    init_config
  end

  describe 'list' do
    it 'should list' do
      stub_client_request(:get, '/', { query: { op: 'list', num: 120, order: 1, context: 'contextstr' } }, file_path: 'list.json')
      obj = QcloudCos.list('/', num: 120, order: 1, context: 'contextstr')
      assert_kind_of(QcloudCos::List, obj)
      assert_equal(2, obj.size)
      assert_equal('test2/|sdk.zip|0|', obj.context)
      assert_equal(false, obj.has_more)
      assert_kind_of(QcloudCos::FolderObject, obj[0])
      assert_kind_of(QcloudCos::FileObject, obj[1])
    end

    it "auto add leading '/'" do
      stub_client_request(:get, '/', { query: { op: 'list', num: 100 } }, file_path: 'list.json')
      assert_kind_of(QcloudCos::List, QcloudCos.list)
    end

    it 'should raise RequestError' do
      stub_client_request(:get, '/', { query: { op: 'list', num: 100 } }, body: { code: -5999, message: 'error message' }.to_json, status: 400)
      error = assert_raises(QcloudCos::RequestError) { QcloudCos.list }
      assert_equal(-5999, error.code)
      assert_equal('error message', error.message)
    end

    it 'should raise InvalidNumError' do
      assert_raises(QcloudCos::InvalidNumError) do
        QcloudCos.list('/', num: 200, order: 1, context: 'contextstr')
      end
    end
  end

  it 'should list files' do
    QcloudCos.expects(:list).with('/', 'pattern' => 'eListFileOnly')
    QcloudCos.list_files('/')
  end

  it 'should list folders' do
    QcloudCos.expects(:list).with('/', 'pattern' => 'eListDirOnly')
    QcloudCos.list_folders('/')
  end

  describe 'create folder' do
    it 'should create folder' do
      stub_client_request(
        :post,
        '/test/',
        body: { op: 'create', biz_attr: 'attr' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      assert_kind_of(Hash, QcloudCos.create_folder('/test/', biz_attr: 'attr'))
    end

    it "auto add leading '/'" do
      stub_client_request(
        :post,
        '/test/',
        body: { op: 'create', biz_attr: 'attr' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      assert_kind_of(Hash, QcloudCos.create_folder('test/', biz_attr: 'attr'))
    end
  end

  describe 'upload' do
    it 'should upload file' do
      stub_client_request(:post, '/test', headers: { 'Content-Type' => /multipart\/form-data;\S*/ })
      assert_kind_of(Hash, QcloudCos.upload('/test', 'Hello World', biz_attr: 'attr'))
    end

    it 'should upload file with IO' do
      stub_client_request(:post, '/test', headers: { 'Content-Type' => /multipart\/form-data;\S*/ })
      assert_kind_of(Hash, QcloudCos.upload('/test', File.new(File.expand_path('./test/fixtures/sample.txt')), biz_attr: 'attr'))
    end

    it 'should create file' do
      stub_client_request(:post, '/test', headers: { 'Content-Type' => /multipart\/form-data;\S*/ })
      assert_kind_of(Hash, QcloudCos.create('/test', 'Hello World', biz_attr: 'attr'))
    end

    it 'should raise error when path have end /' do
      assert_raises(QcloudCos::InvalidFilePathError) do
        QcloudCos.create('/test/', 'Hello World', biz_attr: 'attr')
      end
    end
  end

  describe 'upload_slice' do
    it 'should raise error when path have end /' do
      assert_raises(QcloudCos::InvalidFilePathError) do
        QcloudCos.upload_slice('/test/', File.expand_path('./test/fixtures/sample.txt'))
      end
    end

    it 'should raise error when local path not exist' do
      assert_raises(QcloudCos::FileNotExistError) do
        QcloudCos.upload_slice('/test', File.expand_path('./test/fixtures/noexist.txt'))
      end
    end

    it 'should return url for small request' do
      link = 'http://example.com/sample.txt'
      stub_client_request(:post, '/test', {}, body: { code: 0, data: { url: link } }.to_json)
      result = QcloudCos.upload_slice('/test', File.expand_path('./test/fixtures/sample.txt'))
      assert_kind_of(Hash, result)
      assert_equal(link, result['url'])
    end

    it 'should upload in slice' do
      File.stubs(size: 150_000)
      IO.stubs(read: 'content')
      link = 'http://example.com/sample.txt'
      session = 'randste' * 4
      stub_client_request(:post, '/test', {}, body: { code: 0, data: { session: session, offset: 0, slice_size: 100_000 } }.to_json)
        .to_return(
          body: { code: 0, data: { session: session, offset: 100_000 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        ).to_return(
          body: { code: 0, data: { url: link } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      result = QcloudCos.upload_slice('/test', File.expand_path('./test/fixtures/sample.txt'))
      assert_kind_of(Hash, result)
      assert_equal(link, result['url'])
    end

    it 'should upload in slice with block' do
      File.stubs(size: 150_000)
      IO.stubs(read: 'content')
      link = 'http://example.com/sample.txt'
      session = 'randste' * 4
      stub_client_request(:post, '/test', {}, body: { code: 0, data: { session: session, offset: 0, slice_size: 100_000 } }.to_json)
        .to_return(
          body: { code: 0, data: { session: session, offset: 100_000 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        ).to_return(
          body: { code: 0, data: { url: link } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      out, _ = capture_io do
        result = QcloudCos.upload_slice('/test', File.expand_path('./test/fixtures/sample.txt')) do |pr|
          puts "uploaded #{pr*100}%"
        end
        assert_kind_of(Hash, result)
        assert_equal(link, result['url'])
      end
      assert_equal("uploaded 67.0%\nuploaded 100.0%\n", out)
    end

    it 'should retry when upload part failed' do
      link = 'http://example.com/sample.txt'
      session = 'randste' * 4
      stub_client_request(:post, '/test', {}, body: { code: 0, data: { session: session, offset: 0, slice_size: 100_000 } }.to_json)
        .to_raise(RuntimeError)
        .to_return(
          body: { code: 0, data: { url: link } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      result = QcloudCos.upload_slice('/test', File.expand_path('./test/fixtures/sample.txt'))
      assert_kind_of(Hash, result)
      assert_equal(link, result['url'])
    end

    it 'should raise error when reach max retry times' do
      link = 'http://example.com/sample.txt'
      session = 'randste' * 4
      stub_client_request(:post, '/test', {}, body: { code: 0, data: { session: session, offset: 0, slice_size: 100_000 } }.to_json)
        .to_raise(RuntimeError).times(4)
      assert_raises(RuntimeError) do
        QcloudCos.upload_slice('/test', File.expand_path('./test/fixtures/sample.txt'))
      end
    end

    it 'should config max retry times' do
      QcloudCos.configure { |config| config.max_retry_times = 5 }
      link = 'http://example.com/sample.txt'
      session = 'randste' * 4
      stub_client_request(:post, '/test', {}, body: { code: 0, data: { session: session, offset: 0, slice_size: 100_000 } }.to_json)
        .to_raise(RuntimeError).times(4)
        .to_return(
          body: { code: 0, data: { url: link } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      result = QcloudCos.upload_slice('/test', File.expand_path('./test/fixtures/sample.txt'))
      assert_kind_of(Hash, result)
      assert_equal(link, result['url'])
    end
  end

  it 'should update biz_attr for file' do
    stub_client_request(
      :post,
      '/test',
      body: { op: 'update', biz_attr: 'attr' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    assert_kind_of(Hash, QcloudCos.update('/test', 'attr'))
  end

  it 'should update biz_attr for folder' do
    stub_client_request(
      :post,
      '/test/',
      body: { op: 'update', biz_attr: 'attr' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    assert_kind_of(Hash, QcloudCos.update('/test/', 'attr'))
  end

  describe 'delete' do
    it 'should delete file' do
      stub_client_request(
        :post,
        '/test',
        body: { op: 'delete' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      assert_kind_of(Hash, QcloudCos.delete('/test'))
    end

    it 'should delete folder' do
      stub_client_request(
        :post,
        '/test/',
        body: { op: 'delete' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      assert_kind_of(Hash, QcloudCos.delete('/test/'))
    end

    it 'should raise error when path not valid' do
      assert_raises(QcloudCos::InvalidFilePathError) { QcloudCos.delete_file('/test/') }
    end

    it 'should raise error when delete file with path end with /' do
      assert_raises(QcloudCos::InvalidFilePathError) { QcloudCos.delete_file('/test/') }
    end

    it 'should invoke delete with file' do
      QcloudCos.expects(:delete).with('/test', {})
      QcloudCos.delete_file('/test')
    end

    it 'should raise error when delete folder with path end without /' do
      assert_raises(QcloudCos::InvalidFolderPathError) { QcloudCos.delete_folder('/test') }
    end

    it 'should invoke delete with folder' do
      QcloudCos.expects(:delete).with('/test/', {})
      QcloudCos.delete_folder('/test/')
    end

    it "delete_folder should support recursive" do
      options = { recursive: true }
      stub_client_request(:get, '/test/', { query: { op: 'list', num: 100 } }, file_path: 'list.json')
      stub_client_request(:get, '/test/', { query: { op: 'list', num: 100, context: 'test2/|sdk.zip|0|' } }, body: { code: 0, data: { infos: []} }.to_json)
      stub_client_request(:get, '/test/test2/', { query: { op: 'list', num: 100 } }, body: { code: 0, data: { infos: []} }.to_json)
      stub_client_request(:post, '/test/test2/', body: { op: 'delete' }.to_json)
      stub_client_request(:post, '/test/sdk.zip', body: { op: 'delete' }.to_json)
      stub_client_request(:post, '/test/', body: { op: 'delete' }.to_json)
      QcloudCos.delete_folder('/test/', options)
    end
  end

  describe 'stat' do
    it 'should get file information' do
      stub_client_request(
        :get,
        '/test',
        query: { op: 'stat' }
      )
      assert_kind_of(Hash, QcloudCos.stat('/test'))
    end

    it 'should get folder information' do
      stub_client_request(
        :get,
        '/test/',
        query: { op: 'stat' }
      )
      assert_kind_of(Hash, QcloudCos.stat('/test/'))
    end
  end

  describe 'public_url' do
    it 'should get public url' do
      stub_client_request(
        :get,
        '/test',
        {
          query: { op: 'stat' }
        },
        body: { code: 0, data: { access_url: 'http://example.com/test' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      QcloudCos.public_url('/test')
    end

    it 'should raise error' do
      stub_client_request(
        :get,
        '/test',
        query: { op: 'stat' }
      )
      assert_raises(QcloudCos::FileNotExistError) { QcloudCos.public_url('test') }
    end
  end

  describe "bucket_info" do
    before do
      stub_client_request(:get, '/', { query: { op: 'stat' } }, file_path: 'bucket_info.json')
    end

    it "should get bucket information" do
      result = QcloudCos.bucket_info
      assert_kind_of(Hash, result)
      assert_equal('eWRPrivate', result['authority'])
    end
  end

  describe "count" do
    it "should get count for folder and file" do
      stub_client_request(:get, '/test/', { query: { op: 'list', num: 1, pattern: 'eListDirOnly' } }, file_path: 'list.json')
      result = QcloudCos.count('/test/')
      assert_kind_of(Hash, result)
      assert_equal(1, result[:file_count])
      assert_equal(1, result[:folder_count])
    end
  end

  describe "empty?" do
    it "should check path empty?" do
      stub_client_request(:get, '/test/', { query: { op: 'list', num: 1, pattern: 'eListDirOnly' } }, file_path: 'list.json')
      assert_equal(false, QcloudCos.empty?('/test/'))
    end

    it "should check path contains file or not" do
      stub_client_request(:get, '/test/', { query: { op: 'list', num: 1, pattern: 'eListDirOnly' } }, file_path: 'empty_list.json')
      assert_equal(true, QcloudCos.contains_file?('/test/'))
    end

    it "should check path contains folder or not" do
      stub_client_request(:get, '/test/', { query: { op: 'list', num: 1, pattern: 'eListDirOnly' } }, file_path: 'empty_list.json')
      assert_equal(false, QcloudCos.contains_folder?('/test/'))
    end
  end

  describe "exist?" do
    it "should check path exist or not" do
      stub_client_request(:get, '/test/', { query: { op: 'stat' } }, file_path: 'folder.json')
      assert_equal(true, QcloudCos.exists?('/test/'))
    end

    it "should check file exist or not" do
      stub_client_request(:get, '/test', { query: { op: 'stat' } }, file_path: 'file.json')
      assert_equal(true, QcloudCos.exists?('/test'))
    end
  end

end
