#!/usr/bin/env bash
set -eu

ROOT_DIR="$(realpath ../../)"
REPO_FOLDER=$(mktemp -d)

setup_suite() {
  cd "$REPO_FOLDER"
  git init --initial-branch=master

  echo 'from setuptools import setup, find_packages


setup(
    name="foo",
    version="1.0",
    packages=find_packages(),
)
' >>"$REPO_FOLDER/setup.py"

  export GIT_DIR="$REPO_FOLDER/.git"
  export GIT_CONFIG="$REPO_FOLDER/.gitconfig"
  export GIT_WORK_TREE="$REPO_FOLDER"

  if [[ -n "${GIT_USERNAME-}" && -n "${GIT_EMAIL-}" ]]; then
    export GIT_COMMITTER_NAME="$GIT_USERNAME"
    export GIT_COMMITTER_EMAIL="$GIT_EMAIL"
    export GIT_AUTHOR_NAME="$GIT_USERNAME"
    export GIT_AUTHOR_EMAIL="$GIT_EMAIL"

    git config user.email "$GIT_EMAIL"
    git config user.name "$GIT_USERNAME"
  fi
}

teardown_suite() {
  rm -rf "$GIT_WORK_TREE"
  unset REPO_FOLDER
  unset GIT_DIR
  unset GIT_CONFIG
  unset GIT_WORK_TREE

  unset GIT_COMMITTER_NAME
  unset GIT_COMMITTER_EMAIL
  unset GIT_AUTHOR_NAME
  unset GIT_AUTHOR_EMAIL
}

#####################################
## This tests of specification at  ##
## https://conventionalcommits.org ##
#####################################

test_commit_0_1_initial_message() {
  git commit -m "fix(workspace1): initial commit" --allow-empty --no-gpg-sign

  GPG_NO_SIGN=1 bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace
  assert_equals "workspace1-v0.0.1" "$(git tag -l | tail -1)"
}
test_commit_0_2_initial_message_no_change() {

  assert_matches "Your project has no new commits" "$(GPG_NO_SIGN=1 bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace)"
}
test_commit_0_3_skip_change() {
  git commit -m "chore(workspace1): chore commit" --allow-empty --no-gpg-sign

  GPG_NO_SIGN=1 bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --dry-run --pre-release
  assert_equals "workspace1-v0.0.1" "$(git tag -l | tail -1)"

  GPG_NO_SIGN=1 bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace
  assert_equals "workspace1-v0.0.1" "$(git tag -l | tail -1)"
}
test_commit_1_feat_breaking_major_message() {
  git commit -m "feat(workspace1): allow provided config object to extend other configs" -m "BREAKING CHANGE: \`extends\` key in config file is now used for extending other config files" --allow-empty --no-gpg-sign

  GPG_NO_SIGN=1 bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet --stable
  assert_equals "workspace1-v1.0.0" "$(git tag -l | tail -1)"
}
test_commit_2_feat_mark_major_message() {
  git commit -m "feat!: send an email to the customer when a product is shipped" --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet --dry-run
  assert_equals "workspace1-v1.0.0" "$(git tag -l | tail -1)"

  assert_matches "workspace1-v1.0.0" "$(bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --verbose --dry-run)"

  GPG_NO_SIGN=1 bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v1.0.0" "$(git tag -l | tail -1)"
}
test_commit_3_feat_mark_scope_major_message() {
  git commit -m "feat(workspace1)!: send an email to the customer when a product is shipped" --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet --dry-run
  assert_equals "workspace1-v1.0.0" "$(git tag -l | tail -1)"

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v2.0.0" "$(git tag -l | tail -1)"
}
test_commit_4_feat_mark_breaking_scope_major_message() {
  git commit -m "chore(workspace1)!: drop support for Node 6" -m "BREAKING CHANGE: use JavaScript features not available in Node 6." --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet --dry-run
  assert_equals "workspace1-v2.0.0" "$(git tag -l | tail -1)"

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v3.0.0" "$(git tag -l | tail -1)"
}
test_commit_5_docs_root_no_update_message() {
  git commit -m "docs: correct spelling of CHANGELOG" --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --verbose --dry-run
  assert_equals "workspace1-v3.0.0" "$(git tag -l | tail -1)"

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v3.0.0" "$(git tag -l | tail -1)"
}
test_commit_5_docs_workspace_no_update_message() {
  git commit -m "docs(workspace1): correct spelling of CHANGELOG" --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --verbose --dry-run
  assert_equals "workspace1-v3.0.0" "$(git tag -l | tail -1)"

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v3.0.0" "$(git tag -l | tail -1)"
}
test_commit_6_feat_scope_message() {
  git commit -m "feat(workspace1): add Polish language" --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet --dry-run
  assert_equals "workspace1-v3.0.0" "$(git tag -l | tail -1)"

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v3.1.0" "$(git tag -l | tail -1)"
}
test_commit_7_fix_multi_message() {
  git commit -m "fix(workspace1): prevent racing of requests" -m "Introduce a request id and a reference to latest request. Dismiss incoming responses other than from latest request." -m "Remove timeouts which were used to mitigate the racing issue but are obsolete now" -m "Reviewed-by: Z" -m "Refs: #123" --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet --dry-run
  assert_equals "workspace1-v3.1.0" "$(git tag -l | tail -1)"

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v3.1.1" "$(git tag -l | tail -1)"
}
test_commit_8_revert_message() {
  git commit -m "revert(workspace1): let us never again speak of the noodle incident" -m "Refs: 676104e, a215868" --allow-empty --no-gpg-sign

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet --dry-run
  assert_equals "workspace1-v3.1.1" "$(git tag -l | tail -1)"

  bash "$ROOT_DIR/release.sh" --plugins=git --preset=workspace --workspace --quiet
  assert_equals "workspace1-v3.1.2" "$(git tag -l | tail -1)"
}
