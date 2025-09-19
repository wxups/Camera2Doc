# 上海广升信息技术有限公司 Mediatek 平台相机算法移植包 v3.1

为 Mediatek 系统扩展多种相机效果的移植包  

## 支持

### 算法支持

|          | 美颜    | 虚化    | 滤镜    | 贴纸    | 广角    | 普通夜景 | 超级夜景 | HDR     | 多帧降噪 | 视频防抖 | 照片水印 | 全景     | AI分类   | 文档发现 |
| :------ | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: |  :-----: | :-----: |  :-----: | 
| 预览     |    √    |    √    |    √    |  App √  |    √    |    -    |    -    |    -    |    -    |    √    |    -    |    √     |    √    |    √    |
| 成像     |    √    |    √    |    √    |  App √  |    √    |    √    |    √    |    √    |    √    |    √    |    √    |    √     |    -    |    √    |

默认为 HAL 层算法不带 App 标签，使用 Android Camera2 API 调用即可，我们会提供相应的 Key。  
带 App 标签的为应用层算法，使用我们的 App 或者集成我们应用层算法的 SDK 即可支持。  
该移植包仅包含 HAL 层算法和调用 HAL 层算法的 App 层 SDK，App 算法 SDK 请[联系我们](#认证)额外提供。  
所有 HAL 层算法都可以通过 JNI 转为 App 层算法，可以理解为支持 HAL 层的也支持 App 层，反之不行。  


**HAL 层集成方式的优缺点：**   
**优点：**  
- 首次集成速度快，只需根据移植包对比合入即可。
- SDK 方式的开发成本低，且应用层只需 1 行代码就能调用算法，不需要专业的 Android 相机 App 开发人员。  
- 运行速度相对 App 集成的快，不占用 App 内存（因为运行在相机进程）。  

**缺点：**  
- 依赖 MTK 平台，需要编译系统源码。  

**App 层集成方式的优缺点：**    
**优点：**  
- 适用性广，不依赖芯片平台，纯 Android 应用层，只要是 Android 系统即可运行。  

**缺点：**  
- 首次集成有大量开发工作，需要了解广升算法输入输出且做好对应处理。  
- 调用算法需要有专业的 Android 相机 App 开发人员，需要熟悉 Surface, Camera2 API, JNI 等技术。  
- 运行速度不如 HAL 层，且处理图像需占 App 内存。  

#### **HAL 算法类型**
|          | 美颜    | 虚化     | 滤镜    | 广角    | 普通夜景 | 超级夜景 | HDR     | 多帧降噪 | 视频防抖 | 照片水印 | 全景    | AI分类  | 文档发现 |
| :------- | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | 
| 流       |    √    |    √    |    √    |    √    |    -    |    -    |    -    |    -    |    √    |    -    |    √    |    √    |    √    | 
| 单帧     |    √    |    √    |    √    |    √    |    -    |    -    |    -    |    -    |    -    |    √    |    -    |    -    |    √    | 
| 多帧     |    -    |    -    |    -    |    -    |    √    |    √    |    √    |    √    |    -    |    -    |    -    |    -    |    -    | 

### Android 版本支持

| 版本       | Mediatek ISP6S | Mediatek ISP7 |
| :-------   | :-----: | :-----: |
| Android 10 |    -    |    -    |
| Android 11 |    -    |    -    |
| Android 12 - 16 |    √    |    √    |

关于其他 Android 版本的 MTK 平台相机支持或**其他算法需求**，请[联系我们](#认证)


## 开始

移植前请准备好文本对比工具，比如 [Beyond Compare](https://www.scootersoftware.com/)  

移植前须知：  
* 切勿这样对比 **(after | 系统源码)**，虽然可以很方便的合入到系统源码，但是也会合入不必要的部分，甚至产生冲突。  
  因为我们的 after 是基于 before 上做的修改，而我们的 before 与需要合入的系统源码不一定相同，很可能产生不必要的合入。  
  建议用对比工具这样对比 **(before | after)**，然后用编辑器单独打开系统源码要合入的文件，把差异一个一个合入，虽然比较慢，但是不会出错。  

* 移植包中遇到 **mt6768**, **mgvi_64_armv82**, **mssi_64_cn**, **k69v1_64_k419** 这类和编译参数相关的目录，请根据实际情况自行调整到正确的目录。  

### 移植步骤

1. **合入**  
   开始移植前需要知道目标系统的 Android 版本，ISP 版本（3、4、6s、7、7s、7sp），以便从以下表格中选择自己需要移植的内容。  
   _如果不清楚当前的 ISP 版本请默认选择 ISP6s，如果是天玑 9000 系列一般为 ISP7，具体以实际情况为准_  

   比如 **ISP6s**，则选择第 **1 行 1 列**中的所有内容移植，其他内容忽略。  
   比如 **ISP7** ，则选择第 **1 行 2 列**中的所有内容移植，其他内容忽略。  

   因 Mediatek 源码解耦编译，所以会区分 **vendor_codebase** 和 **system_codebase**，  
   **vnd** 前缀的请移植到 **vendor_codebase**，**sys** 前缀的请移植到 **system_codebase**。  

   如未解耦编译，说明唯一的一份源码即是 vnd 又是 sys，都移植上去即可。  

   |            | ISP3, ISP4, ISP6S   | ISP7, ISP7s, ISP7sp |
   | :-------   | :------------------ | :------------------ |
   | **Android 12 - 16** | vnd: [before](./before) \| [after](./after)<br/>vnd: [before-isp6s](./before-isp6s/) \| [after-isp6s](./after-isp6s/)<br/>sys: [before-system](./before-system) \| [after-system](./after-system) | vnd: [before](./before) \| [after](./after)<br/>vnd: [before-isp7](./before-isp7/) \| [after-isp7](./after-isp7/)<br/>sys: [before-system](./before-system) \| [after-system](./after-system) |

   移植工作量预计：  
   - vnd: before | after  
     广升的算法库，只有新增文件，复制粘贴到正确的位置即可。  
     **预计耗时 1 分钟**  
   - vnd: before-isp? | after-isp?  
     基于 MTK HAL 实现的图像处理，其中修改约 18 个文件。  
     **预计耗时 20~40 分钟**  
   - sys: before-system | after-system  
     包含广升相机 App 和 system prop 属性设置，复制粘贴到正确的位置即可。  
     **预计耗时 3 分钟**  
   - **总预计耗时为 24~44 分钟**  


1. **定制**

   合入完毕后不急着编译，请自答以下问题并作出操作以完成定制化  

   - 是否需要使用广升应用层的相机 App？  
     是：什么都不用做。  
     否：不用广升相机 App 则说明会使用 SDK 方式接入，需要做以下操作：  
      - 请将 SystemConfig.mk 中 ADUPS_CAMERA_APP_SUPPORT 设置为 no，不编译广升相机 App
        ```
        # 建议首次编译打开该宏（设置为 yes），用广升 App 确认算法是否导通，确认导通后再关闭该宏。
        ADUPS_CAMERA_APP_SUPPORT = no
        ```  

   - 是否想把广升相机 App 移到 packages 目录下？  
     是：自行移动后请务必保证 `after-system/vendor/adups/device.mk` 文件内所写入的属性能够在系统运行时读到。  
     > **注意：** 这里指的是 system_codebase 下的 App。vendor_codebase 下没有 App，**不建议把 `after/vendor/adups` 算法库目录放到 packages 下**，因为后期会频繁发布增量移植包来迭代算法，如果自行改动 vendor_codebase 中的目录结构，在后续合入增量移植包时定会产生不必要的麻烦。  

     否：什么都不用做。  

   - 源码编译脚本是否是 splity_build.py 2.0？  
     是：什么都不用做，移植包就是基于 splity_build.py 2.0 制作。  
     否：如果是 splity_build.py 1.0，VendorConfig.mk 中的宏不会生效，需要将 VendorConfig.mk 中的宏变量挪到对应的 ProjectConfig.mk 文件中。  
     ProjectConfig.mk 具体位置为 device\mediateksample\k69v1_64_k419\ProjectConfig.mk。

     > 附：  
     > Vendor 的宏变量:  
     > ISP6S：[device/mediatek/vendor/mgvi_64_armv82/VendorConfig.mk](after-isp6s/device/mediatek/vendor/mgvi_64_armv82/VendorConfig.mk)  
     > ISP7 ：[device/mediatek/vendor/mgvi_64_armv82/VendorConfig.mk](after-isp7/device/mediatek/vendor/mgvi_64_armv82/VendorConfig.mk)
     > 

   - 是否已经按照客户的实际需求开关对应的算法宏？  
     是：什么都不用做。  
     否：请按照邮件中的要求修改 SystemConfig.mk 中对应的宏（**仅修改 SystemConfig.mk 即可， VendorConfig.mk 无需修改建议保持默认的全开**）。 

     > 附：  
     > 
     > System 的宏变量:   
     > System：[device/mediatek/system/mssi_64_cn/SystemConfig.mk](after-system/device/mediatek/system/mssi_64_cn/SystemConfig.mk)  

   - 是否需要 16K 页面大小的支持？（vendor_codebase 是 Android 15 前的请忽略该问答）  
     从 Android 15 起，Google 要求现有 Native Library 都必须在 64 位设备上支持 16K 的页面大小，否则无法过 GMS 验证。    
     什么是 16K 页面大小请点击[这里](https://developer.android.com/guide/practices/page-sizes?hl=zh-cn)  
     是：请在过 GMS 验证前告知我们。  
     否：什么都不用做。  
     如果不知道是否需要可以先忽略。  

1. **编译**  
   编译 ROM。  
   如果是解耦编译请将 vendor_codebase 和 system_codebase 都编译后 Merge 为一个 ROM。  

1. 移植过程中如有任何问题请联系我们获得技术支持。  

## 相机 App

### 自研相机 App

  开发者需要在自研相机 App 内根据[广升算法调用文档 SDK Doc](./doc/README.md) 做开发。

### 广升相机 App

- 初版 App 用来确认移植成功。  
  App 需要迭代几个版本才能满足需求，所以需要提供**设备**，**移植后的 Userdebug ROM**，**系统签名**，都提供后我们会针对该 ROM 调试 App，调试完后 App 也可直接安装验证效果。

- 后续会多次收到移植包 Patch，收到后替换对应目录的文件即可完成版本迭代，一般不会再有比较耗时的修改类的文件。 


## 认证
该移植包内所有算法都是 Demo 版本，成像和预览都会带有 Demo 字样，如需商用请联系我们 PM 或商务授权。  
Email：[jinxing@abupdate.com](mailto:jinxing@abupdate.com)  

## 算法介绍

### 美颜
美颜模式，现在支持以下参数：

	瘦脸，大眼，磨皮，美白，红润，红唇  

我们支持调整各个刻度所对应的强度，为不同项目调整出最合适的效果（各项强度上限还有 50% 的调整空间）。  
然后将调好的配置放到源码中编译作为后续默认值。

### MFNR
支持 ISO 分段，可以很方便的指定不同 ISO 区间所对应的算法的各项参数，为不同项目调整出最合适的效果。  
可调参数有：降噪级别，边缘增强，提亮级别，饱和度，对比度，锐化强度，噪声加回。

### HDR
支持 ISO 分段，可以很方便的指定不同 ISO 区间所对应的算法的各项参数，为不同项目调整出最合适的效果。  
可调参数有：降噪级别，边缘增强，提亮级别，饱和度，对比度，去鬼影，效果优先和性能优先。

### 超级夜景
支持 ISO 分段，可以很方便的指定不同 ISO 区间所对应的算法的各项参数，为不同项目调整出最合适的效果。  
可调参数有：降噪级别，边缘增强，提亮级别，饱和度，对比度，去鬼影，效果优先和性能优先。

### AI 分类
在后摄预览时打开照片模式顶部的 AI 开关，对准相应事物会显示出相应事物的名称，现在可以识别以下事物：  

	食物，文档，交通工具（现在主要是识别汽车），花，人物，建筑，动物（目前支持猫狗），植物，海，天空，雪景，太阳，自然风光，生日，夜景，高山，城市，彩虹，喷泉，名片，银行卡，身份证，聚餐，瀑布




