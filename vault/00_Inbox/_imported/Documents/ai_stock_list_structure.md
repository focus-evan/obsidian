# ai_stock_list 表结构说明

在 `dify-api-bzsj` 项目中，`ai_stock_list` 表主要用于存储所有监控股票的**基础档案信息**和**采集状态标识**。这些数据通常从外部数据源（如“理杏仁”）同步而来。该表以 `stockCode`（股票代码）作为唯一主键。

通过分析项目中的 `AiStockList` 实体类、Mapper XML 及相关业务代码，以下是该表的详细字段说明：

## 1. 基础识别信息

| 字段名 | 数据类型 (Java) | 含义说明 | 备注 |
| :--- | :--- | :--- | :--- |
| `stockCode` | String | **股票代码** | 表的主键（Primary Key） |
| `name` | String | 公司名称 | - |
| `market` | String | 市场/大类交易所 | `cn`：A股<br>`us`：美股<br>`hk`：港股 |
| `exchange` | String | 具体交易所名称 | 例如 `sse` (上交所), `szse` (深交所), `hkex` (港交所) |
| `currency` | String | 币种 | 例如 `CNY`, `HKD`, `USD` 等 |
| `seg_id` | String | 知识库分段 ID | 与知识库（如 Dify/LLM 向量库）关联的 Segment ID |

## 2. 上市与分类信息

| 字段名 | 数据类型 (Java) | 含义说明 | 备注 |
| :--- | :--- | :--- | :--- |
| `ipoDate` | String | 上市日期 | 格式通常为 `yyyy-MM-dd` |
| `delistedDate` | String | 退市时间 | 若未退市通常为空 |
| `listingStatus` | String | 上市状态 | 例如 `normally_listed` (正常上市) |
| `targetMarket` | String | 目标市场/板块 | 例如主板、创业板、科创板等 |
| `mutualMarkets` | String | 互联互通机制 | 标识是否属于沪股通、深股通、港股通等 |
| `sector` | String | 行业赛道 | 股票所属的行业或赛道分类 |
| `areaCode` | String | 区域代码 | 公司所属国家或地区的地理编码 |

## 3. 业务与财报属性

| 字段名 | 数据类型 (Java) | 含义说明 | 备注 |
| :--- | :--- | :--- | :--- |
| `fsTableType` | String | 财报类型 | 区分行业特性的财报格式（如一般企业、银行、保险、券商等） |
| `mainBusiness` | String | 主营业务 | 公司主要经营的业务范围描述 |
| `newStrategicBusiness`| String | 新兴战略业务 | 公司涉及的新兴战略性产业方向 |

## 4. 采集任务控制与系统状态

在定时任务和数据采集流水线中，该表也作为任务调度的状态跟踪表。

| 字段名 | 数据类型 (Java) | 含义说明 | 备注 |
| :--- | :--- | :--- | :--- |
| `reportDataCollected` | Boolean | 财报数据是否已采集 | 对应列 `report_data_collected`，标志是否已成功采集财务数据 |
| `stockInfoCollected` | Boolean | 基础信息是否已采集 | 对应列 `stock_info_collected`，标志是否已成功采集日频/基础数据 |
| `createTime` | Date | 创建时间 | Mybatis 自动填充/手动维护 |
| `updateTime` | Date | 更新时间 | Mybatis 自动填充/手动维护 |

> [!NOTE]
> **业务使用场景**：在项目代码（如 `AiDimensionController.java` 和调度任务 `ScheduleTask.java`）中，系统会根据 `ai_stock_list` 表中的 `listingStatus`（如只取 `normally_listed` 的票）、`market`（如只跑 `cn` 市场的票）以及 `*Collected` 采集标识位来分批过滤和拉取最新的股票财报 (`stock_report_data`) 和交易数据 (`stockinfo`)。
