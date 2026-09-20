#!/usr/bin/env bash
# 一键推送到 GitHub 并开启 GitHub Pages
#
# 前置：在 https://github.com/new 建一个空的 public 仓库（不要勾选 README / .gitignore）
#
# 用法：
#   ./push.sh <你的GitHub用户名> [仓库名]
#   ./push.sh octocat 每日预算挑战·任务签到表
#
# 认证：脚本会优先用已登录的 gh；没登录会走 git 凭据（HTTPS 会弹窗/用 credential helper）

set -e

USER="$1"
REPO="${2:-每日预算挑战·任务签到表}"

if [ -z "$USER" ]; then
  echo "用法: ./push.sh <你的GitHub用户名> [仓库名]"
  exit 1
fi

# 中文仓库名做 URL 编码
ENC_REPO=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$REPO")
REMOTE="https://github.com/${USER}/${ENC_REPO}.git"

cd "$(dirname "$0")"

if [ ! -d .git ]; then
  git init -q
fi

git add -A
git -c user.name="WorkBuddy" -c user.email="workbuddy@users.noreply.github.com" \
  commit -q -m "Add 每日预算挑战·任务签到表 page" || echo "（没有新的改动可提交，继续推送）"

git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"

echo "推送到 $REMOTE ..."
git push -u origin main

# 开启 GitHub Pages（main 分支根目录）
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh api -X POST "repos/${USER}/${REPO}/pages" \
    -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
    && echo "GitHub Pages 已开启" \
    || echo "Pages 可能已开启，或需要你在仓库 Settings → Pages 里手动选择 main 分支根目录"
else
  echo "未检测到 gh 登录，请手动开启：仓库 Settings → Pages → Source 选 main / (root)"
fi

echo
echo "部署完成后访问（约 1 分钟生效）："
python3 -c "import urllib.parse,sys;print('https://'+sys.argv[1]+'.github.io/'+urllib.parse.quote(sys.argv[2])+'/')" "$USER" "$REPO"
