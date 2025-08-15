#!/bin/bash

# 自动从IPSW文件提取IPCC的完整脚本
# 使用方法: ./extract_ipcc_from_ipsw.sh <path_to_ipsw_file> [ipsw_tool_path]

set -e  # Exit on any error

# 检查是否提供了IPSW文件路径
if [ $# -eq 0 ]; then
    echo "错误：请提供IPSW文件路径"
    echo "使用方法: $0 <path_to_ipsw_file> [ipsw_tool_path]"
    echo "示例: $0 /path/to/iPhone_16_Pro_23A344_Restore.ipsw"
    echo "示例: $0 /path/to/iPhone_16_Pro_23A344_Restore.ipsw /usr/local/bin/ipsw"
    exit 1
fi

# 获取IPSW文件的绝对路径
IPSW_FILE=$(realpath "$1" 2>/dev/null || echo "$1")

# 设置ipsw工具路径，默认为/opt/homebrew/bin/ipsw
IPSW_TOOL_PATH="${2:-/opt/homebrew/bin/ipsw}"

# 检查IPSW文件是否存在
if [ ! -f "$IPSW_FILE" ]; then
    # 如果不是绝对路径，尝试在当前目录查找
    if [ ! -f "$(pwd)/$1" ]; then
        echo "错误：IPSW文件不存在: $1"
        echo "当前目录: $(pwd)"
        echo "请检查文件路径是否正确"
        exit 1
    else
        IPSW_FILE="$(pwd)/$1"
    fi
fi

echo "使用IPSW文件: $IPSW_FILE"
echo "使用ipsw工具路径: $IPSW_TOOL_PATH"

# 检查ipsw工具是否存在
if [ ! -f "$IPSW_TOOL_PATH" ]; then
    echo "错误：ipsw工具不存在于指定路径: $IPSW_TOOL_PATH"
    echo "请检查ipsw工具路径是否正确，或者安装ipsw工具"
    echo "安装命令: brew install ipsw"
    exit 1
fi

echo "=================================================="
echo "开始自动提取IPCC文件"
echo "IPSW文件: $IPSW_FILE"
echo "ipsw工具: $IPSW_TOOL_PATH"
echo "=================================================="

# 获取当前工作目录和文件信息
current_dir=$(pwd)
ipsw_basename=$(basename "$IPSW_FILE" .ipsw)
work_dir="$current_dir/${ipsw_basename}_ipcc_extraction"

# 创建工作目录
echo "创建工作目录: $work_dir"
mkdir -p "$work_dir"
cd "$work_dir"

# 步骤1：使用ipsw工具从IPSW文件中提取所有.dmg.aea文件
echo ""
echo "步骤1: 使用ipsw工具从IPSW文件中提取.dmg.aea文件..."
"$IPSW_TOOL_PATH" extract --dmg fs "$IPSW_FILE"

if [ $? -ne 0 ]; then
    echo "错误：从IPSW文件提取.dmg.aea文件失败"
    exit 1
fi

echo "✓ .dmg.aea文件提取完成"

# 清理Firmware文件夹
echo "  清理Firmware文件夹..."
find . -type d -name "Firmware" -exec rm -rf {} + 2>/dev/null && echo "  ✓ 已删除Firmware文件夹" || echo "  - 未找到Firmware文件夹"

# 步骤2：查找最大的.dmg.aea文件
echo ""
echo "步骤2: 查找最大的.dmg.aea文件..."

largest_dmg_aea=$(find . -name "*.dmg.aea" -type f -exec ls -la {} + | sort -k5 -nr | head -1 | awk '{print $NF}')

if [ -z "$largest_dmg_aea" ]; then
    echo "错误：未找到.dmg.aea文件"
    exit 1
fi

echo "✓ 找到最大的.dmg.aea文件: $largest_dmg_aea"

# 步骤3：使用ipsw工具转换最大的.dmg.aea为.dmg
echo ""
echo "步骤3: 使用ipsw工具转换.dmg.aea为.dmg..."
"$IPSW_TOOL_PATH" fw aea "$largest_dmg_aea"

if [ $? -ne 0 ]; then
    echo "错误：转换.dmg.aea文件失败"
    exit 1
fi

echo "✓ .dmg.aea文件转换完成"

# 步骤4：查找生成的.dmg文件
echo ""
echo "步骤4: 查找生成的.dmg文件..."
dmg_files=$(find . -name "*.dmg" -type f)

if [ -z "$dmg_files" ]; then
    echo "错误：未找到生成的.dmg文件"
    exit 1
fi

echo "✓ 找到.dmg文件，开始提取..."

# 定义要查找的bundle文件列表
bundle_files=(
    # 中国运营商
    "ChinaTelecom_USIM_cn.bundle"
    "ChinaTelecom_hk.bundle"
    "ChinaTelecom_USIM_mo.bundle"
    "CMCC_cn.bundle"
    "CMCC_hk.bundle"
    "CMCC_HKBN_hk.bundle"
    "CMCC_CMI.bundle"
    "Unicom_cn.bundle"
    "Unicom_hk.bundle"
    "CBN_cn.bundle"
    # 香港运营商
    "Hutchison_HKBN_hk.bundle"
    "Hutchison_hk.bundle"
    "SmarTone_hk.bundle"
    "CSL_hk.bundle"
)

# 获取运营商名称的函数
get_carrier_name() {
    local bundle_name="$1"
    case "$bundle_name" in
        ChinaTelecom_*)
            echo "中国电信"
            ;;
        CMCC_*)
            echo "中国移动"
            ;;
        Unicom_*)
            echo "中国联通"
            ;;
        CBN_*)
            echo "中国广电"
            ;;
        Hutchison_*)
            echo "香港和记"
            ;;
        SmarTone_*)
            echo "香港SmarTone"
            ;;
        CSL_*)
            echo "香港CSL"
            ;;
        *)
            echo "未知运营商"
            ;;
    esac
}

# 创建输出目录
output_dir="$work_dir/extracted_carrier_bundles"
mkdir -p "$output_dir"

# 创建运营商分类目录
classified_dir="$output_dir/classified_by_carrier"
mkdir -p "$classified_dir/中国电信"
mkdir -p "$classified_dir/中国移动"
mkdir -p "$classified_dir/中国联通"
mkdir -p "$classified_dir/中国广电"
mkdir -p "$classified_dir/香港和记"
mkdir -p "$classified_dir/香港SmarTone"
mkdir -p "$classified_dir/香港CSL"

# 创建IPCC输出目录
ipcc_dir="$output_dir/ipcc_files"
mkdir -p "$ipcc_dir"

echo ""
echo "步骤5: 从DMG文件提取Carrier Bundles..."

# 步骤5：处理所有DMG文件，提取iPhone目录
for dmg_file in $dmg_files; do
    echo "处理DMG文件: $dmg_file"
    
    # Create mount point
    mount_point="/tmp/dmg_mount_$$"
    mkdir -p "$mount_point"
    
    # Mount the dmg file
    hdiutil attach "$dmg_file" -mountpoint "$mount_point" -readonly -nobrowse -quiet
    
    if [ $? -eq 0 ]; then
        # Check if the target path exists
        carrier_bundles_path="$mount_point/System/Library/Carrier Bundles/iPhone"
        
        if [ -d "$carrier_bundles_path" ]; then
            echo "  ✓ 找到Carrier Bundles/iPhone目录"
            
            # 完整拷贝整个iPhone目录（如果已存在则合并）
            if [ ! -d "$output_dir/iPhone" ]; then
                cp -R "$carrier_bundles_path" "$output_dir/"
                echo "  ✓ 提取完整iPhone目录到: $output_dir/iPhone"
            else
                # 合并到已存在的目录
                cp -R "$carrier_bundles_path"/* "$output_dir/iPhone/" 2>/dev/null
                echo "  ✓ 合并bundle文件到: $output_dir/iPhone"
            fi
        else
            echo "  ✗ 未找到Carrier Bundles/iPhone目录"
        fi
        
        # Unmount the dmg
        hdiutil detach "$mount_point" -quiet
    else
        echo "  ✗ 挂载DMG文件失败"
    fi
    
    # Clean up mount point
    rmdir "$mount_point" 2>/dev/null
done

echo ""
echo "步骤6: 分类拷贝中国运营商bundle文件..."

# 步骤6：从完整的iPhone目录中分类拷贝指定的运营商bundle文件
extracted_iphone_dir="$output_dir/iPhone"
if [ -d "$extracted_iphone_dir" ]; then
    found_bundles=0
    for bundle_name in "${bundle_files[@]}"; do
        bundle_path="$extracted_iphone_dir/$bundle_name"
        
        if [ -d "$bundle_path" ]; then
            carrier=$(get_carrier_name "$bundle_name")
            classified_output_path="$classified_dir/$carrier/$bundle_name"
            
            # 拷贝bundle文件到分类目录
            cp -R "$bundle_path" "$classified_output_path"
            echo "  ✓ $bundle_name -> classified_by_carrier/$carrier/"
            ((found_bundles++))
        fi
    done
    
    if [ $found_bundles -eq 0 ]; then
        echo "  ⚠️ 未找到目标运营商bundle文件"
    else
        echo "  ✓ 共找到并分类 $found_bundles 个运营商bundle文件"
    fi
else
    echo "  ✗ 错误：iPhone目录不存在"
    exit 1
fi

echo ""
echo "步骤7: 创建IPCC文件..."

# 步骤7：为每个运营商的bundle文件创建IPCC文件
total_ipcc_created=0
for carrier in "中国电信" "中国移动" "中国联通" "中国广电" "香港和记" "香港SmarTone" "香港CSL"; do
    carrier_dir="$classified_dir/$carrier"
    
    if [ -d "$carrier_dir" ]; then
        # 检查该运营商目录下是否有bundle文件
        bundle_count=$(find "$carrier_dir" -maxdepth 1 -type d | grep -v "^$carrier_dir$" | wc -l)
        bundle_count=$(echo $bundle_count | tr -d ' ')
        
        if [ $bundle_count -gt 0 ]; then
            echo "  处理 $carrier ($bundle_count 个bundle文件)..."
            
            # 为该运营商的每个bundle创建单独的IPCC文件
            find "$carrier_dir" -maxdepth 1 -type d | grep -v "^$carrier_dir$" | while read bundle_dir; do
                bundle_name=$(basename "$bundle_dir")
                
                # 创建临时工作目录
                temp_work_dir="/tmp/ipcc_work_$$_$(echo $bundle_name | tr '.' '_' | tr '/' '_')"
                mkdir -p "$temp_work_dir/Payload"
                
                # 拷贝bundle到Payload目录
                cp -R "$bundle_dir" "$temp_work_dir/Payload/"
                
                # 创建ZIP文件
                cd "$temp_work_dir"
                
                # 处理数字目录名的情况（如45006, 45010）
                if [[ "$bundle_name" =~ ^[0-9]+$ ]]; then
                    # 数字目录，使用数字作为IPCC文件名
                    zip_file="$ipcc_dir/${bundle_name}.zip"
                    ipcc_name="${bundle_name}.ipcc"
                else
                    # .bundle目录，移除.bundle后缀
                    zip_file="$ipcc_dir/${bundle_name%%.bundle}.zip"
                    ipcc_name="${bundle_name%%.bundle}.ipcc"
                fi
                
                zip -r "$zip_file" Payload/ >/dev/null 2>&1
                
                if [ $? -eq 0 ]; then
                    # 将.zip改名为.ipcc
                    ipcc_file="$ipcc_dir/$ipcc_name"
                    mv "$zip_file" "$ipcc_file"
                    echo "    ✓ 已创建: $ipcc_name"
                    ((total_ipcc_created++))
                else
                    echo "    ✗ 压缩失败: $bundle_name"
                fi
                
                # 清理临时目录
                cd "$work_dir"
                rm -rf "$temp_work_dir"
            done
        fi
    fi
done

echo ""
echo "=================================================="
echo "提取完成！"
echo "=================================================="
echo ""
echo "文件提取结果："
echo "1. 工作目录: $work_dir"
echo "2. 完整的iPhone目录: $output_dir/iPhone"
echo "3. 按运营商分类的bundle文件: $classified_dir"
echo "4. IPCC文件: $ipcc_dir"

# 显示分类结果统计
echo ""
echo "运营商bundle分类统计："
for carrier in "中国电信" "中国移动" "中国联通" "中国广电" "香港和记" "香港SmarTone" "香港CSL"; do
    carrier_dir="$classified_dir/$carrier"
    if [ -d "$carrier_dir" ]; then
        count=$(find "$carrier_dir" -maxdepth 1 -type d | grep -v "^$carrier_dir$" | wc -l)
        count=$(echo $count | tr -d ' ')
        echo "  $carrier: $count 个bundle"
        if [ $count -gt 0 ]; then
            find "$carrier_dir" -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort | sed 's/^/    - /'
        fi
    fi
done

# 显示完整iPhone目录统计
if [ -d "$output_dir/iPhone" ]; then
    total_bundles=$(find "$output_dir/iPhone" -maxdepth 1 -name "*.bundle" -type d 2>/dev/null | wc -l)
    total_bundles=$(echo $total_bundles | tr -d ' ')
    echo ""
    echo "完整iPhone目录包含 $total_bundles 个bundle文件"
fi

# 显示生成的IPCC文件
if [ -d "$ipcc_dir" ]; then
    ipcc_count=$(find "$ipcc_dir" -name "*.ipcc" -type f 2>/dev/null | wc -l)
    ipcc_count=$(echo $ipcc_count | tr -d ' ')
    echo ""
    echo "生成的IPCC文件 ($ipcc_count 个)："
    if [ $ipcc_count -gt 0 ]; then
        find "$ipcc_dir" -name "*.ipcc" -type f -exec basename {} \; 2>/dev/null | sort | sed 's/^/  - /'
    fi
fi

echo ""
echo "=================================================="
echo "脚本执行完成！所有文件已保存在: $work_dir"
echo "==================================================" 