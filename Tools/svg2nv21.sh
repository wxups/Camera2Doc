#!/bin/bash

# ==========================================
# 使用示例
# script.sh input width align background
# inpug: 需要转换的 svg 文件
# width: 转换后的目标宽度
# align: 宽高对齐位数
# background: 背景色名字
# ==========================================
# 完整示例
# svg2nv21.sh logo.svg 1300 2 black
# ==========================================
# 依赖项
# imagemagick, ffmpeg
# ==========================================


# ==========================================
# 配置与输入检查
# ==========================================
if [ $# -lt 1 ]; then
    echo "用法: $0 <input_svg_path> [output_width] [align_bit] [background_color]"
    echo "示例: $0 logo.svg 1300 2 black"
    exit 1
fi

# 检查工具：使用 ImageMagick
if command -v convert &> /dev/null; then
    echo "使用 ImageMagick。"
else
    echo "错误: 请安装 ImageMagick。"
    exit 1
fi

# 1. 获取输入参数
inputFile="$1"
outputWidth="${2:-1300}"      # 默认宽 1300
alignBit="${3:-2}"            # 默认对齐位数 2
bg="${4:-black}"              # 默认背景 black

# 检查文件是否存在
if [ ! -f "$inputFile" ]; then
    echo "错误: 文件 '$inputFile' 不存在。"
    exit 1
fi

# 获取输入文件的目录和文件名
inputDir=$(dirname "$inputFile")
inputBase=$(basename "$inputFile")
inputName="${inputBase%.*}"

echo "正在处理: $inputFile"
echo "目标宽度: $outputWidth, 对齐: $alignBit, 背景: $bg"

# ==========================================
# 2. 获取“实际图像尺寸” 
# ==========================================

# 创建一个临时文件用于初步裁剪/分析
tempTrimmed="${inputDir}/${inputName}_trimmed_temp.png"

# 使用 ImageMagick 获取 SVG 的原始宽高 (Geometry 格式为 "宽x高+X+Y")
# 注意：这里不需要渲染，只是读取元数据
geometry=$(identify -format "%wx%h" "$inputFile" 2>/dev/null)

if [ -z "$geometry" ]; then
    echo "错误: 无法获取 SVG 尺寸，请确保安装了 ImageMagick 且 SVG 格式正确。"
    exit 1
fi

# 解析原始宽高
origWidth=$(echo $geometry | cut -d'x' -f1)
origHeight=$(echo $geometry | cut -d'x' -f2)
echo "原始尺寸: ${origWidth}x${origHeight}"

# 1. 先导出一个临时 PNG，使用 --export-area-drawing 自动裁剪画板空白
convert -background "$bg" \
    -alpha remove \
    -alpha off \
    -trim \
    -colors 2 \
    +dither \
    -depth 8 \
    "$inputFile" \
    "$tempTrimmed" \
    2>/dev/null

# 2. 获取这个裁剪后 PNG 的尺寸
geometry=$(identify -format "%wx%h" "$tempTrimmed" 2>/dev/null)
origWidth=$(echo $geometry | cut -d'x' -f1)
origHeight=$(echo $geometry | cut -d'x' -f2)

# 清理临时分析文件
rm -f "$tempTrimmed"

if [ -z "$origWidth" ] || [ -z "$origHeight" ]; then
    echo "错误: 无法获取图像尺寸。"
    exit 1
fi

echo "内容尺寸: ${origWidth}x${origHeight}"


# 计算缩放比例
# 使用 bc 进行浮点运算
scaleRatio=$(echo "scale=10; $outputWidth / $origWidth" | bc)

# 计算理论高度
theoreticalHeight=$(echo "scale=0; $origHeight * $scaleRatio / 1" | bc)

# --- 对齐逻辑 ---
# 我们需要找到一个高度 H，使得 H % alignBit == 0
# 策略：先向下取整到最近的 alignBit 倍数，如果误差过大则向上取整
# 或者简单点：直接取最接近的倍数

# 计算向下取整的倍数
h_floor=$(echo "$theoreticalHeight / $alignBit" | bc)
h_floor_val=$((h_floor * alignBit))

# 计算向上取整的倍数
h_ceil_val=$(((h_floor + 1) * alignBit))

# 比较哪个更接近
diff_floor=$(echo "$theoreticalHeight - $h_floor_val" | bc)
diff_ceil=$(echo "$h_ceil_val - $theoreticalHeight" | bc)

# 简单的绝对值比较逻辑 (bc 不支持 abs，用 if 判断)
targetHeight=0
if (( $(echo "$diff_floor < $diff_ceil" | bc -l) )); then
    targetHeight=$h_floor_val
else
    targetHeight=$h_ceil_val
fi

# 确保目标宽度也是对齐的 (虽然用户指定了 outputWidth，但为了严谨)
targetWidth=$outputWidth
if [ $((targetWidth % alignBit)) -ne 0 ]; then
    # 如果用户指定的宽度本身不对齐，这里强制修正或警告
    # 这里选择修正为最接近的倍数
    targetWidth=$(( (targetWidth / alignBit) * alignBit ))
    echo "提示: 输入宽度已修正为 $targetWidth 以满足对齐要求。"
fi

echo "目标尺寸: ${targetWidth}x${targetHeight}"

# ==========================================
# 3. 执行转换
# ==========================================

# 3.1 定义临时 PNG 路径
tempPng="${inputDir}/${inputName}_temp.png"
# 3.2 定义最终输出路径
finalOutput="${inputDir}/logo_${targetWidth}x${targetHeight}_i420.yuv"

echo "步骤 1/2: 使用 ImageMagick 转换 SVG 为 PNG..."
# 使用 convert 进行光栅化
# -background 设置背景色 (处理透明度)
# -resize 设置尺寸
# -alpha remove -alpha off 确保移除透明通道，转为 RGB
convert -background "$bg" \
    -alpha remove \
    -alpha off \
    -trim \
    -colors 2 \
    +dither \
    -depth 8 \
    -resize "${targetWidth}x${targetHeight}!" \
    "$inputFile" \
    "$tempPng"

if [ $? -ne 0 ]; then
    echo "错误: ImageMagick 转换失败。"
    exit 1
fi

echo "步骤 2/2: 使用 FFmpeg 转换 PNG 为 NV21..."
# 使用 FFmpeg 转换
# -pix_fmt nv21 指定输出格式
# -f rawvideo 强制输出为原始视频流
ffmpeg -y -i "$tempPng" \
    -pix_fmt nv21 \
    -f rawvideo \
    "$finalOutput" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "成功! 文件已保存至: $finalOutput"
else
    echo "错误: FFmpeg 转换失败。"
    rm -f "$tempPng"
    exit 1
fi

# ==========================================
# 4. NV21 二值化处理（纯Shell实现，无第三方依赖）
# ==========================================

echo "步骤 3/3: 对NV21进行二值化处理..."

# 计算NV21数据大小
y_size=$((targetWidth * targetHeight))
uv_size=$((y_size / 2))
total_size=$((y_size + uv_size))

# 检查文件大小
file_size=$(wc -c < "$finalOutput")
if [ "$file_size" -ne "$total_size" ]; then
    echo "错误: 文件大小不匹配，期望 $total_size，实际 $file_size"
    exit 1
fi

# 创建临时文件用于存储二值化后的数据
tempYuv="${inputDir}/logo_${targetWidth}x${targetHeight}_i420_binarized.yuv"

# 使用dd读取NV21数据，逐字节处理
# Y平面二值化：>=128 -> 0xFF, <128 -> 0x00
# UV平面：全部设置为 0x80

# 使用perl进行二值化处理（perl是Linux标准组件）
# Y平面二值化：>=128 -> 0xFF, <128 -> 0x00
# UV平面：全部设置为 0x80

perl -e '
    use strict;
    use warnings;
    
    my ($input, $width, $height, $output) = @ARGV;
    my $y_size = $width * $height;
    my $uv_size = $y_size / 2;
    my $total_size = $y_size + $uv_size;
    
    # 读取文件
    open(my $fh, "<:raw", $input) or die "无法打开文件: $!";
    my $data;
    read($fh, $data, $total_size);
    close($fh);
    
    if (length($data) != $total_size) {
        die "数据大小不匹配: 期望 $total_size, 实际 " . length($data);
    }
    
    # Y平面二值化
    for (my $i = 0; $i < $y_size; $i++) {
        my $byte = ord(substr($data, $i, 1));
        substr($data, $i, 1) = ($byte >= 128) ? "\xff" : "\x00";
    }
    
    # UV平面设置为0x80
    for (my $i = $y_size; $i < $total_size; $i++) {
        substr($data, $i, 1) = "\x80";
    }
    
    # 写入文件
    open($fh, ">:raw", $output) or die "无法写入文件: $!";
    print $fh $data;
    close($fh);
' "$finalOutput" "$targetWidth" "$targetHeight" "$tempYuv" || {
    echo "错误: 二值化处理失败。"
    rm -f "$tempYuv"
    exit 1
}

# 检查输出文件大小
binarized_size=$(wc -c < "$tempYuv")
if [ "$binarized_size" -ne "$total_size" ]; then
    echo "错误: 二值化后文件大小不匹配，期望 $total_size，实际 $binarized_size"
    rm -f "$tempYuv"
    exit 1
fi

# 替换原文件
mv "$tempYuv" "$finalOutput"

echo "二值化处理完成！"

echo "成功! 文件已保存至: $finalOutput"

# 清理临时文件
rm -f "$tempPng"
