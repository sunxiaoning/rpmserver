set -o nounset
set -o errexit
set -o pipefail

PKG_PATH="hack/pack"

PKG_VERSION="1.0.2"
PKG_NAME="rpmserver-${PKG_VERSION}.tar.gz"

REL_TAG="v${PKG_VERSION}"
REL_TITLE="Release v${PKG_VERSION}"
REL_NOTES="
## Improvements
- Fix the \`RENDER_SH_FILE\` variable.
"
