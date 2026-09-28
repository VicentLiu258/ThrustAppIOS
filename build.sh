#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# iOS 自动化打包脚本
# 命名规则: APP名字+版本号+日期 (例如: ThrustWealth_1.0.0_20260928.ipa)
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR}"

PROJECT_NAME="ThrustWealth.xcodeproj"
SCHEME="ThrustWealth"
CONFIGURATION="Release"
OUTPUT_DIR="${PROJECT_DIR}/build"
DATE="$(date +%Y%m%d)"

echo "==> 正在读取工程配置..."

# 从 Xcode 获取工程配置参数
BUILD_SETTINGS=$(xcodebuild -project "${PROJECT_NAME}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" -showBuildSettings 2>/dev/null)

APP_NAME=$(echo "${BUILD_SETTINGS}" | awk -F ' = ' '/^[[:space:]]*PRODUCT_NAME = /{print $2}' | tr -d '[:space:]')
if [ -z "${APP_NAME}" ]; then
    APP_NAME="ThrustWealth"
fi

VERSION=$(echo "${BUILD_SETTINGS}" | awk -F ' = ' '/^[[:space:]]*MARKETING_VERSION = /{print $2}' | tr -d '[:space:]')
if [ -z "${VERSION}" ]; then
    VERSION="1.0.0"
fi

BUNDLE_ID=$(echo "${BUILD_SETTINGS}" | awk -F ' = ' '/^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = /{print $2}' | tr -d '[:space:]')
if [ -z "${BUNDLE_ID}" ]; then
    BUNDLE_ID="com.thrustwealth.tools"
fi

# 文件命名格式: APP名字+版本号+日期 (推荐下划线分隔)
BASE_NAME="${APP_NAME}_${VERSION}_${DATE}"
ARCHIVE_PATH="${OUTPUT_DIR}/${BASE_NAME}.xcarchive"
IPA_PATH="${OUTPUT_DIR}/${BASE_NAME}.ipa"

mkdir -p "${OUTPUT_DIR}"

echo "===================================================="
echo "  包名 (Bundle ID):      ${BUNDLE_ID}"
echo "  APP 名称 (App Name):   ${APP_NAME}"
echo "  版本号 (Version):      ${VERSION}"
echo "  打包日期 (Date):       ${DATE}"
echo "  输出基础名:            ${BASE_NAME}"
echo "  归档路径 (.xcarchive): ${ARCHIVE_PATH}"
echo "  IPA 路径 (.ipa):        ${IPA_PATH}"
echo "===================================================="

# 1. 验证 Bundle ID
EXPECTED_BUNDLE_ID="com.thrustwealth.tools"
if [ "${BUNDLE_ID}" != "${EXPECTED_BUNDLE_ID}" ]; then
    echo "⚠️ 警告: 当前工程 Bundle ID (${BUNDLE_ID}) 与预期 (${EXPECTED_BUNDLE_ID}) 不一致，将在构建时使用 ${EXPECTED_BUNDLE_ID}"
    BUNDLE_ID_FLAG="PRODUCT_BUNDLE_IDENTIFIER=${EXPECTED_BUNDLE_ID}"
else
    BUNDLE_ID_FLAG=""
fi

# 2. 清理旧归档和 IPA（如果同名存在）
rm -rf "${ARCHIVE_PATH}" "${IPA_PATH}"

echo "==> [1/2] 开始编译并生成 Archive..."

xcodebuild -project "${PROJECT_NAME}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination 'generic/platform=iOS' \
  -archivePath "${ARCHIVE_PATH}" \
  archive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ${BUNDLE_ID_FLAG} \
  -quiet

if [ ! -d "${ARCHIVE_PATH}" ]; then
    echo "❌ 错误: Archive 构建失败，未生成 ${ARCHIVE_PATH}"
    exit 1
fi

echo "✅ Archive 归档成功: ${ARCHIVE_PATH}"

# 3. 提取 .app 并打包生成 .ipa
APP_BUNDLE_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"

if [ ! -d "${APP_BUNDLE_PATH}" ]; then
    APP_BUNDLE_PATH=$(find "${ARCHIVE_PATH}/Products/Applications" -maxdepth 1 -name "*.app" | head -n 1)
fi

if [ -z "${APP_BUNDLE_PATH}" ] || [ ! -d "${APP_BUNDLE_PATH}" ]; then
    echo "❌ 错误: 在 Archive 中未找到 .app 文件"
    exit 1
fi

echo "==> [2/2] 正在提取 Payload 并压缩生成 IPA..."

TEMP_PAYLOAD_DIR=$(mktemp -d /tmp/ipa_payload_XXXXXX)
mkdir -p "${TEMP_PAYLOAD_DIR}/Payload"
cp -R "${APP_BUNDLE_PATH}" "${TEMP_PAYLOAD_DIR}/Payload/"

(
    cd "${TEMP_PAYLOAD_DIR}"
    zip -r -q -y "${IPA_PATH}" Payload
)
rm -rf "${TEMP_PAYLOAD_DIR}"

if [ ! -f "${IPA_PATH}" ]; then
    echo "❌ 错误: IPA 生成失败"
    exit 1
fi

# 创建纯连接名称的软链接 (例如 ThrustWealth1.0.020260928.ipa) 便于匹配不同命名偏好
NO_UNDERSCORE_NAME="${APP_NAME}${VERSION}${DATE}"
(
    cd "${OUTPUT_DIR}"
    ln -sf "${BASE_NAME}.ipa" "${NO_UNDERSCORE_NAME}.ipa"
    ln -sf "${BASE_NAME}.ipa" "${APP_NAME}.ipa"
)

echo "✅ IPA 打包成功!"
echo "===================================================="
echo "📦 打包产物生成完成:"
ls -lh "${ARCHIVE_PATH}"
ls -lh "${IPA_PATH}"
echo "----------------------------------------------------"
echo "产物路径:"
echo "  • IPA 文件:     ${IPA_PATH}"
echo "  • xcarchive:   ${ARCHIVE_PATH}"
echo "===================================================="
