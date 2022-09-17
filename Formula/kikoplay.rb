class Kikoplay < Formula
  desc "NOT ONLY A Full-Featured Danmu Player"
  homepage "https://github.com/KikoPlayProject/KikoPlay"
  license "GPL-3.0"

  stable do
    url "https://github.com/KikoPlayProject/KikoPlay/archive/0.8.2.tar.gz"
    sha256 "dc42b74eb616286910e028ceaa6753db803d553fc37347756df68f882d1f3d6a"

    resource "script" do
      url "https://github.com/KikoPlayProject/KikoPlayScript.git",
          revision: "438248101f04b9fd0af29313c78b001a110cf219"
    end
  end

  head do
    url "https://github.com/KikoPlayProject/KikoPlay.git"

    resource "script" do
      url "https://github.com/KikoPlayProject/KikoPlayScript.git"
    end
  end

  bottle do
    rebuild 1
    root_url "https://github.com/KikoPlayProject/Homebrew-KikoPlay/releases/download/kikoplay-v0.8.2"
    sha256 cellar: :any, high_sierra: "af8f77463ed27a7de937714087c26069e0fdab171d402bfdf82d2b8eb6a12c7a"
  end

  depends_on "aria2"
  depends_on "lua@5.3"
  depends_on "mpv"
  depends_on "kikoplayproject/kikoplay/qhttpengine"
  depends_on "qt@5"

  def install
    # Enable test
    if build.head?
      system "git", "fetch", "--tags"
      version_str = Utils.safe_popen_read("git", "describe", "--tags")
      inreplace "res/version.json", /(?<="Version":).*/, %Q("#{version_str}")
    end

    inreplace "main.cpp", "args.pop_front();", <<~EOS
      args.pop_front();
      if(args.at(0) == "-V")
      {
        QFile version(":/res/version.json");
        version.open(QIODevice::ReadOnly);
        QJsonObject curVersionObj = QJsonDocument::fromJson(version.readAll()).object();
        QTextStream(stderr) << qUtf8Printable(curVersionObj.value("Version").toString());
        exit(0);
      }
    EOS

    # Use relative path ($prefix/bin/..) for instead of /usr
    inreplace %W[
      LANServer/httpserver.cpp
      Script/scriptmanager.cpp
    ] do |s|
      s.gsub! '"/usr/share', 'QCoreApplication::applicationDirPath()+"/../Resources'
    end

    # Force create ~/.config/kikoplay
    inreplace "globalobjects.cpp", "if (fileinfoConfig", "if (1 || fileinfoConfig"

    # Support native application menu
    inreplace "UI/mainwindow.cpp" do |s|
      s.gsub! /(#include <QApplication>)/,
              "#include <QMenuBar>\n\\1"
      s.gsub! /(.*QAction \*act_Settingse.*)/,
              "\\1 act_Settingse->setMenuRole(QAction::PreferencesRole);"
      s.gsub! /(.*QAction \*act_about.*)/,
              "\\1 act_about->setMenuRole(QAction::AboutRole);"
      s.gsub! /(.*QAction \*act_exit.*)/, <<~EOS
          \\1 act_exit->setMenuRole(QAction::QuitRole);
              auto *menuBar = new QMenuBar(nullptr);
              auto *appMenu = new QMenu(nullptr);
              menuBar->addMenu(appMenu);
              appMenu->addAction(act_Settingse);
              appMenu->addAction(act_about);
              appMenu->addAction(act_exit);
              setMenuBar(menuBar);
      EOS
    end

    # Create icon
    mkdir "KikoPlay.iconset"
    system "sips", "-p", "128", "128",
           "kikoplay.png", "--out", "KikoPlay_Square.png"
    [16, 32, 128, 256, 512].each do |s|
      system "sips", "-z", s, s, "KikoPlay_Square.png",
                     "--out", "KikoPlay.iconset/icon_#{s}x#{s}.png"
      system "sips", "-z", s * 2, s * 2, "KikoPlay_Square.png",
                     "--out", "KikoPlay.iconset/icon_#{s}x#{s}@2x.png"
    end
    system "iconutil", "-c", "icns", "KikoPlay.iconset"

    libs = %W[
      -L#{Formula["lua@5.3"].lib}
      -L#{Formula["mpv"].lib}
      -L#{Formula["kikoplayproject/kikoplay/qhttpengine"].lib}
    ]
    system "#{Formula["qt@5"].bin}/qmake",
           "LIBS += #{libs * " "}",
           "ICON = KikoPlay.icns"

    # Use packaged Lua headers
    ln_sf Dir[Formula["lua@5.3"].opt_include/"lua/*"], "Script/lua/"

    # Strip leading /usr during installation
    ln_s prefix, "usr"
    ENV["INSTALL_ROOT"] = "."
    system "make", "install"

    # Move app bundle and create command line shortcut
    mkdir "usr/libexec"
    mv "usr/bin/KikoPlay.app", "usr/libexec"
    bin.install_symlink libexec/"KikoPlay.app/Contents/MacOS/KikoPlay"
    (libexec/"KikoPlay.app/Contents/Resources").install_symlink share/"kikoplay"

    resource("script").stage do
      (share/"kikoplay/script").install Dir["*"]
    end

    doc.install Dir["KikoPlay*.pdf"]
  end

  def caveats
    <<~EOS
      After installation, link KikoPlay app to /Applications by running:
        ln -sf #{opt_libexec}/KikoPlay.app /Applications/
    EOS
  end

  test do
    version_str = shell_output("#{bin}/KikoPlay -V 2>&1").lines.last.chomp
    assert_equal version.to_s, version_str.sub(/^.*-\d+-g/, "HEAD-")
  end
end
