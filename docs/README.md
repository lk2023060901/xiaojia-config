# xDooria-config 配置工具文档

## 概述

xDooria-config 是基于 [Luban](https://github.com/focus-creative-games/luban) 的游戏配置管理工具集，用于 xDooria 项目的配置数据生成和管理。

## 目录结构

```
xDooria-config/
├── bin/                    # Luban 可执行文件
│   ├── windows/           # Windows 平台
│   │   └── Luban.exe
│   ├── macos/             # macOS 平台
│   │   └── Luban
│   └── linux/             # Linux 平台
│       └── Luban
├── docs/                  # 文档目录
│   └── README.md
├── LICENSE
└── README.md
```

## Luban 工具介绍

Luban 是一个强大、易用、优雅、稳定的游戏配置解决方案，适用于从小型到超大型游戏项目。

### 核心特性

#### 1. 多语言支持（12+ 语言）
- **C#**: DotNet、Unity、NewtonSoft JSON
- **C++**: rawptr、sharedptr 指针模式
- **Go**: Golang
- **Java**: 标准 Java
- **JavaScript/TypeScript**: NodeJs、Cocos2、Cocos3
- **Lua**: 标准 Lua、Unity xLua
- **Python**: 标准 Python
- **Rust**: Rust 语言
- **Dart**: Dart/Flutter
- **GDScript**: Godot 引擎
- **PHP**: Web 后端
- **Erlang**: 服务端

#### 2. 丰富的数据源格式（输入）
- **Excel 族**: csv, xls, xlsx, xlsm
- **结构化数据**: json, xml, yaml, lua
- **增强的 Excel**: 支持复杂嵌套结构配置

#### 3. 多种导出格式（输出）

**二进制格式：**
- bin: 自定义二进制格式
- protobuf: Protocol Buffers (v2/v3)
- flatbuffers: FlatBuffers
- msgpack: MessagePack
- bson: BSON

**文本格式：**
- json: 标准 JSON（及多种变体）
- xml: XML 格式
- yaml: YAML 格式
- lua: Lua 表格式

#### 4. 完备的类型系统
- **基础类型**: int, float, string, bool, datetime
- **复合类型**: list, map, set
- **自定义类型**: bean（结构体）, enum（枚举）
- **OOP 支持**: 类型继承（用于行为树、技能等）
- **可选类型**: nullable 支持

#### 5. 强大的数据校验
- **ref 引用检查**: 引用完整性验证
- **path 路径检查**: 资源路径验证
- **range 范围检查**: 数值范围验证
- **自定义验证器**: 扩展验证逻辑

#### 6. 多目标配置
- **client**: 客户端配置
- **server**: 服务器配置
- **editor**: 编辑器配置
- **test**: 测试配置
- **all**: 全部配置

#### 7. 本地化（L10N）支持
- 多语言文本管理
- 文本键值对映射
- 支持多种本地化数据源

## 使用方法

### 基本命令格式

```bash
# Windows
Luban.exe [options]

# macOS / Linux
./Luban [options]
```

### 命令行参数

```bash
-s, --schemaCollector    # schema collector name
--conf                   # luban 配置文件（必需）
-t, --target             # 目标名称（必需，如 client/server/all）
-c, --codeTarget         # 代码生成目标（如 cs-bin, go-json）
-d, --dataTarget         # 数据生成目标（如 bin, json）
-p, --pipeline           # 管线名称
-f, --forceLoadTableDatas # 强制加载表数据
-i, --includeTag         # 包含标签
-e, --excludeTag         # 排除标签
-x <key>=<value>         # 扩展参数
```

### 常用代码生成目标（-c 参数）

#### C# 相关
- `cs-bin`: C# 二进制格式
- `cs-json`: C# JSON 格式
- `cs-dotnet-json`: C# DotNet JSON
- `cs-newtonsoft-json`: C# Newtonsoft JSON

#### Go 相关
- `go-bin`: Go 二进制格式
- `go-json`: Go JSON 格式

#### C++ 相关
- `cpp-bin`: C++ 二进制格式
- `cpp-ue-bp`: Unreal Engine 蓝图

#### 其他语言
- `java-bin`, `java-json`: Java
- `lua-bin`: Lua
- `python-json`: Python
- `typescript-bin`, `typescript-json`: TypeScript
- `rust-json`, `rust-bin`: Rust
- `dart-json`: Dart

#### 消息方案
- `protobuf2`, `protobuf3`: Protocol Buffers
- `flatbuffers`: FlatBuffers

### 常用数据生成目标（-d 参数）

- `bin`: 二进制格式
- `json`: JSON 格式
- `bson`: BSON 格式
- `xml`: XML 格式
- `lua`: Lua 格式
- `yaml`: YAML 格式
- `protobuf-bin`, `protobuf-json`: Protobuf
- `flatbuffers-json`: FlatBuffers
- `msgpack`: MessagePack

### 扩展参数示例（-x 参数）

```bash
-x outputCodeDir=Gen                    # 代码输出目录
-x outputDataDir=Datas                  # 数据输出目录
-x pathValidator.rootDir=/path/to/root  # 路径验证根目录
-x l10n.provider=default                # 本地化提供者
-x l10n.textFile.path=texts.json        # 本地化文本文件
-x l10n.textFile.keyFieldName=key       # 本地化键字段名
```

## 配置文件示例

### luban.conf 基本结构

```json
{
    "groups": [
        {"names": ["c"], "default": true},    // 客户端组
        {"names": ["s"], "default": true},    // 服务器组
        {"names": ["e"], "default": true},    // 编辑器组
        {"names": ["t"], "default": false}    // 测试组
    ],
    "schemaFiles": [
        {"fileName": "Defines", "type": ""},
        {"fileName": "Datas/__tables__.xlsx", "type": "table"},
        {"fileName": "Datas/__beans__.xlsx", "type": "bean"},
        {"fileName": "Datas/__enums__.xlsx", "type": "enum"}
    ],
    "dataDir": "Datas",
    "targets": [
        {"name": "client", "manager": "Tables", "groups": ["c"], "topModule": "cfg"},
        {"name": "server", "manager": "Tables", "groups": ["s"], "topModule": "cfg"},
        {"name": "all", "manager": "Tables", "groups": ["c","s","e"], "topModule": "cfg"}
    ]
}
```

## 使用示例

### 示例 1: 生成 Go 客户端代码和 JSON 数据

```bash
# macOS / Linux
cd /path/to/xDooria-config/bin/macos
./Luban \
    -t client \
    -c go-json \
    -d json \
    --conf /path/to/luban.conf \
    -x outputCodeDir=./output/code \
    -x outputDataDir=./output/data

# Windows
cd C:\path\to\xDooria-config\bin\windows
Luban.exe ^
    -t client ^
    -c go-json ^
    -d json ^
    --conf C:\path\to\luban.conf ^
    -x outputCodeDir=.\output\code ^
    -x outputDataDir=.\output\data
```

### 示例 2: 生成服务器配置（二进制格式）

```bash
./Luban \
    -t server \
    -c go-bin \
    -d bin \
    --conf /path/to/luban.conf \
    -x outputCodeDir=./server/gen \
    -x outputDataDir=./server/data
```

### 示例 3: 生成所有目标配置

```bash
./Luban \
    -t all \
    -c go-json \
    -d json \
    --conf /path/to/luban.conf \
    -x outputCodeDir=./gen \
    -x outputDataDir=./data
```

### 示例 4: 带本地化支持的生成

```bash
./Luban \
    -t client \
    -c go-json \
    -d json \
    --conf /path/to/luban.conf \
    -x outputCodeDir=./gen \
    -x outputDataDir=./data \
    -x l10n.provider=default \
    -x l10n.textFile.path=l10n/texts.json \
    -x l10n.textFile.keyFieldName=key
```

## 支持的游戏引擎和平台

### 游戏引擎
- Unity (标准、Editor、热更新)
- Unreal Engine
- Cocos2d / Cocos Creator
- Godot
- 微信小游戏

### 热更新方案
- hybridclr
- ILRuntime
- xLua / tLua / sLua
- Puerts

### 运行平台
- Windows (x64)
- macOS (ARM64 / Apple Silicon)
- Linux (x64)

## 工作流程

### 1. 配置定义阶段
- 在 Excel 或其他数据源中定义配置表
- 定义数据结构（bean）和枚举（enum）
- 编写 luban.conf 配置文件

### 2. 代码生成阶段
```bash
# 生成代码
./Luban -t client -c <language> --conf luban.conf -x outputCodeDir=<dir>
```

### 3. 数据生成阶段
```bash
# 生成数据
./Luban -t client -d <format> --conf luban.conf -x outputDataDir=<dir>
```

### 4. 集成使用阶段
- 将生成的代码集成到项目中
- 加载生成的数据文件
- 在游戏中使用配置数据

## 数据验证

Luban 支持多种数据验证功能，确保配置数据的正确性：

### 1. 引用完整性检查
验证配置项之间的引用关系是否正确

### 2. 路径验证
检查资源路径是否存在

### 3. 范围检查
验证数值是否在指定范围内

### 4. 自定义验证器
可以编写自定义验证逻辑

## 性能特点

- **生成速度快**: 高性能生成引擎
- **运行时高效**:
  - 二进制格式加载快
  - 无反射调用
  - 内存占用小
- **按需加载**: 支持 LazyLoad 模式
- **代码混淆兼容**: 兼容主流混淆工具

## 常见问题

### Q1: 如何选择代码生成目标？
A: 根据项目使用的编程语言和数据格式选择：
- 如果需要高性能，选择 `bin` 格式
- 如果需要可读性，选择 `json` 格式
- 如果需要跨语言，考虑 `protobuf` 或 `flatbuffers`

### Q2: 如何处理客户端和服务器的配置差异？
A: 使用 groups 和 targets 机制：
- 定义不同的 group（如 c=客户端，s=服务器）
- 在配置表中标记数据所属的 group
- 生成时指定对应的 target

### Q3: 支持热更新吗？
A: 是的，Luban 支持多种热更新方案：
- Unity: hybridclr, ILRuntime, xLua
- 其他引擎: 根据引擎特性选择方案

### Q4: 如何添加自定义类型？
A: 在 XML Schema 文件中定义：
```xml
<bean name="CustomType">
    <var name="field1" type="int"/>
    <var name="field2" type="string"/>
</bean>
```

### Q5: 数据文件太大怎么办？
A: 可以：
- 使用二进制格式（比 JSON 小很多）
- 启用数据压缩
- 使用 LazyLoad 按需加载
- 分表存储

## 版本信息

- **Luban 版本**: 4.5.0
- **最后更新**: 2025-12-19
- **支持平台**: Windows x64, macOS ARM64, Linux x64

## 相关链接

- [Luban 官方文档](https://www.datable.cn/)
- [Luban GitHub](https://github.com/focus-creative-games/luban)
- [Luban 示例项目](https://github.com/focus-creative-games/luban_examples)
- [快速上手指南](https://www.datable.cn/docs/beginner/quickstart)

## 技术支持

- QQ 群: 692890842 (Luban 开发交流群)
- Discord: https://discord.gg/dGY4zzGMJ4
- Email: luban@code-philosophy.com

## 许可证

Luban 采用 MIT 许可证

---

**注意**: 本文档基于 Luban 4.5.0 编写，具体使用时请参考官方文档获取最新信息。
