require 'test_helper'

describe QcloudCos::Authorization do
  before do
    @config = QcloudCos::Configuration.new
    @config.app_id = '200001'
    @config.secret_id = 'AKIDUfLUEUigQiXqm7CVSspKJnuaiIKtxqAv'
    @config.secret_key = 'bLcPnl88WU30VY57ipRhSePfPdOfSruK'

    @authorization = QcloudCos::Authorization.new(@config)
    @authorization.stubs(:current_time).returns(1_436_077_115)
    @authorization.stubs(:rdm).returns(11_162)
  end

  it 'should sign for multiple' do
    bucket = 'newbucket'
    expired = 1_438_669_115 - 1_436_077_115
    assert_equal(
      '5bIObv9KXNcITrcVNRGCLG3K6xxhPTIwMDAwMSZiPW5ld2J1Y2tldCZrPUFLSURVZkxVRVVpZ1FpWHFtN0NWU3NwS0pudWFpSUt0eHFBdiZlPTE0Mzg2NjkxMTUmdD0xNDM2MDc3MTE1JnI9MTExNjImZj0=',
      @authorization.sign(bucket, expired)
    )

    assert_equal(
      @authorization.sign(bucket, QcloudCos::EXPIRED_SECONDS),
      @authorization.sign(bucket)
    )
  end

  it 'should sign once' do
    bucket = 'newbucket'
    field = '/newbucket/tencent_test.jpg'
    assert_equal(
      'OXy21aC6AjhScJaJqrBxcS0Y7lNhPTIwMDAwMSZiPW5ld2J1Y2tldCZrPUFLSURVZkxVRVVpZ1FpWHFtN0NWU3NwS0pudWFpSUt0eHFBdiZlPTAmdD0xNDM2MDc3MTE1JnI9MTExNjImZj0vMjAwMDAxL25ld2J1Y2tldC90ZW5jZW50X3Rlc3QuanBn',
      @authorization.sign_once(bucket, field)
    )
  end
end
