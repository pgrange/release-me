#!/usr/bin/env bash
set -e

release() {
  # Publish a `npm` tag
  if [[ "$NPM_TOKEN" != "" ]]; then
    log "Publishing npm tag..."
    log_verbose "npm tag: $RELEASE_TAG_NAME and version: $RELEASE_VERSION!"

    if ! $IS_DRY_RUN; then
      rm -rf .npmrc
      echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" >>.npmrc

      npm publish --tag "$RELEASE_VERSION"

      echo "Published [$RELEASE_TAG_NAME]!"
      rm -rf .npmrc
    else
      log "Skipped npm tag [$RELEASE_TAG_NAME] in DRY-RUN mode."
    fi
  else
    echo "
npm Token is not found
Please export npm Token so this plugin can be used
"
  fi
}
