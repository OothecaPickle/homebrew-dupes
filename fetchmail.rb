require 'formula'

class Fetchmail < Formula
  homepage 'http://www.fetchmail.info/'
  url 'http://downloads.sourceforge.net/project/fetchmail/branch_6.3/fetchmail-6.3.21.tar.xz'
  sha1 '4f1e5f2e1a616d4007da1de9c976c2c1fb5dcb81'

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make install"
  end
end
