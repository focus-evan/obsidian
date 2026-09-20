# 使用说明

## 已完成内容
- 已按口播结构创建分章节素材目录。
- 已下载一批可直接使用的 NASA / SpaceX Flickr / Wikimedia 素材。
- 已为部分无法直接自动下载的 SpaceX 历史视频创建快捷链接文件（`.url`）。

## 目录规则
- `01_hook_ipo`：上市钩子、估值、火箭大场面、数据图
- `02_early_mars_and_russia`：火星梦想、早期动机
- `03_first_principles`：发动机、控制中心、工程感
- `04_falcon1_failures_success`：Falcon 1 四次发射链接
- `05_nasa_dragon_iss`：Dragon / ISS / 商业货运
- `06_reusability_falcon9`：Falcon 9 / 回收 / 可复用
- `07_starlink_network`：Starlink / 卫星网络 / 通信基础设施
- `08_elon_spacex_broll`：马斯克 / SpaceX HQ / 采访感素材
- `09_concept_mars_network_finance`：火星、地球夜景、概念补画面

## 文件命名规则
格式：`SXX_CYY_TZZZ_source_desc.ext`

- `SXX`：章节号
- `CYY`：章节内序号
- `TZZZ`：类型
  - `VID` 视频
  - `IMG` 图片
  - `LNK` 链接快捷方式
- `source`：来源简称（nasa / spacex / wiki / spacex_api）
- `desc`：英文简述

## 剪辑建议
1. 先从 `asset_manifest.md` 查看全部素材和原始链接。
2. Falcon 1 历史发射已放在 `04_falcon1_failures_success` 里，当前为 `.url` 快捷方式；如需转为本地视频，建议在已登录浏览器环境中补抓。
3. `05`、`06`、`07`、`08` 已有较多可直接用的图像/视频，可先完成主片粗剪。
4. `09_concept_mars_network_finance` 适合继续补 AI 生成镜头，例如火星温室、全球联网、资本市场抽象动画。

## 当前缺口
- `02_early_mars_and_russia`：缺俄罗斯买火箭、早期创业办公室、PayPal 后人物状态类真实镜头。
- `04_falcon1_failures_success`：已有官方视频链接，但未落地为本地 mp4。
- `09_concept_mars_network_finance`：还缺资本市场、IPO、全球通信网络的动态概念素材。

## 清单文件
- `00_docs/asset_manifest.md`：总表
- `00_docs/download_manifest_nasa.json`
- `00_docs/download_manifest_spacex_api.json`
- `00_docs/download_manifest_spacex_flickr.json`
- `00_docs/download_manifest_wikimedia.json`
- `00_docs/download_manifest_concepts.json`

## 版权说明
按你的要求，本批素材按“内部 demo / 节课使用”口径收集。若后续改为公开发布，建议逐条复核第三方平台和新闻来源的授权边界。
