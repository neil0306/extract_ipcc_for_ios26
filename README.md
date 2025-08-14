# IPCC 提取工具

这是一个从 iOS IPSW 固件文件中自动提取 IPCC (iPhone Carrier Configuration) 文件的工具。该工具可以自动从 IPSW 文件中提取中国运营商的载波配置文件。

## 功能特性

- 🔄 自动从 IPSW 文件中提取所有载波配置 bundle 文件
- 📱 专门针对中国运营商配置文件进行分类提取
- 📦 自动将 bundle 文件转换为 IPCC 格式
- 🗂️ 按运营商分类整理输出文件
- ✅ 支持完整的载波配置文件备份

## 支持的运营商

- **中国电信** (China Telecom)
- **中国移动** (China Mobile)
- **中国联通** (China Unicom) 
- **中国广电** (China Broadcasting Network)
- **香港和记** (Hutchison HK)

## 系统要求

### 操作系统
- macOS (推荐)
- Linux (需手动安装依赖)

### 必需工具

1. **ipsw 工具**
   ```bash
   # macOS 用户通过 Homebrew 安装
   brew install ipsw
   
   # 或手动从 GitHub 下载
   # https://github.com/blacktop/ipsw
   ```

2. **系统工具**
   - `hdiutil` (macOS 自带)
   - `zip` (系统自带)
   - `unzip` (系统自带)
   - `find` (系统自带)

## 安装

1. 克隆或下载此项目：
   ```bash
   git clone <repository-url>
   cd extract_ipcc_for_ios26
   ```

2. 给脚本添加执行权限：
   ```bash
   chmod +x extract_ipcc_from_ipsw.sh
   ```

3. 确保已安装 ipsw 工具：
   ```bash
   brew install ipsw
   ```

## 使用方法

### 下载固件包 (ipsw 文件)
使用 ipsw 下载的命令格式为：
```shell
ipsw download appledb --os iOS --device <设备代码> --beta --latest     # 最新beta版本固件

ipsw download appledb --os iOS --device <设备代码> --latest            # 最新的稳定版固件

ipsw download appledb --os iOS --device <设备代码> --version iOS版本号  # 下载指定的稳定版固件
```

举例：
```shell
# iPhone 15 pro (固件代码 iPhone16,1)
ipsw download appledb --os iOS --device iPhone16,1 --beta --latest

ipsw download appledb --os iOS --device iPhone16,1 --latest

ipsw download appledb --os iOS --device iPhone16,1 --version 18.2
```


### 基本用法

```bash
./extract_ipcc_from_ipsw.sh <IPSW文件路径>
```

### 示例

```bash
# 使用绝对路径
./extract_ipcc_from_ipsw.sh /path/to/iPhone_16_Pro_23A344_Restore.ipsw

# 使用相对路径
./extract_ipcc_from_ipsw.sh ./iPhone_16_Pro_23A344_Restore.ipsw
```

## 输出结构

脚本运行完成后，会在当前目录下创建一个工作目录，包含以下内容：

```
<IPSW文件名>_ipcc_extraction/
├── extracted_carrier_bundles/
│   ├── iPhone/                          # 完整的载波配置目录
│   │   ├── ChinaTelecom_USIM_cn.bundle
│   │   ├── CMCC_cn.bundle
│   │   ├── Unicom_cn.bundle
│   │   └── ... (所有载波配置文件)
│   ├── classified_by_carrier/           # 按运营商分类
│   │   ├── 中国电信/
│   │   ├── 中国移动/
│   │   ├── 中国联通/
│   │   ├── 中国广电/
│   │   └── 香港和记/
│   └── ipcc_files/                      # 生成的 IPCC 文件
│       ├── ChinaTelecom_USIM_cn.ipcc
│       ├── CMCC_cn.ipcc
│       ├── Unicom_cn.ipcc
│       └── ...
└── [临时文件和中间文件]
```

## 执行流程

1. **验证输入** - 检查 IPSW 文件是否存在
2. **工具检查** - 自动检查并安装 ipsw 工具
3. **提取 DMG** - 从 IPSW 文件中提取 .dmg.aea 文件
4. **转换格式** - 将 .dmg.aea 转换为 .dmg 格式
5. **挂载提取** - 挂载 DMG 文件并提取载波配置
6. **分类整理** - 按运营商分类整理文件
7. **生成 IPCC** - 将 bundle 文件打包为 IPCC 格式

## 故障排除

### 常见问题

1. **ipsw 工具未安装**
   ```bash
   brew install ipsw
   ```

2. **权限问题**
   ```bash
   chmod +x extract_ipcc_from_ipsw.sh
   ```

3. **文件路径错误**
   - 确保 IPSW 文件存在
   - 使用绝对路径或正确的相对路径

4. **磁盘空间不足**
   - 确保有足够的磁盘空间（通常需要 IPSW 文件大小的 2-3 倍）

### 错误日志

脚本会在执行过程中显示详细的进度信息和错误消息。如果遇到问题，请查看控制台输出获取具体错误信息。

## 注意事项

- 📄 本工具仅用于教育和研究目的
- 💾 确保有足够的磁盘空间存储提取的文件
- ⏱️ 提取过程可能需要几分钟到十几分钟，取决于 IPSW 文件大小
- 🔒 某些 IPSW 文件可能需要特殊处理或无法提取

## 许可证

请确保您有权使用相关的 IPSW 文件和载波配置文件。本工具仅供学习和研究使用。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工具。

## 支持

如果您遇到问题或有建议，请创建 Issue 进行反馈。
