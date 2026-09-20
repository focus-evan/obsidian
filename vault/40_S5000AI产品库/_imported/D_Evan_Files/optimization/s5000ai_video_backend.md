# S5000AI 视频模块后端开发进度

## 开发完成清单

### 一、数据库建表脚本
| 文件 | 表数量 | 状态 |
|------|--------|------|
| [video_module_tables.sql](file:///D:/Evan/Codes/dify-api-openservice/doc/video_module_tables.sql) | 8张表 | ✅ 完成 |

8张表：`ai_video_resource`, `ai_video_category`, `ai_video_permission_group`, `ai_video_permission_group_video`, `ai_user_video_permission`, `ai_video_watch_log`, `ai_user_action_log`, `ai_user_profile`

### 二、dify-api-openservice（用户端后端）

#### PO实体类（7个）
| 文件 | 说明 |
|------|------|
| [AiVideoResourcePo.java](file:///D:/Evan/Codes/dify-api-openservice/dify-api-common/src/main/java/com/yuzhidi/po/AiVideoResourcePo.java) | 视频资源 |
| [AiVideoCategoryPo.java](file:///D:/Evan/Codes/dify-api-openservice/dify-api-common/src/main/java/com/yuzhidi/po/AiVideoCategoryPo.java) | 视频分类 |
| [AiVideoPermissionGroupPo.java](file:///D:/Evan/Codes/dify-api-openservice/dify-api-common/src/main/java/com/yuzhidi/po/AiVideoPermissionGroupPo.java) | 权限组 |
| [AiUserVideoPermissionPo.java](file:///D:/Evan/Codes/dify-api-openservice/dify-api-common/src/main/java/com/yuzhidi/po/AiUserVideoPermissionPo.java) | 用户权限 |
| [AiVideoWatchLogPo.java](file:///D:/Evan/Codes/dify-api-openservice/dify-api-common/src/main/java/com/yuzhidi/po/AiVideoWatchLogPo.java) | 观看记录 |
| [AiUserActionLogPo.java](file:///D:/Evan/Codes/dify-api-openservice/dify-api-common/src/main/java/com/yuzhidi/po/AiUserActionLogPo.java) | 操作日志 |
| [AiUserProfilePo.java](file:///D:/Evan/Codes/dify-api-openservice/dify-api-common/src/main/java/com/yuzhidi/po/AiUserProfilePo.java) | 用户画像 |

#### MyBatis Mapper接口 + XML（6组）
| Mapper | XML |
|--------|-----|
| [AiVideoResourceMapper](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/java/com/yuzhidi/dao/ai/mapper/AiVideoResourceMapper.java) | [XML](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/resources/mapper/AiVideoResourceMapper.xml) |
| [AiVideoCategoryMapper](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/java/com/yuzhidi/dao/ai/mapper/AiVideoCategoryMapper.java) | [XML](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/resources/mapper/AiVideoCategoryMapper.xml) |
| [AiVideoPermissionMapper](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/java/com/yuzhidi/dao/ai/mapper/AiVideoPermissionMapper.java) | [XML](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/resources/mapper/AiVideoPermissionMapper.xml) |
| [AiVideoWatchLogMapper](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/java/com/yuzhidi/dao/ai/mapper/AiVideoWatchLogMapper.java) | [XML](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/resources/mapper/AiVideoWatchLogMapper.xml) |
| [AiUserActionLogMapper](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/java/com/yuzhidi/dao/ai/mapper/AiUserActionLogMapper.java) | [XML](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/resources/mapper/AiUserActionLogMapper.xml) |
| [AiUserProfileMapper](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/java/com/yuzhidi/dao/ai/mapper/AiUserProfileMapper.java) | [XML](file:///D:/Evan/Codes/dify-api-openservice/dify-api-dao/src/main/resources/mapper/AiUserProfileMapper.xml) |

#### Service（4个）
| 接口 | 实现 |
|------|------|
| [VideoService](file:///D:/Evan/Codes/dify-api-openservice/dify-api-interface/src/main/java/com/yuzhidi/service/ai/VideoService.java) | [VideoServiceImpl](file:///D:/Evan/Codes/dify-api-openservice/dify-api-service-provider/src/main/java/com/yuzhidi/service/impl/ai/VideoServiceImpl.java) |
| [VideoPermissionService](file:///D:/Evan/Codes/dify-api-openservice/dify-api-interface/src/main/java/com/yuzhidi/service/ai/VideoPermissionService.java) | [VideoPermissionServiceImpl](file:///D:/Evan/Codes/dify-api-openservice/dify-api-service-provider/src/main/java/com/yuzhidi/service/impl/ai/VideoPermissionServiceImpl.java) |

#### Controller用户端（2个，共8个接口）
| 路径 | 方法 | 说明 |
|------|------|------|
| `ai/video/list` | POST | 视频列表(按分类/标签) |
| `ai/video/detail` | POST | 视频详情+权限标识 |
| `ai/video/playUrl` | POST | 鉴权+生成播放URL |
| `ai/video/watch/report` | POST | 上报观看进度 |
| `ai/video/watch/history` | POST | 观看历史 |
| `ai/video/category/list` | POST | 分类列表 |
| `ai/user/action/log` | POST | 操作日志上报 |
| `ai/user/profile` | POST | 用户画像查询 |

### 三、stock-scoring（管理后台，共18个接口）

| 文件 | 说明 |
|------|------|
| [AiVideoManageBusi.java](file:///D:/Evan/Codes/stock-scoring/stock-scroing-web-api/src/main/java/com/glenls/stock/web/busi/AiVideoManageBusi.java) | JFinal Db直查业务层 |
| [AiVideoManageController.java](file:///D:/Evan/Codes/stock-scoring/stock-scroing-web-api/src/main/java/com/glenls/stock/web/controller/AiVideoManageController.java) | 管理后台Controller |

**管理后台接口：**
| 路径 | 说明 |
|------|------|
| GET `/api/web/aivideo/list` | 视频列表 |
| POST `/api/web/aivideo/add` | 新增视频 |
| POST `/api/web/aivideo/update` | 更新视频 |
| POST `/api/web/aivideo/toggleStatus` | 上下架 |
| GET `/api/web/aivideo/category/list` | 分类列表 |
| POST `/api/web/aivideo/category/add` | 新增分类 |
| POST `/api/web/aivideo/category/update` | 更新分类 |
| GET `/api/web/aivideo/permission/groups` | 权限组列表 |
| POST `/api/web/aivideo/permission/addGroup` | 新增权限组 |
| POST `/api/web/aivideo/permission/updateGroup` | 更新权限组 |
| POST `/api/web/aivideo/permission/bindVideos` | 绑定视频 |
| POST `/api/web/aivideo/permission/unbindVideos` | 解绑视频 |
| GET `/api/web/aivideo/permission/groupVideos` | 权限组内视频 |
| POST `/api/web/aivideo/permission/grant` | 用户授权 |
| POST `/api/web/aivideo/permission/revoke` | 撤销权限 |
| GET `/api/web/aivideo/permission/userPermissions` | 查看用户权限 |
| GET `/api/web/aivideo/stats/playTop` | 播放TOP统计 |
| GET `/api/web/aivideo/stats/activeUsers` | 活跃用户统计 |

## 待办
- [ ] 在数据库执行 [video_module_tables.sql](file:///D:/Evan/Codes/dify-api-openservice/doc/video_module_tables.sql) 建表
- [ ] `dify-api-openservice` 编译打包部署
- [ ] `stock-scoring` 编译打包部署
- [ ] 后续接入 OSS SDK 生成签名URL（防盗链增强）
- [ ] 画像计算定时任务
- [ ] 前端 `wx-mini-S5000AI` 对接
