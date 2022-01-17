{ lib, stdenv, fetchurl, qt4, pkg-config, boost, expat, cairo, python3,
  cmake, flex, bison, pango, librsvg, librevenge, libxml2, libcdr, libzip, seexpr,
  poppler, imagemagick, openexr, ffmpeg, opencolorio_1, openimageio,
  qmake4Hook, libpng, libGL, lndir, libraw, openjpeg, libwebp, fetchFromGitHub }:

let
  version = "2.4.2";
  OpenColorIO-Configs = fetchFromGitHub {
    owner = "NatronGitHub";
    repo = "OpenColorIO-Configs";
    rev = "Natron-v${lib.versions.majorMinor version}";
    sha256 = "0yylscspmxz7djixg98v7qrw1mdgpzwj44h6wpx7x7mapxbwa4p2";
  };
  buildPlugin = { pluginName, sha256, nativeBuildInputs ? [], buildInputs ? [], preConfigure ? "", postPatch ? "" }:
    stdenv.mkDerivation {
      pname = "openfx-${pluginName}";
      version = version;
      src = fetchFromGitHub {
        owner = "NatronGitHub";
        repo = "openfx-${pluginName}";
        rev = "Natron-${version}";
        fetchSubmodules = true;
        inherit sha256;
      };
      inherit nativeBuildInputs buildInputs postPatch;

      makeFlags = [
        "CONFIG=release"
        "PLUGINPATH=${placeholder "out"}/Plugins/OFX/Natron"
      ];
    };
  plugins = map buildPlugin [
    ({
      pluginName = "arena";
      sha256 = "1jnmnpka5n1a9qc8dqcsmhzbyv5s4f09cdlzws8cj7w1z45k3mbr";
      nativeBuildInputs = [ pkg-config ];
      buildInputs = [
        pango librsvg librevenge libcdr opencolorio_1 libxml2 libzip
        poppler imagemagick
      ];
      preConfigure = ''
        sed -i 's|pkg-config poppler-glib|pkg-config poppler poppler-glib|g' Makefile.master
      '';
    })
    ({
      pluginName = "io";
      sha256 = "0mgb7r6lw5nbwfnywz8shxxia3xbfngwd24nki8s0vadjac8j7xm";
      nativeBuildInputs = [ pkg-config ];
      buildInputs = [
        libpng ffmpeg openexr opencolorio_1 openimageio boost libGL
        seexpr libraw openjpeg libwebp
      ];
    })
    ({
      pluginName = "misc";
      sha256 = "19in8jicc7xmafx2i70rrlq67k2h07swhbd2l3qivn05v0411h2s";
      buildInputs = [
        libGL
      ];
    })
  ];
in
stdenv.mkDerivation {
  inherit version;
  pname = "natron";

  src = fetchFromGitHub {
    owner = "NatronGitHub";
    repo = "Natron";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "0h99pfy4jx8604s55090138sg59zd80l0hlppm6l9bjch83awf61";
  };

  nativeBuildInputs = [ qmake4Hook pkg-config python3.pkgs.wrapPython ];

  buildInputs = [
    qt4 boost expat cairo python3.pkgs.pyside python3.pkgs.pysideShiboken
  ];

  preConfigure = ''
    export MAKEFLAGS=-j$NIX_BUILD_CORES
    cp ${./config.pri} config.pri
    cp -R ${OpenColorIO-Configs}/. OpenColorIO-Configs
  '';

  postFixup = ''
    for i in ${lib.escapeShellArgs plugins}; do
      ${lndir}/bin/lndir $i $out
    done
    wrapProgram $out/bin/Natron \
      --set PYTHONPATH "$PYTHONPATH"
  '';

  meta = with lib; {
    description = "Node-graph based, open-source compositing software";
    longDescription = ''
      Node-graph based, open-source compositing software. Similar in
      functionalities to Adobe After Effects and Nuke by The Foundry.
    '';
    homepage = "https://natron.fr/";
    license = lib.licenses.gpl2Plus;
    maintainers = with maintainers; [ puffnfresh vojta001 ];
    platforms = platforms.linux;
  };
}
