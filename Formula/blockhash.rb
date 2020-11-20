class Blockhash < Formula
  desc "Perceptual image hash calculation tool"
  homepage "https://github.com/commonsmachinery/blockhash"
  url "https://github.com/commonsmachinery/blockhash/archive/v0.3.1.tar.gz"
  sha256 "56e8d2fecf2c7658c9f8b32bfb2d29fdd0d0535ddb3082e44b45a5da705aca86"
  license "MIT"
  revision 2
  head "https://github.com/commonsmachinery/blockhash.git"

  bottle do
    cellar :any
    sha256 "4cc1dfdfa365edd25d95d9188e9b45f03477a7c138ff3e539dce3ff839f7330c" => :big_sur
    sha256 "3db282d2098b5e52c197a62e977382fe5b192ce22ecb88020599534e07682475" => :catalina
    sha256 "45c611b516f5a0f53c75588ede65591eab5ec76bc65e05e5400ef232cb367a89" => :mojave
    sha256 "3b46ba7629e56dc9ef1b5a8a00fe7dc43b81d1f09b8f9efcb8bff49ecf16676e" => :high_sierra
  end

  depends_on "pkg-config" => :build
  depends_on "python@3.9" => :build
  depends_on "imagemagick"

  resource "testdata" do
    url "https://raw.githubusercontent.com/commonsmachinery/blockhash/ce08b465b658c4e886d49ec33361cee767f86db6/testdata/clipper_ship.jpg"
    sha256 "a9f6858876adadc83c8551b664632a9cf669c2aea4fec0c09d81171cc3b8a97f"
  end

  # Add python3 support
  #
  # This patch mimics changes from https://github.com/commonsmachinery/blockhash/commit/07268aeaeef880e0749bd22331ee424ddbc156e0
  # but can't be applied as a formula patch since it contains GIT binary patch
  #
  # See https://github.com/commonsmachinery/blockhash/issues/28#issuecomment-417726356
  #
  # Remove this in next release
  resource "waf-2.0.10" do
    url "https://raw.githubusercontent.com/commonsmachinery/blockhash/07268aeaeef880e0749bd22331ee424ddbc156e0/waf"
    sha256 "0a855861c793f9b7e46b0077b791e13515e00742e1493e1818f9b369133b83d7"
  end

  def install
    resource("waf-2.0.10").stage buildpath
    chmod 0755, "waf"

    ENV.prepend_path "PATH", Formula["python@3.9"].opt_bin

    system "./waf", "configure", "--prefix=#{prefix}"
    # pkg-config adds -fopenmp flag during configuring
    # This fails the build on system clang, and OpenMP is not used in blockhash
    inreplace "build/c4che/_cache.py", "-fopenmp", ""
    system "./waf"
    system "./waf", "install"
  end

  test do
    resource("testdata").stage testpath
    hash = "00007ff07ff07fe07fe67ff07560600077fe701e7f5e000079fd40410001ffff"
    result = shell_output("#{bin}/blockhash #{testpath}/clipper_ship.jpg")
    assert_match hash, result
  end
end
