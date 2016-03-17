# Qcloud COS

It's the full featured Ruby SDK for Qcloud COS(Cloud Object Service).

We keep API simple but powerful, to give you more freedom.

Enjoy it!

## Installation

Add this line to your application's Gemfile:


    gem 'qcloud_cos'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qcloud_cos

## Usage

```ruby
QcloudCos.configure do |config|
  config.app_id = 'app-id'
  config.secret_id = 'secret_id'
  config.secret_key = 'secret_key'
  config.endpoint = "http://web.file.myqcloud.com/files/v1/"
  config.bucket = "default-bucket-name"
end

QcloudCos.list # 列出 / 目录下的文件和文件夹

QcloudCos.upload('/test.log', 'Hello World')
QcloudCos.upload('/test.log', File.new('path/to/log'))

QcloudCos.upload_slice('/video.mp4', 'path/to/video.mp4')

QcloudCos.create_folder('/test/') # 创建目录
```

### CLI

```ruby
$ qcloud-cos config

$ qcloud-cos info
$ qcloud-cos list
```

More Example and Scenario, visit our [Document](#document)

## Document

Here is original Restful API, It has the most detailed and authoritative explanation for every API.

+ [COS RESTful API文档](http://www.qcloud.com/wiki/RESTful_API%E6%96%87%E6%A1%A3)
+ [COS 详细文档](http://www.qcloud.com/doc/product/227/%E4%BA%A7%E5%93%81%E4%BB%8B%E7%BB%8D)

Here is our RDoc Document, It's well format to help you find more detail about methods.

+ [RDoc Document](http://www.rubydoc.info/gems/qcloud_cos)


Here are some more guides for help you. Welcome to advice.

+ [Getting Started](wiki/get_started.md)


## Test

We use minitest for test and rubocop for Syntax checker, If you want to make contribute to this library. Confirm below Command is success:

    bundle exec rake test


## Authors && Contributors

- [Newell](https://github.com/zlx_star)


## License

licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)
