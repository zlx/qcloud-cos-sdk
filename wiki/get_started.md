## 目录

1. [开发准备](#开发准备)
   1. [前期准备](#前期准备)
   2. [获取 SDK](#获取sdk)
   3. [Https 支持](#https支持)
2. [API详细说明](#api详细说明)
   1. [生成签名](#生成签名)
   2. [Bucket 操作](#bucket-操作)
      1. [查看 Bucket 信息](#查看-bucket-信息 )
   2. [目录操作](#目录操作)
      1. [创建目录 (create, create_folder)](#创建目录)
      2. [更新目录属性 (update)](#更新属性)
      3. [查询目录信息 (stat)](#目录或者文件查询)
      4. [列出目录 (list, list_folders)](#列举目录下文件或目录)
      5. [文件夹搜索 (list)](#列举目录下文件或目录)
      6. [删除目录 (delete, delete_folder)](#删除文件或目录)
      7. [检查目录是否存在 (exists?, exist?)](#判断目录或者文件是否存在)
      8. [查看目录下文件夹数量 (count)](#查看文件和文件夹数目)
      9. [检查目录是否为空 (empty?)](#判断目录是否为空)
      10. [检查目录下是否有文件夹 (contains_folder?)](#判断目录是否为空)
   3. [文件操作](#文件操作)
      1. [上传文件 (create, upload)](#文件上传)
      2. [分片上传文件，支持断点续传 (upload_slice)](#大文件分片上传)
      3. [更新文件属性 (update)](#更新属性)
      4. [查询文件信息 (stat)](#目录或者文件查询)
      5. [列出文件 (list, list_files)](#列举目录下文件或目录)
      6. [删除文件 (delete, delete_file)](#删除文件或目录)
      7. [获取文件外网访问地址 (public_url)](#获取文件外网访问地址)
      8. [文件搜索 (list)](#列举目录下文件或目录)
      9. [检查文件是否存在 (exists?, exist?)](#判断目录或者文件是否存在)
      10. [查看目录下文件数量 (count)](#查看文件和文件夹数目)
      11. [检查目录下是否有文件 (contains_folder?)](#判断目录是否为空)
   4. [分片上传 (upload_slice)](#文件分片上传)
      1. [分片上传大文件 (upload_slice)](#大文件分片上传)
      2. [分片上传初始化 (init_slice_upload)](#分片上传初始化)
      3. [分片上传数据 (upload_part)](#分片上传数据)   
   4. [命令行工具 (qcloud-cos)](#命令行工具)
      1. [配置 (qcloud-cos config)](#命令行配置)
      2. [查看信息 (qcloud-cos info)](#info)
      3. [列出文件 (qcloud-cos list)](#list)
      4. [上传文件或者目录 (qcloud-cos upload)](#upload)
      5. [下载文件或者目录 (qcloud-cos download)](#download)
      6. [删除文件或者目录 (qcloud-cos remove)](#remove)
 3. [其它资源](#其它资源)   


##  开发准备

1. 对象存储服务的 Ruby SDK 的 官方地址：https://github.com/tencentyun/cos-ruby-sdk
2. 项目名： tencentyun/cos-ruby-sdk

### 前期准备

1.  sdk 支持 Ruby 1.9.3 及以上。
2.  获取项目ID(appid)，bucket，secret_id和secret_key；

### 获取SDK

把这行代码加到你的 Gemfile:

    gem 'qcloud_cos'

然后执行:

    $ bundle

或者自己安装:

    $ gem install qcloud_cos

然后配置你的环境：

```ruby
QcloudCos.configure do |config|
  config.app_id = 'app-id'
  config.secret_id = 'secret_id'
  config.secret_key = 'secret_key'
  config.endpoint = "http://web.file.myqcloud.com/files/v1/"
  config.bucket = "default-bucket-name"
end
```

### https支持

需要支持 https, 有两种方式:


1. 配置 endpoint 为 https 地址(比如： https://web.file.myqcloud.com/files/v1/ )即可。这时候会加密客户端请求，但是服务端会无条件信任证书

2. 配置 endpoint 为 https 地址(比如： https://web.file.myqcloud.com/files/v1/ )，并配置 ssl_ca_file, 这样服务端会验证你的证书，保证你的通信安全并且合法

```ruby
QcloudCos.config do |config|
  config.ssl_ca_file = 'path/to/ca/file'
end
```

## API详细说明

### 生成签名

1. 接口说明

 签名生成方法，可以在服务端生成签名，供移动端app使用。

 签名分为2种：
 多次有效签名（有一定的有效时间）
 单次有效签名（绑定资源url，只能生效一次）
 签名的详细描述及使用场景参见 [鉴权技术服务方案](http://www.qcloud.com/wiki/%E9%89%B4%E6%9D%83%E6%8A%80%E6%9C%AF%E6%9C%8D%E5%8A%A1%E6%96%B9%E6%A1%88)

2. 方法

 多次有效签名

 ```ruby
 Authorization#sign(bucket, expired)
 ```

 单次有效签名

 ```ruby
 Authorization#sign_once(bucket, fileid)
 ```

3. 参数和返回值

参数说明：


| 参数名 | 类型   | 必须 | 默认值 | 参数描述 |
| ----- | ----- | ---- | ----- | ------ |
|expired    |long   |否 |无 |有效时长, 以当前时间计算过期时间|
|bucket |String |是 |无 |bucket名称，bucket创建参见创建Bucket|
|fileid |String |是 |无 |文件路径，以斜杠开头，例如 /filepath/filename，为文件在此bucketname下的全路径|


返回值：签名字符串

示例代码：

```ruby
expired = 600
authorization = QcloudCos::Authorization.new(QcloudCos.config)
authorization.sign(bucket, expired) # 生成一个10分钟有效的多次有效签名
fileid = "/myFloder/myFile.rar"
authorization.sign_once(bucket, fileid) # 生成一个绑定文件的单次有效签名
```

### Bucket 操作

#### 查看 Bucket 信息 

1.  接口说明

 查看 Bucket 配置信息

2.  方法

 ```ruby
 QcloudCos.bucket_info(bucket_name = config.bucket)
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|-----|----|------|------|
| bucket_name   |String|是  |配置里面的默认 Bucket | Bucket 名字|


返回值, Hash

如果指定的 Bucket 不存在，则返回 `{}`

| 属性                   | 类型          | 描述                                    |
| --------------------- | ------------- | -------------------------------------- |
| authority             | String        | eWPrivateRPublic私有写公共读，eWPrivate私有写私有读 |
| bucket_type           | Integer       | bucket_type                            |
| migrate_source_domain | String        | 回源地址                                   |
| need_preview          | String        | need_preview                           |
| refers                | Array<String> | refers                                 |
| blackrefers           | Array<String> | blackrefers                            |
| cnames                | Array<String> | cnames                                 |
| nugc_flag             | String        | nugc_flag                              |


示例代码：

```ruby
QcloudCos.bucket_info  #=> { authority: '', ... }
QcloudCos.bucket_info('other-bucket') # => {}
```

### 目录操作

#### 创建目录

1.  接口说明

 用于目录的创建，调用者可以通过此接口在指定bucket下创建目录。

2.  方法

    ```ruby
    QcloudCos.create_folder(path, options = {})
    ```

3.  参数和返回值

***文件夹名称限制：***

> 文件夹名请保持在 20 个字符以内，同时注意不支持保留符号和保留字段。
> 
> 保留符号不可以使用，例如：'/' , '?' , '*' , ':' , '|' , '\' , '<' , '>' , '"'。
>
> 保留字段不可以直接使用，可以包含使用，例如：'con' , 'aux' , 'nul' , 'prn' , 'com0' , 'com1' , 'com2' , 'com3' , 'com4' , 'com5' , 'com6' , 'com7' , 'com8' , 'com9' , 'lpt0' , 'lpt1' , 'lpt2' , 'lpt3' , 'lpt4' , 'lpt5' , 'lpt6' , 'lpt7' , 'lpt8' , 'lpt9'，但 'con1' 或 'aux1' 这样的名字可以使用。

对不符合要求的文件夹路径会抛出 InvalidFolderPathError 异常。

参数说明：

|参数名|类型|必须|默认值|参数描述|
|-----|---|----|-----|------|
|path|  String| 是| 无| 需要创建目录的全路径，API 会自动补齐"/"开头, 缺失 / 结尾，会抛出异常 InvalidFolderPathError|
|options| Hash| 否  |{}|    支持 bucket 和 biz_attr(目录绑定的属性信息，业务自行维护)|

返回值, Hash:

|参数名|类型 |参数描述|
|-----|----|-------|
|code| Int| 错误码，成功时为0|
|message|   String| 错误信息|
|data|  Hash|   返回数据|
|data['ctime']| String| 目录的创建时间，unix时间戳|
|data['resource_path']  |String|    目录的资源路径|

API 请求错误，则抛出 RequestError 异常

|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| API 错误码|
|message| String| 错误信息|
|original_response| Response| 原始返回结果|


示例代码：

```ruby
path = "/myFolder/"
biz_attr = "attr_folder"
result  = QcloudCos.create_folder(path, biz_attr: biz_attr)
```


#### 更新属性

1. 接口说明

  用于目录业务自定义属性的更新，调用者可以通过此接口更新业务的自定义属性字段。

2. 方法

    ```ruby
    QcloudCos.update(path, biz_attr, options = {})
    ```

3.  参数和返回值

参数说明：

|参数名 |类型 |必须 |默认值 |参数描述|
|------|----|-----|------|------|
|path|  String| 是  |无 |需要创建目录的全路径，以"/"开头，api会补齐|
|biz_attr|  String| 是  |无 |新的目录绑定的属性信息|
|options| Hash| 否  |{}|    支持 bucket, 默认使用配置的 bucket |


返回值, Hash:

|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| 错误码，成功时为0|
|message|   String| 错误信息|

API 请求错误，则抛出 RequestError 异常

|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| API 错误码|
|message| String| 错误信息|
|original_response| Response| 原始返回结果|


示例代码：

```ruby
path = "/myFolder/";
biz_attr = "attr_folder_new";
result  = QcloudCos.update(path, biz_attr)
```


#### 目录或者文件查询

1.  接口说明

 用于目录属性的查询，调用者可以通过此接口查询目录的属性。

2.  方法

 ```ruby
 QcloudCos.stat(path, options = {})
 ```

3.  参数和返回值

参数说明：


|参数名 |类型 |必须 |默认值 |参数描述|
|------|----|-----|------|------|
|path|  String| 是  |无 |需要创建目录的全路径，以"/"开头，api会补齐|
|options| Hash| 否  |{}|    支持 bucket, 默认使用配置的 bucket |


返回值, Hash:

|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| 错误码，成功时为0|
|message|   String| 错误信息|
|data['biz_attr']   |String |目录绑定的属性信息，业务自行维护|
|data['ctime']  |String |目录或者文件的创建时间，unix时间戳|
|data['mtime']  |String |目录或者文件的修改时间，unix时间戳|
|data['name']   |String |目录或者文件的名称|
|data['filesize']   |Integer    |文件的大小，当类型为文件时有|
|data['sha']    |String |文件的Sha，当类型为文件时有|
|data['access_url'] |String |文件的可访问的url，当类型为文件时有|


API 请求错误，则抛出 RequestError 异常

|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| API 错误码|
|message| String| 错误信息|
|original_response| Response| 原始返回结果|


示例代码：

 ```ruby
 path = "/myFolder/";
 result = QcloudCos.stat(path)
 ```

#### 删除文件或目录

1.  接口说明

 用于目录的删除，调用者可以通过此接口删除空目录，如果目录中存在有效文件或目录，将不能删除。

2.  方法

 ```ruby
 QcloudCos.delete(path, options = {}) # 删除文件或者目录
 QcloudCos.delete_file(path, options = {}) # 删除文件
 QcloudCos.delete_folder(path, options = {}) # 删除目录
 ```

3.  参数和返回值

参数说明：

|参数名 |类型 |必须 |默认值 |参数描述|
|------|----|-----|------|------|
|path|  String| 是  |无 |需要创建目录的全路径，以"/"开头，api会补齐|
|options| Hash| 否  |{}|    支持 bucket, 默认使用配置的 bucket |
|recursive| Boolean| 否  |false| 级联删除, 删除目录下所有内容, 仅 delete_folder 方法支持 |


返回值, Hash:

|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| 错误码，成功时为0|
|message|   String| 错误信息|

API 请求错误，则抛出 RequestError 异常


|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| API 错误码|
|message| String| 错误信息|
|original_response| Response| 原始返回结果|


示例代码：

```ruby
path = "/myFolder/"
result = QcloudCos.delete(path)

path = "/myNotEmptyFolder/"
result = QcloudCos.delete_folder(path) # 错误: 目录非空
result = QcloudCos.delete_folder(path, recursive: true) # 成功
```

#### 列举目录下文件或目录

1.  接口说明

 用于列举目录下文件和目录，调用者可以通过此接口查询目录下的文件和目录属性。

2.  方法

 ```ruby
 QcloudCos.list(path, options = {}) # 列出文件或者目录
 QcloudCos.list_folders(path, options = {}) # 列出目录
 QcloudCos.list_files(path, options = {}) # 列出文件
 QcloudCos.list(path, options = {}) # path 不为 / 结尾，则为搜索该前缀的文件或者目录
 ```

3.  参数和返回值

参数说明：

|参数名 |类型 |必须 |默认值 |参数描述|
|------|----|-----|------|------|
|path|  String| 是  |'/'|   目录的全路径，以"/"开头，api会补齐｜
|options| Hash| 否 | {} | 额外参数|
|options['num'] |int    |否 |100    |要查询的目录/文件数量|
|options['context']|    String| 否| null|   透传字段，查看第一页，则传空字符串。若需要翻页，需要将前一页返回值中的context透传到参数中。order用于指定翻页顺序。若order填0，则从当前页正序/往下翻页；若order填1，则从当前页倒序/往上翻页|
|options['order']   |int|   否| 0|  默认正序(=0), 填1为反序|
|options['pattern'] |String |否 |eListBoth| eListBoth,eListDirOnly,eListFileOnly 默认eListBoth|

返回值, List 对象:

|属性 |类型 |必然返回 |描述 |
|----|-----|-------|-----|
|has_more   |Boolean|   是  |是否有内容可以继续往前/往后翻页|
|context    |String |是|    透传字段，查看第一页，则传空字符串。若需要翻页，需要将前一页返回值中的context透传到参数中。order用于指定翻页顺序。若order填0，则从当前页正序/往下翻页；若order填1，则从当前页倒序/往上翻页|
|dircount   |String |是|    子目录数量(总)|
|filecount]  |String |是 |子文件数量(总)|
|objects  | Hash| 是  | FileObject 和 FolderObject 集合|

FileObject 对象

|属性 |类型 |必然返回 |描述 |
|----|-----|-------|-----|
|name|String|    是  |文件名字|
|biz_attr  |String|    是  |文件属性，业务端维护|
|ctime |String|    是  |文件的创建时间，unix时间戳|
|mtime |String|    是  |文件的修改时间，unix时间戳|
|filesize  |Int|   否  |文件大小|
|filelen   |Int|   否  |文件已传输大小(通过与filesize对比可知文件传输进度)|
|sha   |String|    否  |文件sha|
|access_url|   String  |否 |生成的文件下载url|

FolderObject 对象


|属性 |类型 |必然返回 |描述|
|----|-----|-------|----|
|name|String|    是  |目录名字|
|biz_attr  |String|    是  |目录属性，业务端维护|
|ctime |String|    是  |目录的创建时间，unix时间戳|
|mtime |String|    是  |目录的修改时间，unix时间戳|


API 请求错误，则抛出 RequestError 异常


|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| API 错误码|
|message| String| 错误信息|
|original_response| Response| 原始返回结果|


示例代码：

```ruby
path = "/myFolder/"
result = QcloudCos.list(path, num: 20)
prefix= "/myFolder/2015-";
result = QcloudCos.list(prefix, num: 20)
```



### 文件操作

#### 文件上传

1． 接口说明

用于较小文件(一般小于8MB)的上传，调用者可以通过此接口上传较小的文件并获得文件的url，较大的文件请使用分片上传接口。

2． 方法

```ruby
QcloudCos.upload(path, file_or_bin, options = {})
```

3． 参数和返回值

参数说明：


|参数名 |类型 |必须 |默认值 |参数描述|
|------|----|-----|------|------|
|path   |String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
|file_or_bin| IO 或者 Binary| 否 | 无|一个IO对象或者文件内容 |
| options | Hash | 否 | 无 | 额外参数, 支持 bucket, 默认使用配置的 bucket |
| options['biz_attr'] | String| 否 | 无 | 文件属性，业务端自己维护 |


返回值, Hash:


|参数名 |类型 |必然返回 |参数描述 |
|------|----|--------|--------|
|code| Int| 是 |错误码，成功时为0|
|message|   String| 是|错误信息|
|data|  Hash|是|返回数据|
|data['access_url'] | String|   是  |生成的文件下载url|
|data['url']|   String  |是 |操作文件的url|
|data['resource_path']  |String|    是  |资源路径. 格式:/appid/bucket/xxx|

API 请求错误，则抛出 RequestError 异常


|参数名 |类型 |参数描述|
|------|----|-------|
|code| Int| API 错误码|
|message| String| 错误信息|
|original_response| Response| 原始返回结果|


示例代码：

```ruby
file = File.new("/data/test.log")
path = "/myFolder/test.log";
result = QcloudCos.upload(path, file, biz_attr: 'attr')
```

#### 查看文件和文件夹数目

1.  接口说明

 查看某路径下文件或者文件夹数目

2.  方法

 ```ruby
 QcloudCos.count(path, options = {})
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|-----|----|------|------|
| path   |String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
| options | Hash | 否 | 无 | 额外参数
| options['bucket'] | String| 否 | 配置的默认 bucket | Bucket 名称|


返回值, Hash

|参数名 |类型 |参数描述|
|------|-----|------|
|file_count | Integer | 文件数目 |
|folder_count | Integer | 文件夹数目 |


示例代码：

```ruby
QcloudCos.public_url("/myFolder/")  #=> { file_count: 10, folder_count: 100 }
```

#### 判断目录或者文件是否存在

1.  接口说明

 判断目录或者文件是否存在

2.  方法

 ```ruby
 QcloudCos.exists?(path, options = {}) 
 QcloudCos.exist?(path, options = {})
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|-----|----|------|------|
| path   |String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
| options | Hash | 否 | 无 | 额外参数
| options['bucket'] | String| 否 | 配置的默认 bucket | Bucket 名称|


返回值, Boolean

文件或者目录存在则返回 true，反之 false


示例代码：

```ruby
QcloudCos.exists?("/myFolder/")  #=> true
QcloudCos.exist?("/myFolder/")  #=> true
```


#### 判断目录是否为空

1.  接口说明

 判断目录是否为空，或者是否含有文件或者文件夹

2.  方法

 ```ruby
 QcloudCos.empty?(path, options = {}) 
 QcloudCos.contains_file?(path, options = {}) 
 QcloudCos.contains_folder?(path, options = {})
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|-----|----|------|------|
| path   |String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
| options | Hash | 否 | 无 | 额外参数
| options['bucket'] | String| 否 | 配置的默认 bucket | Bucket 名称|


返回值, Boolean

+ empty?  该路径下面没有文件和文件夹则返回 true , 反之 false
+ contains_file?  该路径下面有文件则返回 true , 反之 false
+ contails_folder?  该路径下面有文件夹则返回 true , 反之 false


示例代码：

```ruby
QcloudCos.empty?("/myFolder/")  #=> false
QcloudCos.contains_file?("/myFolder/")  #=> true
QcloudCos.contains_folder?("/myFolder/")  #=> false
```

#### 获取文件外网访问地址

1.  接口说明

 有防盗链情况下获取文件的外网访问地址，自动完成签名

2.  方法

 ```ruby
 QcloudCos.public_url(path, options = {})
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|-----|----|------|------|
|path   |String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
| options | Hash | 否 | 无 | 额外参数
| options['bucket'] | String| 否 | 配置的默认 bucket | Bucket 名称|


返回值, 带签名的外网可访问地址

API 请求错误，则抛出 RequestError 异常


|参数名 |类型 |参数描述|
|------|-----|------|
|code| Int| API 错误码|
|message| String| 错误信息|
|original_response| Response| 原始返回结果|

示例代码：

```ruby
path = "/myFolder/test.mp4"
result = QcloudCos.public_url(path)
```


## 分片上传

分片上传在大文件上传和断点续传方面有很大的作用。我们主要提供了三个接口来帮助你完成上传。

### 大文件分片上传

1.  接口说明

 用于较大文件的上传，调用者可以通过此接口上传较大文件并获得文件的url。
 该接口还还支持断点续传，如果由于网络原因，导致了上传失败，只需要重试即可在自动在之前中断的位置继续上传。
 
 如果你还需要更进一步的定制需求，可以使用更底层的接口：[init_slice_upload]() + [upload_part]()

2.  方法

 ```ruby
 QcloudCos.upload_slice(dst_path, src_path, options = {}, &block)
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|----|-----|------|-------|
| dst_path | String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
| src_path | String  |是 |无 |本地要上传文件的全路径|
| block | Blockk  |否 |无 |如果需要显示进度，可以传递一个 Block，Block 需要接受一个参数，是 0~1 的一个小数，表示当前进度|
| options | Hash | 否 | 无 | 额外参数
| options['bucket'] | String| 否 | 配置的默认 bucket | Bucket 名称|
| options['biz_attr'] | String| 否 | 无 | 文件属性，业务端自己维护 |
| options['slice_size'] |Integer    |否 | 3M|分片大小，用户可以根据网络状况自行设置|
| options['session']    |String |否 |null   |如果是断点续传, 则带上(唯一标识此文件传输过程的id, 由后台下发, 调用方透传)|


返回值, Hash:


|参数名 |类型 |必然返回 |参数描述 |
|------|----|--------|--------|
|code |Integer |是 |错误码，成功时为0|
|message |String |是 |错误信息|
|data |Array  |是 |返回数据|
|data['access_url'] | String| 是    |生成的文件下载url|
|data['url']    |String |是 |操作文件的url|
|data['resource_path']  |String |是 |资源路径. 格式:/appid/bucket/xxx|

API 请求错误，则抛出 RequestError 异常


|参数名 |类型 |参数描述 |
|------|----|--------|
|code | Int| API 错误码|
|message | String| 错误信息|
|original_response | Response | 原始返回结果|

示例代码：

```ruby
src_path= "/data/test.mp4"
dst_path = "/myFolder/test.mp4"
result = QcloudCos.upload_slice(dst_path, src_path)
result = QcloudCos.upload_slice(dst_path, src_path) do |pr|
  puts "uploaded #{pr * 100}%"
end
```

### 分片上传初始化

1.  接口说明

 初始化分片上传，正常会返回分片上传 session ID。
 
 注意：
 
 + 如果该文件 sha 值已存在，则直接返回成功，你可以根据结果中是否包含 data['url'] 判断。
 + 如果该文件上次分片上传没有成功，data['offset'] 表示了上次上传的位置，你可以从该位置开始上传。
 + 如果想断点续传，则需要传递上一次 session ID.

2.  方法

 ```ruby
 QcloudCos.init_slice_upload(path, filesize, sha, options = {})
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|----|-----|------|-------|
| path | String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
| filesize | Integer  |是 |无 |本地要上传文件大小|
| sha | String  |是 |无 |本地要上传文件 sha1 值 |
| options | Hash | 否 | 无 | 额外参数
| options['bucket'] | String| 否 | 配置的默认 bucket | Bucket 名称|
| options['biz_attr'] | String| 否 | 无 | 文件属性，业务端自己维护 |
| options['slice_size'] |Integer    |否 | 3M|分片大小，用户可以根据网络状况自行设置|
| options['session']    |String |否 |null   |如果是断点续传, 则带上(唯一标识此文件传输过程的id, 由后台下发, 调用方透传)|


返回值, Hash:


|参数名 |类型 |必然返回 |参数描述 |
|------|----|--------|--------|
|code |Integer |是 |错误码，成功时为0|
|message |String |是 |错误信息|
|data |Hash  |是 |返回数据||data['session'] | String| 否    |本次分片上传 session ID||data['offset'] | Int | 否   |本次分片上传开始传输的位移，当上次分片上传未成功时不为零||data['slice_size'] | Int | 否    |本次分片上传分片大小|
|data['access_url'] | String| 否    |生成的文件下载url|
|data['url']    |String |否 |操作文件的url|
|data['resource_path']  |String |否 |资源路径. 格式:/appid/bucket/xxx|

API 请求错误，则抛出 RequestError 异常


|参数名 |类型 |参数描述 |
|------|----|--------|
|code | Int| API 错误码|
|message | String| 错误信息|
|original_response | Response | 原始返回结果|

示例代码：

```ruby
file = File.new("/data/test.mp4")
filesize = file.size
sha = Digest::SHA1.file('/data/test.mp4').hexdigest
dst_path = "/myFolder/test.mp4"
result = QcloudCos.init_slice_upload(dst_path, filesize, sha)  # { data: { session: 'dsfasfda' }
```

### 分片上传数据

1.  接口说明

 分片上传数据，初始化之后可以分片上传数据，文件上传成功会返回文件的 url。
 
2.  方法

 ```ruby
 QcloudCos.upload_part(path, session, offset, content, options = {})
 ```

3.  参数和返回值

参数说明：


|参数名|类型 |必须 |默认值 |参数描述|
|-----|----|-----|------|-------|
| path | String|是  |无 |文件在COS服务端的全路径，不包括/appid/bucketname|
| session | Integer  |是 |无 |本次分片上传的 session ID, 初始化的时候会返回|
| offset | String  |是 |无 |本地要上传的位移|
| content | String  |是 |无 |本地要上传的内容 |
| options | Hash | 否 | 无 | 额外参数
| options['bucket'] | String| 否 | 配置的默认 bucket | Bucket 名称|


返回值, Hash:


|参数名 |类型 |必然返回 |参数描述 |
|------|----|--------|--------|
|code |Integer |是 |错误码，成功时为0|
|message |String |是 |错误信息|
|data |Hash  |是 |返回数据||data['session'] | String| 否    |本次分片上传 session ID||data['offset'] | Int | 否   |本次分片上传传输的开始位移，如果使用多线程上传，可用于确定分片上传结果|
|data['access_url'] | String| 否    |生成的文件下载url|
|data['url']    |String |否 |操作文件的url|
|data['resource_path']  |String |否 |资源路径. 格式:/appid/bucket/xxx|

API 请求错误，则抛出 RequestError 异常


|参数名 |类型 |参数描述 |
|------|----|--------|
|code | Int| API 错误码|
|message | String| 错误信息|
|original_response | Response | 原始返回结果|

示例代码：

```ruby
session = 'dsfasfda'
result = QcloudCos.upload_part(dst_path, session, 100, 'Hello')
```

## 命令行工具

为了更方便地管理你的 COS，我们提供了命令行工具。

我们主要提供了五个基本命令： info, list, upload, download, remove 来完成你的操作

```
$ qcloud-cos help

NAME:

    qcloud-cos

  DESCRIPTION:

    command-line tool for Qcloud COS

  COMMANDS:
        
    config   Init config, eg: qcloud-cos config         
    download Download objects from COS          
    help     Display global or [command] help documentation             
    info     Obtain information         
    list     List objects under [dest_path]             
    remove   Remove objects from COS            
    upload   Upload file or folder to COS       

  GLOBAL OPTIONS:
        
    -h, --help 
        Display help documentation
        
    -v, --version 
        Display version information
        
    -t, --trace 
        Display backtrace when an error occurs
```

### 命令行配置

在使用之前，你需要先做一些配置，最快速的方式是使用 `qcloud-cos config` 命令:

```
$ qcloud-cos config
Qcloud COS APP ID: 
Qcloud COS Secret ID: 
Qcloud COS Secret Key: 
Default Qcloud COS Endpoint [http://web.file.myqcloud.com/files/v1/]: 
Default Qcloud COS Bucket: 
```

它会自动在当前目录下生成一个 `.qcloud-cos.yml` 配置文件。

如果不使用配置文件，你也可以使用环境变量：

```
export QCLOUD_COS_APP_ID='<your-app-id>'
export QCLOUD_COS_SECRET_ID='<your-secret-id>'
export QCLOUD_COS_SECRET_KEY='<your-secret-key>'
export QCLOUD_COS_ENDPOINT='http://web.file.myqcloud.com/files/v1/'
export QCLOUD_COS_BUCKET='<your-bucket-name>'
export QCLOUD_COS_SSL_CA_FILE='<your-ssl-ca-file-path>'
```

***注意：环境变量会覆盖配置文件中的设置***


### info

查看 Bucket，文件或者文件夹信息

基本用法： `qcloud-cos info [options] [dest_path]`

使用范例：

```
# 查看 Bucket 信息
$ qcloud-cos info

# 查看 /production.log 信息  
$ qcloud-cos info /production.log

# 查看 /test/ 信息
$ qcloud-cos info /test/

# 查看 bucket2 上的 /production.log 信息
$ qcloud-cos info --bucket bucket2 /production.log 
```

### list

列出文件或者文件夹

基本用法： `qcloud-cos list [options] [dest_path]`

使用范例：

```
# 列出 / 下面的所有对象
$ qcloud-cos list 

# 列出 /test/ 下面的所有对象
$ qcloud-cos list /test/ 

# 列出 /test/ 下面的前 10 个对象
$ qcloud-cos list --num 10 /test/ 

# 列出 bucket2 的 /test/ 下面的所有对象
$ qcloud-cos list --bucket bucket2 /test/ 
```

### upload

上传文件或者目录到 COS

基本用法： `qcloud-cos upload [options] file [dest_path]`

使用范例：

```
# 把 production.log 上传到 /
$ qcloud-cos upload production.log 

# 把 production.log 上传到 /data/ 下面
$ qcloud-cos upload production.log /data/ 

# 把 ./test/ 整个文件夹上传到 /data/ 下面
$ qcloud-cos upload test/ /data/  

# 把 ./test/ 整个文件夹上传到 bucket2 的 /data/ 下面
$ qcloud-cos upload --bucket bucket2 test/ /data/  
```

### download

下载文件或者目录

基本用法： `qcloud-cos download [options] dest_path [save_path]`

使用范例：

```
# 把 /data/production.log 下载到当前目录
$ qcloud-cos download /data/production.log 

# 把 /data/production.log 下载到 ./data/ 下
$ qcloud-cos download /data/production.log ./data   
      
# 把 /data/test/ 整个目录下载并保存到 ./data/ 目录下面
$ qcloud-cos download /data/test/ ./data
        
# 把 bucket2 下的 /data/test/ 整个目录下载并保存到 ./data/ 下面
$ qcloud-cos download --bucket bucket2 /data/test/ ./data
```


### remove

删除目录或者文件夹

基本用法： `qcloud-cos remove [options] dest_path`

使用范例：

```
# 删除文件/data/production.log
$ qcloud-cos remove /data/production.log
        
# 删除目录 /data/test/， 目录非空会失败
$ qcloud-cos remove /data/test/
        
# 级联删除目录 /data/test/
$ qcloud-cos remove --recursive /data/test/
        
# 删除 bucket2 下面的目录 /data/test/
$ qcloud-cos download --bucket bucket2 /data/test/
```



## 其它资源

+ [RDoc 文档](http://www.rubydoc.info/gems/qcloud_cos)
+ [腾讯 COS 详细文档](http://www.qcloud.com/doc/product/227/%E4%BA%A7%E5%93%81%E4%BB%8B%E7%BB%8D)
