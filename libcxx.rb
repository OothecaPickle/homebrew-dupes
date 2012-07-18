require 'formula'

# Note, ultimatively this formula should be integrated into llvm
# (as an option) because of the built-in search path of clang:
# /usr/local/Cellar/llvm/HEAD/bin/../lib/c++/v1 if clang is at
# /usr/local/Cellar/llvm/HEAD/bin/clang.

class Libcxx < Formula
  homepage 'http://libcxx.llvm.org/'
  head 'http://llvm.org/svn/llvm-project/libcxx/trunk', :using => :svn

  keg_only :provided_by_osx, 
    "Be warned that Mac OS 10.7 will not boot without a valid copy of libc++.1.dylib in /usr/lib."

  def install
    # There are instructions on how to build on 10.6 here: http://libcxx.llvm.org/
    raise 'This formula is not (yet) ready for Mac OS X 10.6. Help us!' unless MacOS.lion?

    #  lib/buildit needs this to switch to OSX-build style
    ENV['TRIPLE'] = '-apple-'

    cd 'lib' do
      # Adapt install_name to match cellar location
      inreplace 'buildit', '-install_name /usr/lib/libc++.1.dylib \\', "-install_name #{prefix}/lib/libc++.1.dylib \\"
      # A missing space because builtit is not a Makefile but a shell script. Has been reported upstream (but no bugtracker)!
      # On Xcode-only systems you'll see "fatal error: 'string.h' file not found" if we don't inreplace here.
      inreplace 'buildit', 'EXTRA_FLAGS+="-isysroot ${SDKROOT}"', "EXTRA_FLAGS+=\" -isysroot ${SDKROOT} \""
      system './buildit'
      ln_s 'libc++.1.dylib', 'libc++.dylib'
      lib.install 'libc++.1.dylib', 'libc++.dylib'
    end

    mkdir_p include/'c++/v1'
    (include/'c++/v1').install Dir['include/*']

    mkdir prefix/'test'
    (prefix/'test').install Dir['test/*']
  end

  def test
    cd prefix/'test' do
      puts "Tests take a long time to run. Use -v to se progress and results."
      puts "According to http://libcxx.llvm.org, not all will pass (07/2012)."
      # Don't use homebrews build environment but mimic the user's settings:
      ENV.remove_cc_etc
      # The -Wl is given to the linker (ld) and so our libc++.dylip is 
      # picked up first. (`otool -L a.out` tells us the actual link.)
      ENV['OPTIONS']="-std=c++0x -stdlib=libc++ -isysroot #{MacOS.sdk_path} -Wl,-L/usr/local/Cellar/libcxx/HEAD/lib"
      ENV['TRIPLE'] = '-apple-'
      # Let clang search for system includes here first
      ENV['CPATH']=prefix/'include/c++/v1'
      system './testit'
    end
  end

  def caveats
    s = <<-EOS.undent

      To use with clang you can:
        export CPATH="#{prefix}/include/c++/v1"
        clang++ -stdlib=libc++ test.cpp -Wl,-L#{prefix}/lib
        clang++ -std=c++0x -stdlib=libc++ test.cpp -Wl,-L#{prefix}/lib

      Building libc++ with -fno-rtti is not supported.
      However linking against it with -fno-rtti is supported.

    EOS

    unless MacOS.clt_installed?
      s += <<-EOS.undent
        On Xcode-only systems (without the Command Line Tools) you will
        additionally need to pass to clang:
          -isysroot #{MacOS.sdk_path}

        EOS
    end
    return s
  end
end
