# 端口扫描工具 (Port Scan)

原本Android上面有一个PortScan工具，不知道是不是系统兼容性问题，它的线程数配置跟假的一样，扫描速度特别慢，而且端口输入还麻烦。

现在重新创建了基于 Flutter 的跨平台 TCP 端口扫描工具，支持 Android、Window，理论上也支持 iOS、Linux、macOS，但是我没测过。

## 功能特性

### IP 地址输入

| 方式 | 说明 | 示例 |
|------|------|------|
| 直接 IP | 输入单个 IP 地址 | `192.168.1.1` |
| 域名解析 | 通过 DNS 将域名解析为 IP | `www.example.com` |
| 网段/掩码 | 扫描整个子网 | `192.168.1.0/24` |
| IP 范围 | 扫描两个 IP 之间的所有地址 | `192.168.1.1:192.168.1.254` |

支持累计添加多个 IP 目标，自动去重。

### 端口输入

| 方式 | 说明 | 示例 |
|------|------|------|
| 直接端口 | 输入单个端口号 | `22` |
| 端口范围 | 扫描端口区间 | `1:1024` |
| 常用端口 | 从预设列表中选择 | SSH/FTP/HTTP/HTTPS/MySQL 等 |

内置 24 种常用端口预设，支持全选/单选。

### 扫描配置

- **连接超时**：1000–10000ms 可调，提供快捷选择
- **并发线程数**：10–500 可调，信号量控制并发
- **服务识别**：自动识别 100+ 常见端口对应的服务名称
- **Banner 抓取**：尝试获取开放端口返回的 Banner 信息

### 结果展示

- 实时扫描进度（进度条 + 百分比 + 统计）
- 开放端口实时展示（IP:端口 + 服务名 + 延迟）
- 扫描摘要（总扫描数 / 开放 / 关闭 / 耗时）
- 单端口详情页

### 数据管理

- 扫描历史记录（最近 20 次）
- 结果导出为 CSV（可用 Excel 打开）
- 结果导出为 JSON
- 一键复制开放端口列表

## 项目结构

```
lib/
├── main.dart                   # 应用入口
├── models/
│   ├── scan_target.dart        # IP 目标 & 端口条目模型
│   ├── scan_result.dart        # 扫描结果 & 进度 & 摘要模型
│   └── scan_config.dart        # 扫描配置模型
├── services/
│   ├── ip_parser.dart          # IP 解析器（4 种输入方式）
│   ├── port_parser.dart        # 端口解析器（3 种输入方式）
│   ├── port_scanner.dart       # TCP 扫描引擎
│   ├── service_detector.dart   # 端口→服务名映射
│   ├── scan_history.dart       # 扫描历史 & 导出服务
│   └── scan_state.dart         # 全局状态管理
└── pages/
    ├── home_page.dart          # 首页
    ├── ip_input_page.dart      # IP 输入页
    ├── port_input_page.dart    # 端口输入页
    ├── scan_page.dart          # 扫描进度 & 结果页
    ├── result_detail_page.dart # 结果详情页
    ├── settings_page.dart      # 设置页
    └── history_page.dart       # 历史记录页
```

## 运行

```bash
# 安装依赖
flutter pub get

# 运行
flutter run
```

## 注意事项

- 请确保拥有扫描目标 IP 地址的合法授权
- 未经授权的端口扫描可能违反法律法规
- 高并发扫描可能触发防火墙规则
- Web 平台因浏览器限制不支持 TCP Socket 扫描