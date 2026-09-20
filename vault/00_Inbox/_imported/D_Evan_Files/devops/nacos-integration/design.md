# Nacos微服务改造设计文档

## Overview

本设计文档描述了将现有的传统Spring 4.x单体应用改造为支持Nacos服务注册与发现、实现负载均衡的微服务架构的技术方案。改造遵循"最小侵入"原则，不修改现有业务代码，通过添加依赖、配置和少量基础设施代码实现微服务化。

当前项目技术栈：
- Spring Framework 4.0.5
- MyBatis 3.5.9
- Maven多模块项目
- 传统XML配置方式
- Tomcat/Jetty容器部署

改造目标：
- 集成Nacos服务注册与发现
- 实现客户端负载均衡
- 支持配置中心
- 保持业务代码零修改
- 支持多环境部署

## Architecture

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Nacos Server                            │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │  服务注册中心     │      │   配置中心        │            │
│  │  (Registry)      │      │  (Config)        │            │
│  └──────────────────┘      └──────────────────┘            │
└─────────────────────────────────────────────────────────────┘
           ↑                           ↑
           │ 注册/心跳/发现              │ 配置拉取/监听
           │                           │
┌──────────┴───────────────────────────┴──────────────────────┐
│                   应用实例层                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  dify-api-api (Web应用)                              │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ Nacos Client │  │ Ribbon LB    │                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │         Spring MVC Controllers                │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │         Service Layer (业务逻辑)              │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │         DAO Layer (MyBatis)                   │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 服务注册流程

```
应用启动 → 加载Nacos配置 → 初始化NacosNamingService → 
注册服务实例 → 启动心跳线程 → 应用就绪
```

### 服务调用流程

```
发起HTTP请求 → RestTemplate拦截 → 解析服务名 → 
从Nacos获取实例列表 → Ribbon负载均衡选择实例 → 
替换服务名为实际IP:Port → 发送HTTP请求 → 返回响应
```

## Components and Interfaces

### 1. Nacos客户端集成组件

#### NacosServiceRegistry
服务注册核心组件，负责将应用实例注册到Nacos。

```java
public class NacosServiceRegistry implements ApplicationListener<ContextRefreshedEvent> {
    private NamingService namingService;
    private String serviceName;
    private String ip;
    private int port;
    
    // 应用启动完成后自动注册
    void onApplicationEvent(ContextRefreshedEvent event);
    
    // 注册服务实例
    void register() throws NacosException;
    
    // 注销服务实例
    void deregister() throws NacosException;
}
```

#### NacosDiscoveryClient
服务发现客户端，提供查询服务实例的能力。

```java
public class NacosDiscoveryClient {
    private NamingService namingService;
    
    // 获取所有健康的服务实例
    List<Instance> getInstances(String serviceName) throws NacosException;
    
    // 获取所有服务名列表
    List<String> getServices() throws NacosException;
    
    // 选择一个实例（带负载均衡）
    Instance selectInstance(String serviceName) throws NacosException;
}
```

### 2. 负载均衡组件

#### LoadBalancedRestTemplate
增强的RestTemplate，支持服务名调用和负载均衡。

```java
@Component
public class LoadBalancedRestTemplate extends RestTemplate {
    private NacosDiscoveryClient discoveryClient;
    private LoadBalancer loadBalancer;
    
    // 拦截请求，解析服务名并替换为实际地址
    @Override
    protected <T> T doExecute(URI url, HttpMethod method, 
                              RequestCallback requestCallback, 
                              ResponseExtractor<T> responseExtractor);
}
```

#### LoadBalancer
负载均衡器接口及实现。

```java
public interface LoadBalancer {
    Instance choose(List<Instance> instances);
}

// 轮询策略
public class RoundRobinLoadBalancer implements LoadBalancer {
    private AtomicInteger position = new AtomicInteger(0);
    
    @Override
    public Instance choose(List<Instance> instances) {
        int pos = position.getAndIncrement() % instances.size();
        return instances.get(pos);
    }
}

// 随机策略
public class RandomLoadBalancer implements LoadBalancer {
    private Random random = new Random();
    
    @Override
    public Instance choose(List<Instance> instances) {
        return instances.get(random.nextInt(instances.size()));
    }
}

// 权重策略
public class WeightedLoadBalancer implements LoadBalancer {
    @Override
    public Instance choose(List<Instance> instances) {
        // 根据实例权重选择
    }
}
```

### 3. 配置管理组件

#### NacosConfigManager
配置中心客户端，负责从Nacos加载和监听配置变化。

```java
public class NacosConfigManager implements ApplicationContextAware {
    private ConfigService configService;
    private ApplicationContext applicationContext;
    
    // 加载配置
    String getConfig(String dataId, String group) throws NacosException;
    
    // 监听配置变化
    void addListener(String dataId, String group, Listener listener);
    
    // 刷新Spring配置
    void refreshConfig(String content);
}
```

### 4. 健康检查组件

#### HealthCheckEndpoint
提供健康检查接口供Nacos调用。

```java
@Controller
@RequestMapping("/actuator")
public class HealthCheckEndpoint {
    
    @RequestMapping(value = "/health", method = RequestMethod.GET)
    @ResponseBody
    public Map<String, Object> health() {
        // 检查数据库连接
        // 检查关键服务状态
        // 返回健康状态
    }
}
```

## Data Models

### 服务实例信息

```java
public class ServiceInstance {
    private String serviceName;      // 服务名称
    private String instanceId;       // 实例ID
    private String ip;               // IP地址
    private int port;                // 端口号
    private boolean healthy;         // 健康状态
    private Map<String, String> metadata;  // 元数据
    private double weight;           // 权重
    private String clusterName;      // 集群名称
}
```

### Nacos配置

```java
public class NacosProperties {
    private String serverAddr;       // Nacos服务器地址
    private String namespace;        // 命名空间
    private String serviceName;      // 服务名称
    private String group;            // 分组
    private String clusterName;      // 集群名称
    private Map<String, String> metadata;  // 元数据
    private int weight;              // 权重
}
```

## Error Handling

### 异常类型

1. **ServiceRegistrationException**: 服务注册失败
   - 原因：Nacos服务器不可达、网络问题、配置错误
   - 处理：记录错误日志，应用继续启动但不提供服务发现功能

2. **ServiceNotFoundException**: 目标服务不存在
   - 原因：服务名错误、服务未注册
   - 处理：抛出异常，返回404错误给调用方

3. **NoAvailableInstanceException**: 无可用服务实例
   - 原因：所有实例都不健康、服务已下线
   - 处理：抛出异常，返回503错误给调用方

4. **LoadBalancerException**: 负载均衡失败
   - 原因：实例列表为空、负载均衡算法错误
   - 处理：记录错误日志，尝试使用默认策略

5. **ConfigLoadException**: 配置加载失败
   - 原因：配置不存在、格式错误、网络问题
   - 处理：使用本地默认配置，记录警告日志

### 错误处理策略

```java
@ControllerAdvice
public class NacosExceptionHandler {
    
    @ExceptionHandler(ServiceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleServiceNotFound(ServiceNotFoundException ex) {
        return ResponseEntity.status(404).body(new ErrorResponse(ex.getMessage()));
    }
    
    @ExceptionHandler(NoAvailableInstanceException.class)
    public ResponseEntity<ErrorResponse> handleNoAvailableInstance(NoAvailableInstanceException ex) {
        return ResponseEntity.status(503).body(new ErrorResponse(ex.getMessage()));
    }
}
```

## Testing Strategy

### 单元测试

测试框架：JUnit 4 + Mockito

测试范围：
- NacosServiceRegistry的注册/注销逻辑
- LoadBalancer的各种策略实现
- NacosDiscoveryClient的服务发现逻辑
- 配置加载和刷新逻辑

### 集成测试

测试场景：
1. 应用启动后成功注册到Nacos
2. 通过服务名成功调用其他服务
3. 多实例场景下负载均衡正常工作
4. 配置变更后应用自动刷新
5. 服务实例下线后自动从列表移除

### 性能测试

测试指标：
- 服务注册耗时 < 1秒
- 服务发现耗时 < 100ms
- 负载均衡选择耗时 < 10ms
- 配置刷新耗时 < 500ms

## Implementation Notes

### 依赖版本选择

由于项目使用Spring 4.0.5，需要选择兼容的Nacos客户端版本：
- nacos-client: 1.4.6（支持Spring 4.x）
- 不使用Spring Cloud Alibaba（需要Spring Boot）
- 直接使用Nacos原生API

### 配置文件结构

```
dify-api-api/src/main/resources/
├── nacos/
│   ├── nacos-dev.properties      # 开发环境配置
│   ├── nacos-sit.properties      # 测试环境配置
│   └── nacos-prod.properties     # 生产环境配置
└── spring/
    └── spring-nacos.xml          # Nacos相关Bean配置
```

### 启动流程优化

1. 应用启动时先初始化Nacos客户端
2. 等待Spring容器完全启动后再注册服务
3. 注册失败不影响应用启动
4. 提供开关可以禁用Nacos功能

### 兼容性考虑

1. 保持原有的直接IP调用方式仍然可用
2. 通过配置开关控制是否启用Nacos
3. 支持本地开发环境不依赖Nacos
4. 提供降级方案，Nacos不可用时使用本地配置

## Deployment Considerations

### 部署架构

```
┌─────────────────────────────────────────────────────────┐
│                    Nginx (负载均衡)                       │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌───────▼──────┐
│ 应用实例1     │  │ 应用实例2     │  │ 应用实例3     │
│ 192.168.1.10 │  │ 192.168.1.11 │  │ 192.168.1.12 │
│ Port: 8080   │  │ Port: 8080   │  │ Port: 8080   │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                ┌─────────▼──────────┐
                │   Nacos Cluster    │
                └────────────────────┘
```

### 环境隔离

使用Nacos命名空间实现环境隔离：
- dev: 开发环境命名空间
- sit: 测试环境命名空间
- prod: 生产环境命名空间

### 配置管理

配置优先级（从高到低）：
1. Nacos配置中心
2. 本地配置文件
3. 默认配置

### 监控和运维

1. 通过Nacos控制台监控服务状态
2. 配置日志输出到统一日志平台
3. 设置告警规则（服务下线、注册失败等）
4. 定期检查服务健康状态

## Migration Plan

### 阶段1：准备阶段
1. 搭建Nacos服务器（单机或集群）
2. 添加Maven依赖
3. 创建配置文件

### 阶段2：开发阶段
1. 实现服务注册组件
2. 实现服务发现组件
3. 实现负载均衡组件
4. 实现配置管理组件
5. 编写单元测试

### 阶段3：测试阶段
1. 本地环境测试
2. 开发环境部署测试
3. 测试环境集成测试
4. 性能测试

### 阶段4：上线阶段
1. 灰度发布（先上线1-2个实例）
2. 观察监控指标
3. 逐步扩展到所有实例
4. 完全切换到Nacos模式

### 回滚方案
1. 通过配置开关禁用Nacos功能
2. 恢复到传统部署模式
3. 保留原有配置文件作为备份
