#!/bin/bash

set -e

echo "=> Running examples..."
# echo "=> Building turbo from source..."
# cd cli && CGO_ENABLED=0 go build ./cmd/turbo/... && cd ..;
export TURBO_BINARY_PATH=$(pwd)/cli/turbo
export TURBO_VERSION=$(head -n 1 $(pwd)/cli/version.txt)
export TURBO_TAG=$(cat $(pwd)/cli/version.txt | sed -n '2 p')
export folder=$1
export pkgManager=$2
echo "=> Binary path: TURBO_BINARY_PATH=$TURBO_BINARY_PATH"
echo "=> Local Turbo Version: TURBO_VERSION=$TURBO_VERSION"
echo "=> Moving our own eslint settings out of the way..."
echo "=> Actually running examples for real..."

if [ -f ".eslintrc.js" ]; then
  mv .eslintrc.js .eslintrc.js.bak
fi

function cleanup {
  rm -rf node_modules
  rm -rf apps/*/node_modules
  rm -rf apps/*/.next
  rm -rf apps/*/.turbo
  rm -rf packages/*/node_modules
  rm -rf packages/*/.next
  rm -rf packages/*/.turbo
  rm -rf *.log
  rm -rf yarn.lock
  rm -rf package-lock.json
  rm -rf pnpm-lock.yaml
}

function setup_git {
  echo "=> Setting up git..."
  rm -rf .git
  mkdir .git
  touch .git/config
  echo "[user]" >> .git/config
  echo "  name = GitHub Actions" >> .git/config
  echo "  email = actions@users.noreply.github.com" >> .git/config
  echo "" >> .git/config
  echo "[init]" >> .git/config
  echo "  defaultBranch = main" >> .git/config
  git init . -q
  git add .
  git commit -m "Initial commit"
}

function run_npm {
  cat package.json | jq '.packageManager = "npm@8.1.2"' | sponge package.json
  if [ "$TURBO_TAG" == "canary" ]; then
    cat package.json | jq '.devDependencies.turbo = "canary"' | sponge package.json
  fi

  echo "======================================================="
  echo "=> $folder: npm install"
  echo "======================================================="
  npm install --force

  echo "======================================================="
  echo "=> $folder: npm build lint"
  echo "======================================================="
  npm run build lint

  echo "======================================================="
  echo "=> $folder: npm build lint again"
  echo "======================================================="
  npm run build lint

  echo "======================================================="
  echo "=> $folder: npm SUCCESSFUL"
  echo "======================================================="
}

function run_pnpm {
  cat package.json | jq '.packageManager = "pnpm@6.26.1"' | sponge package.json
  if [ "$TURBO_TAG" == "canary" ]; then
    cat package.json | jq '.devDependencies.turbo = "canary"' | sponge package.json
  fi

  echo "======================================================="
  echo "=> $folder: pnpm install"
  echo "======================================================="
  pnpm install

  echo "======================================================="
  echo "=> $folder: pnpm build lint"
  echo "======================================================="
  pnpm run build lint

  echo "======================================================="
  echo "=> $folder: pnpm build lint again"
  echo "======================================================="
  pnpm run build lint

  echo "======================================================="
  echo "=> $folder: pnpm SUCCESSFUL"
  echo "======================================================="
}

function run_yarn {
  cat package.json | jq '.packageManager = "yarn@1.22.17"' | sponge package.json
  if [ "$TURBO_TAG" == "canary" ]; then
    cat package.json | jq '.devDependencies.turbo = "canary"' | sponge package.json
  fi

  echo "======================================================="
  echo "=> $folder: yarn install"
  echo "======================================================="
  yarn install

  echo "======================================================="
  echo "=> $folder: yarn build lint"
  echo "======================================================="
  yarn build lint

  echo "======================================================="
  echo "=> $folder: yarn build again"
  echo "======================================================="
  yarn build lint

  echo "======================================================="
  echo "=> $folder: yarn SUCCESSFUL"
  echo "======================================================="
}



if [ -f "examples/$folder/package.json" ]; then
  cd "examples/$folder"
  echo "======================================================="
  echo "=> checking $folder "
  echo "======================================================="
  cleanup
  setup_git
  if [ "$pkgManager" == "npm" ]; then
    run_npm
  elif [ "$pkgManager" == "pnpm" ]; then
    run_pnpm
  elif [ "$pkgManager" == "yarn" ]; then
    run_yarn
  fi

  cat package.json | jq 'del(.packageManager)' | sponge package.json
  if [ "$TURBO_TAG" == "canary" ]; then
    cat package.json | jq '.devDependencies.turbo = "latest"' | sponge package.json
  fi

  cleanup

  cd ../..
fi



if [ -f ".eslintrc.js.bak" ]; then
  mv .eslintrc.js.bak .eslintrc.js
fi

if [[ ! -z $(git status -s) ]];then
  echo "Detected changes"
  git status
  exit 1
fi
