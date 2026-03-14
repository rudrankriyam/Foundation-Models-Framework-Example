#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <tag> [output-file]" >&2
  exit 1
fi

tag="$1"
output_file="${2:-}"
repo="rudrankriyam/Foundation-Models-Framework-Example"
archive_url="https://github.com/${repo}/archive/refs/tags/${tag}.tar.gz"
temp_dir="$(mktemp -d)"
archive_path="${temp_dir}/${tag}.tar.gz"

cleanup() {
  rm -rf "${temp_dir}"
}

trap cleanup EXIT

curl -fsSL "${archive_url}" -o "${archive_path}"
tar -xzf "${archive_path}" -C "${temp_dir}"

archive_root="$(find "${temp_dir}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

if [[ -z "${archive_root}" || ! -f "${archive_root}/FoundationLabCLI/Package.swift" ]]; then
  echo "Tag ${tag} does not contain FoundationLabCLI/Package.swift." >&2
  echo "Create the release from a tag that includes the standalone CLI package." >&2
  exit 1
fi

sha256="$(shasum -a 256 "${archive_path}" | awk '{print $1}')"

formula="$(cat <<EOF
class Fm < Formula
  desc "Foundation Lab command-line interface"
  homepage "https://github.com/${repo}"
  url "${archive_url}"
  sha256 "${sha256}"
  license "MIT"

  def install
    cd "FoundationLabCLI" do
      system "swift", "build", "--configuration", "release", "--disable-sandbox"
      bin.install ".build/release/fm"
    end
  end

  test do
    output = shell_output("#{bin}/fm --help")
    assert_match "USAGE: fm", output
    assert_match "session", output
  end
end
EOF
)"

if [[ -n "${output_file}" ]]; then
  printf '%s\n' "${formula}" > "${output_file}"
else
  printf '%s\n' "${formula}"
fi
